import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shorebird_code_push/shorebird_code_push.dart';
import '../../app/constants/app_colors.dart';
import '../config/api_config.dart';
import '../utils/download_helper.dart';

class AppUpdateService {
  static const String currentAppVersion = '1.0.0';
  static const int currentBuildNumber = 1;

  static final ShorebirdUpdater _updater = ShorebirdUpdater();
  static bool _isChecking = false;

  /// Call once when the app launches or returns to the foreground.
  static Future<void> checkForUpdates(BuildContext context) async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      // 1. Shorebird CodePush Engine (Trending Standard for Hot Live Dart Patches)
      if (!kIsWeb && _updater.isAvailable) {
        final status = await _updater.checkForUpdate();

        if (status == UpdateStatus.outdated) {
          debugPrint('Shorebird: New OTA patch available, downloading in background...');
          await _updater.update();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Live update downloaded! Restart app to apply new features.',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.primary,
                duration: const Duration(seconds: 6),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
          _isChecking = false;
          return;
        } else if (status == UpdateStatus.restartRequired && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Update ready! Please restart the app to apply changes.',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          );
        }
      }

      // 2. Backend Server Check (Fallback for Direct Sideloaded APKs)
      if (!kIsWeb) {
        final res = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/app/version'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final serverBuild = data['buildNumber'] as int? ?? 1;
          final serverVersion = data['latestVersion']?.toString() ?? '1.0.0';
          final downloadUrl = data['downloadUrl']?.toString() ?? '';
          final releaseNotes = data['releaseNotes']?.toString() ?? '';

          if (serverBuild > currentBuildNumber && context.mounted) {
            _showUpdateDialog(
              context,
              version: serverVersion,
              notes: releaseNotes,
              downloadUrl: downloadUrl,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('AppUpdateService check skipped: $e');
    } finally {
      _isChecking = false;
    }
  }

  static void _showUpdateDialog(
    BuildContext context, {
    required String version,
    required String notes,
    required String downloadUrl,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? AppColors.darkCardBorder : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.system_update_rounded,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Available',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(ctx).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Version $version Ready',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                notes.isNotEmpty
                    ? notes
                    : 'A new factory update is available with new features and improvements.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Later',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      downloadFileFromUrl(
                        downloadUrl.isNotEmpty
                            ? downloadUrl
                            : '/download/buoy-erp.apk',
                        filename: 'buoy-erp.apk',
                      );
                    },
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Update Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
