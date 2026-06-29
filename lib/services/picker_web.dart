import 'package:universal_html/html.dart' as html;
import 'dart:typed_data';

Future<void> pickNativeFile({
  required void Function(String name, Uint8List bytes) onSelected,
}) async {
  final uploadInput = html.FileUploadInputElement();
  uploadInput.accept = 'image/*';
  uploadInput.click();

  uploadInput.onChange.listen((e) {
    if (uploadInput.files!.isNotEmpty) {
      final file = uploadInput.files![0];
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((e) {
        onSelected(file.name, reader.result as Uint8List);
      });
    }
  });
}
