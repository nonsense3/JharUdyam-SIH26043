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
    // Reset wizard on screen open
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
        title: const Text(
          'Report Issue',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<ReportProvider>(
        builder: (context, provider, _) {
          switch (provider.currentStep) {
            case ReportStep.photo:
              return _buildPhotoStep(provider);
            case ReportStep.analyzing:
              return _buildAnalyzingStep();
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

  // ── Step 1: Photo Acquisition ──────────────────────────────────────

  Widget _buildPhotoStep(ReportProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryTint,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 48,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Capture the Issue',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a photo or select from gallery to report a civic issue. Our AI will automatically analyze and categorize it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => provider.captureFromCamera(),
                icon: const Icon(Icons.camera_alt),
                label: const Text(
                  'Take Photo',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => provider.pickFromGallery(),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text(
                  'Choose from Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2: AI Analyzing ───────────────────────────────────────────

  Widget _buildAnalyzingStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Analyzing Your Photo',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'AI is identifying the issue, assessing priority, and routing to the correct government department...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 3: Review & Edit ──────────────────────────────────────────

  Widget _buildReviewStep(ReportProvider provider) {
    // Sync controllers with provider values
    if (_titleController.text != provider.title) {
      _titleController.text = provider.title;
    }
    if (_descriptionController.text != provider.description) {
      _descriptionController.text = provider.description;
    }
    if (_addressController.text != (provider.address ?? '')) {
      _addressController.text = provider.address ?? '';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error banner
          if (provider.error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red.shade400, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.error!,
                      style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Image preview
          if (provider.selectedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                provider.selectedImage!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),

          // Editable Location field
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Location / Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              TextButton.icon(
                onPressed: provider.isFetchingLocation
                    ? null
                    : () async {
                        await provider.refreshLocation();
                        if (context.mounted && provider.address != null) {
                          _addressController.text = provider.address!;
                        }
                      },
                icon: provider.isFetchingLocation
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryColor,
                        ),
                      )
                    : const Icon(Icons.my_location, size: 14, color: AppTheme.primaryColor),
                label: Text(
                  provider.isFetchingLocation ? 'Locating...' : 'GPS Auto-Detect',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _addressController,
            onChanged: provider.setAddress,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Enter street address or landmarks...',
              prefixIcon: const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 20),
              filled: true,
              fillColor: AppTheme.primaryTint.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 16),

          // Editable fields
          const Text('Title', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            onChanged: provider.setTitle,
            decoration: const InputDecoration(
              hintText: 'Issue title...',
            ),
          ),
          const SizedBox(height: 16),

          const Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _descriptionController,
            onChanged: provider.setDescription,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Describe the issue...',
            ),
          ),
          const SizedBox(height: 16),

          // Category dropdown
          const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: provider.category,
            onChanged: provider.setCategory,
            decoration: const InputDecoration(
              hintText: 'e.g. Road Infrastructure',
            ),
          ),
          const SizedBox(height: 16),

          // Priority dropdown
          const Text('Priority', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: priorities.contains(provider.priority) ? provider.priority : 'medium',
            items: priorities.map((p) {
              final label = p[0].toUpperCase() + p.substring(1);
              return DropdownMenuItem(
                value: p,
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.priorityColor(p),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(label),
                  ],
                ),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) provider.setPriority(v);
            },
            decoration: const InputDecoration(),
          ),
          const SizedBox(height: 16),

          // Department dropdown
          const Text('Department', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: departments.contains(provider.department) ? provider.department : departments.first,
            items: departments.map((d) {
              return DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 14)));
            }).toList(),
            onChanged: (v) {
              if (v != null) provider.setDepartment(v);
            },
            decoration: const InputDecoration(),
            isExpanded: true,
          ),
          const SizedBox(height: 28),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => provider.submit(),
              icon: const Icon(Icons.send),
              label: const Text(
                'Submit Report',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Step 4: Submitting ─────────────────────────────────────────────

  Widget _buildSubmittingStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Submitting Your Report',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Uploading image and filing your civic report...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 5: Success ────────────────────────────────────────────────

  Widget _buildSuccessStep(ReportProvider provider) {
    final problem = provider.submittedProblem;
    final ticketNo = problem?.ticketNo ?? 'JU-XX-XXXX';

    // Show dialog after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => SuccessDialog(
          ticketNumber: ticketNo,
          onViewReport: () {
            Navigator.of(context).pop(); // close dialog
            if (problem != null) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => ProblemDetailScreen(problem: problem),
                ),
              );
            }
          },
          onDone: () {
            // Refresh feed and go back to home
            context.read<ProblemsProvider>().refreshAll();
            Navigator.of(context).pop(); // close dialog
            Navigator.of(context).pop(); // close create screen
          },
        ),
      );
    });

    return const SizedBox.shrink();
  }
}
