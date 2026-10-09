import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Phones' browsers: the native share sheet with the file attached (Web Share
/// API). Elsewhere, or if sharing files isn't supported: a normal download.
Future<void> saveOrShareFile(
  Uint8List bytes, {
  required String fileName,
  required String mimeType,
}) async {
  final file = web.File(
    [bytes.toJS].toJS,
    fileName,
    web.FilePropertyBag(type: mimeType),
  );
  final shareData = web.ShareData(files: [file].toJS);
  final navigator = web.window.navigator;
  var canShare = false;
  try {
    canShare = navigator.canShare(shareData);
  } catch (_) {}
  if (canShare) {
    try {
      await navigator.share(shareData).toDart;
      return;
    } catch (e) {
      // The user closed the share sheet: that's an answer, not a failure.
      if (e.toString().contains('AbortError')) return;
      // Otherwise (e.g. no user gesture left) fall through to a download.
    }
  }
  _download(file, fileName);
}

void _download(web.File file, String fileName) {
  final url = web.URL.createObjectURL(file);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  // Give the browser a moment to start the download before revoking.
  Future<void>.delayed(const Duration(seconds: 1), () => web.URL.revokeObjectURL(url));
}
