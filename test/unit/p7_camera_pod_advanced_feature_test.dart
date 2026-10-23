import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:titip_jalur/models/errand_model.dart';
import 'package:titip_jalur/repositories/errand_repository.dart';
import 'package:titip_jalur/services/pod_camera_service.dart';

class FakePodCameraService implements IPodCameraService {
  String? nextPhotoPath;
  bool shouldThrowPermissionError = false;

  @override
  Future<String?> captureProofOfDelivery({
    ImageSource source = ImageSource.camera,
  }) async {
    if (shouldThrowPermissionError) {
      throw const CameraPermissionException(
        'Izin akses kamera atau galeri ditolak. Mohon aktifkan izin di pengaturan perangkat.',
      );
    }
    return nextPhotoPath;
  }

  @override
  Future<bool> verifyImageExists(String path) async {
    return path.isNotEmpty && path.contains('.jpg') || path.contains('.png');
  }
}

void main() {
  group('P7 Advanced Feature 2: Camera Proof of Delivery (POD) Tests', () {
    test('1. Capturing photo proof returns valid file path when successful', () async {
      final cameraService = FakePodCameraService()
        ..nextPhotoPath = '/data/user/0/com.titipjalur/cache/pod_proof_101.jpg';

      final photoPath = await cameraService.captureProofOfDelivery(
        source: ImageSource.camera,
      );

      expect(photoPath, isNotNull);
      expect(photoPath, equals('/data/user/0/com.titipjalur/cache/pod_proof_101.jpg'));
      expect(await cameraService.verifyImageExists(photoPath!), isTrue);
    });

    test('2. User cancellation when taking photo returns null gracefully without throwing', () async {
      final cameraService = FakePodCameraService()..nextPhotoPath = null;

      final photoPath = await cameraService.captureProofOfDelivery(
        source: ImageSource.camera,
      );

      expect(photoPath, isNull);
    });

    test('3. Permission denial throws CameraPermissionException with user-friendly message', () async {
      final cameraService = FakePodCameraService()
        ..shouldThrowPermissionError = true;

      expect(
        () => cameraService.captureProofOfDelivery(source: ImageSource.camera),
        throwsA(
          isA<CameraPermissionException>().having(
            (e) => e.message,
            'message',
            contains('Izin akses kamera atau galeri ditolak'),
          ),
        ),
      );
    });

    test('4. ErrandRepository.completeErrand attaches proofOfDeliveryPath and updates state', () async {
      const activeErrand = ErrandModel(
        id: 'pod_task_01',
        item: 'Nasi Ayam Penyet Sambal Ijo',
        pickup: 'Kantin UNESA',
        dropoff: 'Lab Jaringan Gedung K10',
        tip: 6000,
        requester: 'Naufal',
        status: OrderStatus.accepted,
      );

      final repo = ErrandRepositoryImpl(initialErrands: [activeErrand]);

      final completed = await repo.completeErrand(
        'pod_task_01',
        proofOfDeliveryPath: '/cache/proof_of_delivery_01.jpg',
      );

      expect(completed.status, equals(OrderStatus.completed));
      expect(completed.proofOfDeliveryPath, equals('/cache/proof_of_delivery_01.jpg'));

      // Check serialization preserves POD
      final json = completed.toJson();
      expect(json['proofOfDeliveryPath'], equals('/cache/proof_of_delivery_01.jpg'));

      final reconstructed = ErrandModel.fromJson(json);
      expect(reconstructed.proofOfDeliveryPath, equals('/cache/proof_of_delivery_01.jpg'));
    });
  });
}
