import '../utils/download_helper.dart';

class NativeApkInstaller {
  static bool get isSupported => false;

  static Future<String?> getDownloadPath() async => null;
  static Future<bool> canInstallPackages() async => false;
  static Future<bool> openInstallSettings() async => false;
  static Future<bool> installApk(String filePath) async => false;
  static void cancelDownload() {}

  static Future<void> downloadApk({
    required String url,
    required String savePath,
    required void Function(double progress, int receivedBytes, int totalBytes) onProgress,
    required void Function() onComplete,
    required void Function(String error) onError,
  }) async {
    downloadFileFromUrl(url, filename: 'buoy-erp.apk');
    onComplete();
  }
}
