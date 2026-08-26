import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jharudyam_citizen/constants/app_constants.dart';
import 'package:jharudyam_citizen/constants/app_theme.dart';
import 'package:jharudyam_citizen/providers/problems_provider.dart';
import 'package:jharudyam_citizen/providers/report_provider.dart';
import 'package:jharudyam_citizen/screens/problem_detail_screen.dart';
import 'package:jharudyam_citizen/widgets/success_dialog.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().reset();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Problem', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black87)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<ReportProvider>(
        builder: (context, provider, _) {
          switch (provider.currentStep) {
            case ReportStep.photo:
              return _buildPhotoStep(provider);
            case ReportStep.analyzing:
              return _buildAnalyzingStep(provider);
            case ReportStep.review:
              return _buildReviewStep(provider);
            case ReportStep.submitting:
              return _buildSubmittingStep();
            case ReportStep.success:
              return _buildSuccessStep(provider);
          }
        },
      ),
    );
  }

  Widget _buildPhotoStep(ReportProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('Show us the problem', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.black87)),
          const SizedBox(height: 8),
          Text('A photo helps us understand what\'s happening and route to the right department.', style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5)),
          const SizedBox(height: 32),
          // Dashed border camera area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 1.5, strokeAlign: BorderSide.strokeAlignCenter),
              color: AppTheme.primaryTint.withValues(alpha: 0.2),
            ),
            child: Column(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: AppTheme.primaryTint, shape: BoxShape.circle),
                  child: const Icon(Icons.add_a_photo, size: 30, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => provider.captureFromCamera(),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => provider.pickFromGallery(),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingStep(ReportProvider provider) {
    return _AnalyzingView(
      image: provider.selectedImage,
      step: provider.analyzingStep,
    );
  }

  Widget _buildReviewStep(ReportProvider provider) {
    if (_titleController.text != provider.title) _titleController.text = provider.title;
    if (_descriptionController.text != provider.description) _descriptionController.text = provider.description;
    if (_addressController.text != (provider.address ?? '')) _addressController.text = provider.address ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stage indicator
          Text('STAGE 3 OF 4', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryColor, letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('Where is the problem?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black87)),
          const SizedBox(height: 6),
          Text('Confirm the location and review the details.', style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5)),
          const SizedBox(height: 20),

          // Error banner
          if (provider.error != null)
            Container(
              width: double.infinity, padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
              child: Row(children: [
                Icon(Icons.warning_amber, color: Colors.red.shade400, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(provider.error!, style: TextStyle(fontSize: 12, color: Colors.red.shade700))),
              ]),
            ),

          // Image preview
          if (provider.selectedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(provider.selectedImage!, height: 180, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 16),

          // Address card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.primaryTint.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.primaryTint, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('RESOLVED ADDRESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(provider.address ?? 'Detecting location...', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  onChanged: provider.setAddress,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Edit address or enter manually...',
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: provider.isFetchingLocation ? null : () async {
                      await provider.refreshLocation();
                      if (context.mounted && provider.address != null) _addressController.text = provider.address!;
                    },
                    icon: provider.isFetchingLocation
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                        : const Icon(Icons.my_location, size: 16),
                    label: Text(provider.isFetchingLocation ? 'Locating...' : 'GPS Auto-Detect', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Review fields
          _sectionLabel('Title'),
          TextField(controller: _titleController, onChanged: provider.setTitle, decoration: const InputDecoration(hintText: 'Issue title...')),
          const SizedBox(height: 16),

          _sectionLabel('Description'),
          TextField(controller: _descriptionController, onChanged: provider.setDescription, maxLines: 4, decoration: const InputDecoration(hintText: 'Describe the issue...')),
          const SizedBox(height: 16),

          _sectionLabel('Category'),
          TextFormField(initialValue: provider.category, onChanged: provider.setCategory, decoration: const InputDecoration(hintText: 'e.g. Road Infrastructure')),
          const SizedBox(height: 16),

          _sectionLabel('Priority'),
          DropdownButtonFormField<String>(
            initialValue: priorities.contains(provider.priority) ? provider.priority : 'medium',
            items: priorities.map((p) {
              return DropdownMenuItem(value: p, child: Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: AppTheme.priorityColor(p), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(p[0].toUpperCase() + p.substring(1)),
              ]));
            }).toList(),
            onChanged: (v) { if (v != null) provider.setPriority(v); },
            decoration: const InputDecoration(),
          ),
          const SizedBox(height: 16),

          _sectionLabel('Department'),
          DropdownButtonFormField<String>(
            initialValue: departments.contains(provider.department) ? provider.department : departments.first,
            items: departments.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 14)))).toList(),
            onChanged: (v) { if (v != null) provider.setDepartment(v); },
            decoration: const InputDecoration(),
            isExpanded: true,
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => provider.submit(),
              icon: const Icon(Icons.send),
              label: const Text('Submit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
    );
  }

  Widget _buildSubmittingStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 50, height: 50, child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 3)),
            const SizedBox(height: 24),
            const Text('Submitting Your Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primaryDark)),
            const SizedBox(height: 8),
            Text('Uploading image and filing your report...', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessStep(ReportProvider provider) {
    final problem = provider.submittedProblem;
    final ticketNo = problem?.ticketNo ?? 'JU-XX-XXXX';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => SuccessDialog(
          ticketNumber: ticketNo,
          onViewReport: () {
            Navigator.of(context).pop();
            if (problem != null) {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ProblemDetailScreen(problem: problem)));
            }
          },
          onDone: () {
            context.read<ProblemsProvider>().refreshAll();
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        ),
      );
    });
    return const SizedBox.shrink();
  }
}

class _AnalyzingView extends StatefulWidget {
  final dynamic image; // File?
  final int step;

  const _AnalyzingView({required this.image, required this.step});

  @override
  State<_AnalyzingView> createState() => _AnalyzingViewState();
}

class _AnalyzingViewState extends State<_AnalyzingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  final List<String> _steps = const [
    'Image received',
    'Looking for visible issues',
    'Identifying the problem',
    'Preparing your report',
  ];

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF132520),
      width: double.infinity,
      height: double.infinity,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Understanding your\nreport...',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4ADE80),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Jhar Udayam is analyzing the image to help describe the problem.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade300,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Image preview with live scanning line animation
              if (widget.image != null)
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 4)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Image.file(
                          widget.image!,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        // Dark tint overlay
                        Container(
                          color: Colors.black.withValues(alpha: 0.15),
                        ),
                        // Animated Scanning line
                        AnimatedBuilder(
                          animation: _scanAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top: _scanAnimation.value * 190,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Color(0xFF4ADE80),
                                      Colors.white,
                                      Color(0xFF4ADE80),
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4ADE80).withValues(alpha: 0.8),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // Corner borders / reticle
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF4ADE80).withValues(alpha: 0.6),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Text(
                    'AI VISION ANALYSIS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4ADE80),
                      letterSpacing: 1.2,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.radar, color: Color(0xFF4ADE80), size: 18),
                ],
              ),
              const SizedBox(height: 20),

              // Dynamic checklist card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: List.generate(_steps.length, (index) {
                    final label = _steps[index];
                    final isDone = widget.step > index;
                    final isActive = widget.step == index;

                    return Padding(
                      padding: EdgeInsets.only(bottom: index < _steps.length - 1 ? 16 : 0),
                      child: Row(
                        children: [
                          if (isDone)
                            const Icon(
                              Icons.check_circle,
                              size: 22,
                              color: AppTheme.primaryColor,
                            )
                          else if (isActive)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppTheme.primaryColor,
                              ),
                            )
                          else
                            Icon(
                              Icons.circle_outlined,
                              size: 22,
                              color: Colors.grey.shade300,
                            ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : (isDone ? FontWeight.w600 : FontWeight.w500),
                                color: isActive
                                    ? AppTheme.primaryColor
                                    : (isDone ? Colors.black87 : Colors.grey.shade400),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

