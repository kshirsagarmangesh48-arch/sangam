import 'dart:typed_data';

void triggerWebDownload({
  required String url,
  required String fileName,
  Uint8List? bytes,
}) {
  throw UnsupportedError('triggerWebDownload is only supported on web.');
}

void openInNewTabWeb(String url) {
  throw UnsupportedError('openInNewTabWeb is only supported on web.');
}
