import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shorebird_code_push/shorebird_code_push.dart';
import '../../app/constants/app_colors.dart';
import '../../app/constants/app_constants.dart';
import '../config/api_config.dart';
import '../utils/download_helper.dart';
import 'apk_installer.dart';

class AppUpdateService {
  static String get currentAppVersion => AppConstants.appVersion;
  static int get currentBuildNumber => AppConstants.buildNumber;

  static final ShorebirdUpdater _updater = ShorebirdUpdater();
  static bool _isChecking = false;

  /// Call on app launch, return from background, or manually from Settings.
  static Future<void> checkForUpdates(
    BuildContext context, {
    bool manual = false,
  }) async {
    if (_isChecking) {
      if (manual && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Update check already in progress...'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }
    _isChecking = true;

    if (manual && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Checking for latest updates...'),
            ],
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    try {
      // 1. Shorebird CodePush Engine (OTA Instant Patching)
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
                        'Live update installed! Restart app to apply.',
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
                  label: 'RESTART',
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

      // 2. Fetch Latest Version Metadata
      Map<String, dynamic>? versionData;

      // Primary check: backend API
      try {
        final res = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/app/version'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 5));

        if (res.statusCode == 200) {
          versionData = jsonDecode(res.body) as Map<String, dynamic>;
        }
      } catch (e) {
        debugPrint('Primary version check failed: $e, trying secondary raw config fallback...');
      }

      // Secondary fallback check: raw GitHub config
      if (versionData == null) {
        try {
          final resFallback = await http.get(
            Uri.parse('https://raw.githubusercontent.com/kavypatel03/buoy-erp-main/main/backend/config/version.json'),
            headers: {'Content-Type': 'application/json'},
          ).timeout(const Duration(seconds: 5));

          if (resFallback.statusCode == 200) {
            versionData = jsonDecode(resFallback.body) as Map<String, dynamic>;
          }
        } catch (e) {
          debugPrint('Secondary version fallback failed: $e');
        }
      }

      if (versionData != null) {
        final serverBuild = versionData['buildNumber'] as int? ?? 1;
        final serverVersion = versionData['latestVersion']?.toString() ?? '1.0.0';
        final downloadUrl = versionData['downloadUrl']?.toString() ??
            'https://github.com/kavypatel03/buoy-erp-main/raw/main/web/download/buoy-erp.apk';
        final releaseNotes = versionData['releaseNotes']?.toString() ??
            'Factory performance updates and latest bug fixes.';
        final forceUpdate = versionData['forceUpdate'] == true;

        if (serverBuild > currentBuildNumber && context.mounted) {
          _showUpdateDialog(
            context,
            version: serverVersion,
            buildNumber: serverBuild,
            notes: releaseNotes,
            downloadUrl: downloadUrl,
            forceUpdate: forceUpdate,
          );
          return;
        }
      }

      // If user manually tapped Check for Updates and no new version is found:
      if (manual && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Buoy ERP is up to date (${AppConstants.fullVersionString})',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } catch (e) {
      debugPrint('AppUpdateService error: $e');
      if (manual && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to reach update server. Check your connection.'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      _isChecking = false;
    }
  }

  static void _showUpdateDialog(
    BuildContext context, {
    required String version,
    required int buildNumber,
    required String notes,
    required String downloadUrl,
    required bool forceUpdate,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (ctx) => _InAppUpdateModal(
        version: version,
        buildNumber: buildNumber,
        notes: notes,
        downloadUrl: downloadUrl,
        forceUpdate: forceUpdate,
      ),
    );
  }
}

class _InAppUpdateModal extends StatefulWidget {
  final String version;
  final int buildNumber;
  final String notes;
  final String downloadUrl;
  final bool forceUpdate;

  const _InAppUpdateModal({
    required this.version,
    required this.buildNumber,
    required this.notes,
    required this.downloadUrl,
    required this.forceUpdate,
  });

  @override
  State<_InAppUpdateModal> createState() => _InAppUpdateModalState();
}

enum _UpdateStep { prompt, downloading, readyToInstall, error }

class _InAppUpdateModalState extends State<_InAppUpdateModal> {
  _UpdateStep _currentStep = _UpdateStep.prompt;
  double _progress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String _errorMessage = '';
  String? _cachedApkPath;

  @override
  void dispose() {
    if (_currentStep == _UpdateStep.downloading) {
      NativeApkInstaller.cancelDownload();
    }
    super.dispose();
  }

  Future<void> _startInAppDownload() async {
    if (!NativeApkInstaller.isSupported) {
      // Fallback for Web or unsupported platforms
      Navigator.pop(context);
      downloadFileFromUrl(widget.downloadUrl, filename: 'buoy-erp.apk');
      return;
    }

    setState(() {
      _currentStep = _UpdateStep.downloading;
      _progress = 0.0;
      _receivedBytes = 0;
      _totalBytes = 0;
      _errorMessage = '';
    });

    final apkPath = await NativeApkInstaller.getDownloadPath();
    if (apkPath == null) {
      setState(() {
        _currentStep = _UpdateStep.error;
        _errorMessage = 'Could not access device cache directory.';
      });
      return;
    }
    _cachedApkPath = apkPath;

    await NativeApkInstaller.downloadApk(
      url: widget.downloadUrl,
      savePath: apkPath,
      onProgress: (p, received, total) {
        if (mounted) {
          setState(() {
            _progress = p;
            _receivedBytes = received;
            _totalBytes = total;
          });
        }
      },
      onComplete: () async {
        if (!mounted) return;
        setState(() {
          _currentStep = _UpdateStep.readyToInstall;
        });
        await _triggerInstall();
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _currentStep = _UpdateStep.error;
            _errorMessage = 'Download failed: $err';
          });
        }
      },
    );
  }

  Future<void> _triggerInstall() async {
    if (_cachedApkPath == null) return;

    final canInstall = await NativeApkInstaller.canInstallPackages();
    if (!canInstall) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Please grant permission to install updates directly.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.warning,
            action: SnackBarAction(
              label: 'SETTINGS',
              textColor: Colors.white,
              onPressed: () => NativeApkInstaller.openInstallSettings(),
            ),
          ),
        );
      }
      await NativeApkInstaller.openInstallSettings();
      return;
    }

    final ok = await NativeApkInstaller.installApk(_cachedApkPath!);
    if (!ok && mounted) {
      setState(() {
        _currentStep = _UpdateStep.error;
        _errorMessage = 'Failed to trigger package installer.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !widget.forceUpdate && _currentStep != _UpdateStep.downloading,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkCardBorder : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C47FF), Color(0xFF4128C4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.rocket_launch_rounded,
                        color: Colors.white, size: 22),
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
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'v${widget.version} (Build ${widget.buildNumber})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Content based on step
              if (_currentStep == _UpdateStep.prompt) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 15, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            "What's New in this Build:",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.notes,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.flash_on_rounded,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Seamless 1-tap in-app installation',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!widget.forceUpdate)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Later',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _startInAppDownload,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Update Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (_currentStep == _UpdateStep.downloading) ...[
                const Text(
                  'Downloading package update...',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _totalBytes > 0 ? _progress : null,
                    minHeight: 10,
                    backgroundColor: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _totalBytes > 0
                          ? '${(_receivedBytes / (1024 * 1024)).toStringAsFixed(1)} MB / ${(_totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
                          : 'Connecting...',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(_progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        NativeApkInstaller.cancelDownload();
                        setState(() => _currentStep = _UpdateStep.prompt);
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ] else if (_currentStep == _UpdateStep.readyToInstall) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Update package ready. System installer launched.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _triggerInstall,
                      icon: const Icon(Icons.install_mobile_rounded, size: 18),
                      label: const Text('Install Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (_currentStep == _UpdateStep.error) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage.isNotEmpty
                              ? _errorMessage
                              : 'An error occurred during update.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Browser fallback
                        downloadFileFromUrl(widget.downloadUrl,
                            filename: 'buoy-erp.apk');
                        Navigator.pop(context);
                      },
                      child: const Text('Download via Browser'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _startInAppDownload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
