import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:document_management/features/documents/data/services/scan_processing.dart';

void main() {
  test('scan rotation, crop and previews share the exported page geometry', () {
    final source = img.encodePng(img.Image(width: 100, height: 60));
    final rotated = img.decodeJpg(processScanPage((source, 0, 1, [0,0,0,0], 2200)))!;
    expect(rotated.width, 60);
    expect(rotated.height, 100);
    final cropped = img.decodeJpg(processScanPage((source, 1, 0, [0.1,0,0.1,0], 2200)))!;
    expect(cropped.width, 80);
    expect(cropped.height, 60);
    final preview = img.decodeJpg(processScanPage((source, 1, 0, [0.1,0,0.1,0], 40)))!;
    expect(preview.width, 40);
    expect(preview.height, 30);
    expect(() => processScanPage((source, 0, 0, [0.8,0,0,0], 700)), throwsFormatException);
  });
}
