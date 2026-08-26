import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jharudyam_citizen/constants/app_constants.dart';
import 'package:jharudyam_citizen/models/problem_model.dart';
import 'package:jharudyam_citizen/services/ai_service.dart';
import 'package:jharudyam_citizen/services/device_service.dart';
import 'package:jharudyam_citizen/services/image_service.dart';
import 'package:jharudyam_citizen/services/location_service.dart';
import 'package:jharudyam_citizen/services/problem_repository.dart';

enum ReportStep { photo, analyzing, review, submitting, success }

class ReportProvider extends ChangeNotifier {
  final ImageService _imageService = ImageService();
  final LocationService _locationService = LocationService();
  final AiService _aiService = AiService();
  final ProblemRepository _repository = ProblemRepository();

  ReportStep _currentStep = ReportStep.photo;
  File? _selectedImage;
  Uint8List? _compressedBytes;
  Position? _location;
  String? _address;
  AiAnalysisResult? _aiResult;
  String? _error;
  bool _isFetchingLocation = false;
  ProblemModel? _submittedProblem;

  // Editable fields
  String _title = '';
  String _description = '';
  String _category = '';
  String _priority = 'medium';
  String _department = 'Public Works';

  // Getters
  ReportStep get currentStep => _currentStep;
  File? get selectedImage => _selectedImage;
  Uint8List? get compressedBytes => _compressedBytes;
  Position? get location => _location;
  String? get address => _address;
  AiAnalysisResult? get aiResult => _aiResult;
  String? get error => _error;
  bool get isFetchingLocation => _isFetchingLocation;
  ProblemModel? get submittedProblem => _submittedProblem;
  String get title => _title;
  String get description => _description;
  String get category => _category;
  String get priority => _priority;
  String get department => _department;

  // Setters for editable fields
  void setTitle(String v) { _title = v; notifyListeners(); }
  void setDescription(String v) { _description = v; notifyListeners(); }
  void setAddress(String v) { _address = v; notifyListeners(); }
  void setCategory(String v) { _category = v; notifyListeners(); }
  void setPriority(String v) { _priority = v; notifyListeners(); }
  void setDepartment(String v) { _department = v; notifyListeners(); }

  /// Pick photo from camera, compress, fetch GPS, and run AI analysis
  Future<void> captureFromCamera() async {
    final file = await _imageService.pickFromCamera();
    if (file != null) await _processImage(file);
  }

  Future<void> pickFromGallery() async {
    final file = await _imageService.pickFromGallery();
    if (file != null) await _processImage(file);
  }

  Future<void> _processImage(File file) async {
    _selectedImage = file;
    _error = null;
    _currentStep = ReportStep.analyzing;
    notifyListeners();

    try {
      // Compress image & fetch location in parallel
      final compressFuture = _imageService.compressImage(file);
      final locationFuture = _fetchLocation();

      _compressedBytes = await compressFuture;
      await locationFuture;

      // Run AI analysis
      _aiResult = await _aiService.analyzeImage(_compressedBytes!);

      // Populate editable fields from AI result
      _title = _aiResult!.title;
      _description = _aiResult!.description;
      _category = _aiResult!.category;
      _priority = _aiResult!.priority;
      _department = _aiResult!.department;

      _currentStep = ReportStep.review;
    } catch (e) {
      _error = e.toString();
      // Use fallback AI result so the user can still submit
      final fallback = _aiService.fallbackResult();
      _title = fallback.title;
      _description = fallback.description;
      _category = fallback.category;
      _priority = fallback.priority;
      _department = fallback.department;
      _currentStep = ReportStep.review;
    }
    notifyListeners();
  }

  Future<void> _fetchLocation() async {
    _isFetchingLocation = true;
    notifyListeners();
    try {
      _location = await _locationService.getCurrentPosition();
      _address = await _locationService.getAddressFromCoordinates(
        _location!.latitude,
        _location!.longitude,
      );
    } catch (e) {
      // Location failure is non-fatal; user can still enter address manually
      _location = null;
      _address = _address ?? '';
    } finally {
      _isFetchingLocation = false;
      notifyListeners();
    }
  }

  /// Re-fetch GPS location on button press
  Future<void> refreshLocation() async {
    await _fetchLocation();
  }

  /// Submit the report to Supabase
  Future<void> submit() async {
    if (_compressedBytes == null) {
      _error = 'No image selected';
      notifyListeners();
      return;
    }

    _currentStep = ReportStep.submitting;
    _error = null;
    notifyListeners();

    try {
      // Upload image
      final uploadResult = await _repository.uploadImage(_compressedBytes!);

      // Get device ID
      final deviceId = await DeviceService.getDeviceId();

      // Build model
      final problem = ProblemModel(
        title: _title.trim().isEmpty ? 'Civic Issue Report' : _title.trim(),
        description: _description.trim().isEmpty ? 'Civic issue reported by citizen.' : _description.trim(),
        category: _category.trim().isEmpty ? 'General' : _category.trim(),
        priority: _priority,
        department: _department,
        imageUrl: uploadResult.publicUrl,
        imagePath: uploadResult.path,
        address: (_address != null && _address!.trim().isNotEmpty) ? _address!.trim() : 'Location specified on photo',
        latitude: _location?.latitude ?? 0.0,
        longitude: _location?.longitude ?? 0.0,
        reporterId: deviceId,
        reporterName: defaultReporterName,
      );

      // Insert into Supabase
      _submittedProblem = await _repository.submitProblem(problem);
      _currentStep = ReportStep.success;
    } catch (e) {
      _error = e.toString();
      _currentStep = ReportStep.review; // Go back to review so user can retry
    }
    notifyListeners();
  }

  /// Reset wizard state for a new report
  void reset() {
    _currentStep = ReportStep.photo;
    _selectedImage = null;
    _compressedBytes = null;
    _location = null;
    _address = null;
    _aiResult = null;
    _error = null;
    _isFetchingLocation = false;
    _submittedProblem = null;
    _title = '';
    _description = '';
    _category = '';
    _priority = 'medium';
    _department = 'Public Works';
    notifyListeners();
  }
}
