import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Shared progress stepper shown across Step 1, 2, 3 screens.
class DonationStepper extends StatelessWidget {
  const DonationStepper({super.key, required this.currentStep});

  final int currentStep; // 1, 2, or 3

  static const List<String> _labels = ['Donor', 'Cause & Scheme', 'Payment'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        for (int i = 1; i <= 3; i++) ...[
          _stepNode(context, i, _labels[i - 1], currentStep >= i, currentStep > i, isDark),
          if (i < 3) _stepLine(currentStep > i, isDark),
        ],
      ],
    );
  }

  Widget _stepNode(BuildContext context, int step, String label, bool active, bool done, bool isDark) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppTheme.primary : (isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : Text(
                    '$step',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: active ? Colors.white : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? (isDark ? const Color(0xFFFBBF24) : AppTheme.primaryDark) : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
          ),
        ),
      ],
    );
  }

  Widget _stepLine(bool done, bool isDark) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 2.5,
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: done ? AppTheme.primary : (isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
        ),
      ),
    );
  }
}
