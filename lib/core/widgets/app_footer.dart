import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key, this.padding = const EdgeInsets.symmetric(vertical: 20, horizontal: 16)});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: const Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
            children: [
              const TextSpan(text: 'Designed & developed by '),
              TextSpan(
                text: 'ARMSS INFO TECH',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2563EB),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
