import 'package:flutter/foundation.dart';
import 'package:jharudyam_citizen/models/problem_model.dart';
import 'package:jharudyam_citizen/services/problem_repository.dart';
import 'package:jharudyam_citizen/services/device_service.dart';

class ProblemsProvider extends ChangeNotifier {
  final ProblemRepository _repository = ProblemRepository();

  List<ProblemModel> _allProblems = [];
  List<ProblemModel> _myReports = [];
  List<String> _activeCategories = [];
  String? _selectedCategory;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<ProblemModel> get allProblems {
    if (_searchQuery.isEmpty) return _allProblems;
    return _allProblems.where((p) =>
      p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      p.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      p.category.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  List<ProblemModel> get myReports {
    if (_searchQuery.isEmpty) return _myReports;
    return _myReports.where((p) =>
      p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      p.address.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  List<String> get activeCategories => _activeCategories;
  String? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String? category) {
    _selectedCategory = (category == 'All') ? null : category;
    fetchAllProblems();
  }

  Future<void> fetchAllProblems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allProblems = await _repository.getProblems(category: _selectedCategory);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final deviceId = await DeviceService.getDeviceId();
      _myReports = await _repository.getMyReports(deviceId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchActiveCategories() async {
    try {
      _activeCategories = await _repository.getActiveCategories();
      notifyListeners();
    } catch (e) {
      // Non-fatal, keep existing categories
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchAllProblems(),
      fetchMyReports(),
      fetchActiveCategories(),
    ]);
  }
}
