import 'dart:typed_data';

Future<void> pickNativeFile({
  required void Function(String name, Uint8List bytes) onSelected,
}) async {
  // No-op for non-web platforms (could implement mobile logic here)
}
