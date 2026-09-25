import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;

Uint8List processScanPage((Uint8List, int, int, List<double>, int) request) {
  final (bytes, preset, turns, crop, edge) = request;
  final decoder = img.findDecoderForData(bytes);
  final info = decoder?.startDecode(bytes);
  if (info == null || info.width * info.height > 40000000) {
    throw const FormatException('Use a camera image up to 40 megapixels.');
  }
  final decoded = decoder!.decodeFrame(0);
  if (decoded == null) throw const FormatException('Could not process this camera image.');
  var page = img.bakeOrientation(decoded);
  if (turns % 4 != 0) page = img.copyRotate(page, angle: (turns % 4) * 90);
  if (crop.length != 4 || crop.any((v) => !v.isFinite || v < 0 || v > 0.45)) {
    throw const FormatException('Invalid page crop.');
  }
  final left = (page.width * crop[0]).round();
  final top = (page.height * crop[1]).round();
  page = img.copyCrop(page, x: left, y: top,
      width: (page.width * (1 - crop[0] - crop[2])).round().clamp(1, page.width - left),
      height: (page.height * (1 - crop[1] - crop[3])).round().clamp(1, page.height - top));
  if (page.width > edge || page.height > edge) {
    page = img.copyResize(page, width: page.width >= page.height ? edge : null,
        height: page.height > page.width ? edge : null);
  }
  if (preset == 1) page = img.adjustColor(img.grayscale(page), contrast: 1.35);
  if (preset == 2) page = img.adjustColor(page, contrast: 1.55, saturation: 0.15, gamma: 1.05);
  return img.encodeJpg(page, quality: 90);
}

Future<Uint8List> assembleScanPdf(List<Uint8List> pages) async {
  final pdf = pw.Document();
  for (final bytes in pages) {
    final image = pw.MemoryImage(bytes);
    pdf.addPage(pw.Page(build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain))));
  }
  return pdf.save();
}
