import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/api_constants.dart';
import '../theme/app_theme.dart';
import '../../models/app_version_info.dart';

class AppUpdateService {
  AppUpdateService._();

  /// Current build identifiers for Nesakkaram Donor App (Play Store Initial Release)
  static const int currentVersionCode = 1;
  static const String currentVersionName = '1.0.0';

  static bool _dialogShowing = false;

  /// Checks for available updates from the Trust Backend and prompts the donor if needed
  static Future<void> checkUpdate(BuildContext context, {bool silentOnLatest = true}) async {
    if (_dialogShowing) return;

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      final response = await dio.get('/public/app-version', queryParameters: {'platform': 'android'});
      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data;
        final data = raw is Map ? (raw['data'] ?? raw) : null;
        if (data is Map<String, dynamic>) {
          final info = AppVersionInfo.fromJson(data);
          final hasUpdate = info.versionCode > currentVersionCode;
          final isForced = (info.minVersionCode > currentVersionCode) || info.forceUpdate;

          if (hasUpdate && context.mounted) {
            _showUpdateDialog(context, info, isForced);
          }
        }
      }
    } catch (_) {
      // Gracefully ignore network failures during background update checks
    }
  }

  static void _showUpdateDialog(BuildContext context, AppVersionInfo info, bool isForced) {
    _dialogShowing = true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: !isForced,
      builder: (dialogCtx) {
        return PopScope(
          canPop: !isForced,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 12,
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Emblem & Sparkle Badge
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary.withOpacity(0.25), width: 1.5),
                    ),
                    child: Center(
                      child: Icon(
                        isForced ? Icons.system_update_rounded : Icons.auto_awesome_rounded,
                        color: AppTheme.primary,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    info.updateTitle.isNotEmpty ? info.updateTitle : 'New Update Available',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                    ),
                    child: Text(
                      'Version ${info.latestVersion}',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (info.updateMessage.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        info.updateMessage,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          height: 1.5,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Actions
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: Text(
                        'Update on Google Play',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () async {
                        final uri = Uri.parse(info.storeUrl);
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (_) {}
                      },
                    ),
                  ),

                  if (!isForced) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        _dialogShowing = false;
                        Navigator.of(dialogCtx).pop();
                      },
                      child: Text(
                        'Maybe Later',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _dialogShowing = false;
    });
  }
}
