import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

void downloadFileFromUrl(String url, {String? filename}) async {
  try {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  } catch (e) {
    debugPrint('Download error: $e');
  }
}

