import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class NativeApkInstaller {
  static const MethodChannel _channel = MethodChannel('com.buoy.erp/app_update');
  static http.Client? _activeClient;
  static bool _isCancelled = false;

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  static Future<String?> getDownloadPath() async {
    if (!isSupported) return null;
    try {
      final path = await _channel.invokeMethod<String>('getApkDownloadPath');
      return path;
    } catch (e) {
      debugPrint('Error getting APK path: $e');
      return null;
    }
  }

  static Future<bool> canInstallPackages() async {
    if (!isSupported) return false;
    try {
      final allowed = await _channel.invokeMethod<bool>('canInstallPackages');
      return allowed ?? true;
    } catch (e) {
      debugPrint('Error checking install packages: $e');
      return true;
    }
  }

  static Future<bool> openInstallSettings() async {
    if (!isSupported) return false;
    try {
      final opened = await _channel.invokeMethod<bool>('openInstallPermissionSettings');
      return opened ?? false;
    } catch (e) {
      debugPrint('Error opening settings: $e');
      return false;
    }
  }

  static Future<bool> installApk(String filePath) async {
    if (!isSupported) return false;
    try {
      final success = await _channel.invokeMethod<bool>('installApk', {'filePath': filePath});
      return success ?? false;
    } catch (e) {
      debugPrint('Error installing APK: $e');
      return false;
    }
  }

  static void cancelDownload() {
    _isCancelled = true;
    _activeClient?.close();
    _activeClient = null;
  }

  static Future<void> downloadApk({
    required String url,
    required String savePath,
    required void Function(double progress, int receivedBytes, int totalBytes) onProgress,
    required void Function() onComplete,
    required void Function(String error) onError,
  }) async {
    _isCancelled = false;
    _activeClient = http.Client();

    try {
      final uri = Uri.parse(url);
      final request = http.Request('GET', uri);
      final response = await _activeClient!.send(request);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Server responded with status ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final file = File(savePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        if (_isCancelled) {
          await sink.close();
          if (await file.exists()) {
            try {
              await file.delete();
            } catch (_) {}
          }
          return;
        }

        sink.add(chunk);
        receivedBytes += chunk.length;
        final progress = totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;
        onProgress(progress, receivedBytes, totalBytes);
      }

      await sink.flush();
      await sink.close();

      if (!_isCancelled) {
        onComplete();
      }
    } catch (e) {
      if (!_isCancelled) {
        onError(e.toString());
      }
    } finally {
      _activeClient = null;
    }
  }
}
