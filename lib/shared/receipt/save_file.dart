import 'dart:typed_data';

import 'save_file_io.dart' if (dart.library.js_interop) 'save_file_web.dart'
    as impl;

/// Hands a generated file to the user: the share sheet on Android/iOS (Save
/// to Photos/Files, WhatsApp…), a normal browser download on web.
Future<void> saveOrShareFile(
  Uint8List bytes, {
  required String fileName,
  required String mimeType,
}) =>
    impl.saveOrShareFile(bytes, fileName: fileName, mimeType: mimeType);
