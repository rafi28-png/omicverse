import 'dart:typed_data';
import 'package:file_picker/file_picker.dart' as fp;
import '../models/app_error.dart';
import 'file_validator.dart';

/// Result of a file pick + validate operation
class PickedFile {
  final String filename;
  final Uint8List bytes;
  final FileType fileType;
  final int sizeBytes;
  final bool sizeWarning;

  const PickedFile({
    required this.filename,
    required this.bytes,
    required this.fileType,
    required this.sizeBytes,
    this.sizeWarning = false,
  });
}

class FileUploadService {
  /// Pick a file and validate it. Returns null if user cancelled.
  static Future<PickedFile?> pickAndValidate({
    required String module,
    List<String>? allowedExtensions,
  }) async {
    final result = await fp.FilePicker.platform.pickFiles(
      type: allowedExtensions != null ? fp.FileType.custom : fp.FileType.any,
      allowedExtensions: allowedExtensions,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final filename = file.name;
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      throw const ValidationError('Could not read file data. Please try again.');
    }

    // Get header bytes for BGZF detection (first 20 bytes)
    final headerBytes = bytes.length >= 20
        ? Uint8List.fromList(bytes.sublist(0, 20))
        : bytes;

    // Validate
    final validation = FileValidator.validate(
      filename: filename,
      sizeBytes: bytes.length,
      headerBytes: headerBytes,
      module: module,
    );

    if (!validation.isValid) {
      throw ValidationError(validation.error ?? 'Invalid file');
    }

    return PickedFile(
      filename: filename,
      bytes: bytes,
      fileType: validation.detectedType!,
      sizeBytes: bytes.length,
      sizeWarning: validation.sizeWarning,
    );
  }

  /// Format file size for display
  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
