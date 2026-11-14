import 'package:web/web.dart' as web;

void downloadFileFromUrl(String url, {String? filename}) {
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename ?? 'buoy-erp.apk';
  anchor.target = '_blank';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
}
