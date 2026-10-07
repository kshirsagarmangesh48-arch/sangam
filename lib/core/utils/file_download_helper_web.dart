import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

void triggerWebDownload({
  required String url,
  required String fileName,
  Uint8List? bytes,
}) {
  if (bytes != null && bytes.isNotEmpty) {
    final jsArray = [bytes.toJS].toJS;
    final blob = web.Blob(jsArray);
    final blobUrl = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = blobUrl;
    anchor.download = fileName;
    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(blobUrl);
  } else {
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = fileName;
    anchor.target = '_blank';
    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
  }
}

void openInNewTabWeb(String url) {
  web.window.open(url, '_blank');
}
