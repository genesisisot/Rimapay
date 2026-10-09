import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<void> saveOrShareFile(
  Uint8List bytes, {
  required String fileName,
  required String mimeType,
}) async {
  await Share.shareXFiles(
    [XFile.fromData(bytes, name: fileName, mimeType: mimeType)],
    subject: 'RimaPay Receipt',
  );
}
