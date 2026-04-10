import 'package:flutter/services.dart';

/// Simulates a native file picker functionality.
/// This is a mock implementation to resolve compilation errors.
/// In a real scenario, you would use a package like 'file_picker'.
Future<void> pickNativeFile({
  required void Function(String name, Uint8List? bytes) onSelected,
}) async {
  // Simulate native delay
  await Future.delayed(const Duration(milliseconds: 500));

  // Mock data for demonstration
  // In a real implementation, this would trigger a system dialog.
  onSelected("mock_document.pdf", Uint8List.fromList([0, 1, 2, 3]));
}
