import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Exception thrown when camera or gallery permissions are permanently or explicitly denied.
class CameraPermissionException implements Exception {
  final String message;
  const CameraPermissionException(this.message);

  @override
  String toString() => 'CameraPermissionException: $message';
}

/// Abstract contract for camera and image capture operations, enabling unit test mocking.
abstract class IPodCameraService {
  Future<String?> captureProofOfDelivery({
    ImageSource source = ImageSource.camera,
  });

  Future<bool> verifyImageExists(String path);
}

/// Production implementation of Proof of Delivery (POD) camera service using [ImagePicker].
class PodCameraService implements IPodCameraService {
  PodCameraService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> captureProofOfDelivery({
    ImageSource source = ImageSource.camera,
  }) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (photo == null) {
        // User deliberately cancelled the camera or gallery picker
        return null;
      }

      final file = File(photo.path);
      if (!await file.exists()) {
        throw const FileSystemException('Berkas foto bukti tidak ditemukan di penyimpanan.');
      }

      return photo.path;
    } catch (e) {
      if (e is CameraPermissionException || e is FileSystemException) {
        rethrow;
      }
      final msg = e.toString().toLowerCase();
      if (msg.contains('permission') || msg.contains('denied')) {
        throw const CameraPermissionException(
          'Izin akses kamera atau galeri ditolak. Mohon aktifkan izin di pengaturan perangkat.',
        );
      }
      debugPrint('[PodCameraService] Error saat mengambil foto bukti: $e');
      rethrow;
    }
  }

  @override
  Future<bool> verifyImageExists(String path) async {
    try {
      if (path.isEmpty) return false;
      return await File(path).exists();
    } catch (_) {
      return false;
    }
  }
}
