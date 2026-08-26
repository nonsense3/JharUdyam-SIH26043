import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jharudyam_citizen/constants/app_theme.dart';

class SuccessDialog extends StatelessWidget {
  final String ticketNumber;
  final VoidCallback? onViewReport;
  final VoidCallback? onDone;

  const SuccessDialog({
    super.key,
    required this.ticketNumber,
    this.onViewReport,
    this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Green circle checkmark
              Container(
                width: 90, height: 90,
                decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 28),
              const Text('Report submitted', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.black87)),
              const SizedBox(height: 10),
              Text('Thank you for helping improve your community.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5)),
              const SizedBox(height: 32),
              // Tracking ID card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F9F7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Text('TRACKING ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    Text(ticketNumber, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: 1, fontFamily: 'monospace')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text('Please save your tracking ID for future reference.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.4)),
              const SizedBox(height: 28),
              // Track Report button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onViewReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('Track Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              // Copy ID + Done row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: ticketNumber));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tracking ID copied!'), duration: Duration(seconds: 2)),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy ID', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDone,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Footer note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Text('Your report will be reviewed and routed to the relevant authority.', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
