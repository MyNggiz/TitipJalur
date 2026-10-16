import '../models/errand_model.dart';

/// Exception thrown when errand fields violate basic formatting or domain constraints.
class ErrandValidationException implements Exception {
  final String message;
  const ErrandValidationException(this.message);

  @override
  String toString() => 'ErrandValidationException: $message';
}

/// Exception thrown when an operation violates state machine transition constraints.
class ErrandStateException implements Exception {
  final String message;
  const ErrandStateException(this.message);

  @override
  String toString() => 'ErrandStateException: $message';
}

/// Exception thrown when business ethics/marketplace rules are violated (e.g. self-dealing).
class ErrandBusinessException implements Exception {
  final String message;
  const ErrandBusinessException(this.message);

  @override
  String toString() => 'ErrandBusinessException: $message';
}

/// Centralized business logic and domain validation engine for TitipJalur MVP.
class ErrandBusinessValidator {
  /// Minimum tip amount in IDR according to TitipJalur campus commuter compensation rules.
  static const int minTipAmount = 2000;

  /// Minimum character length for item description.
  static const int minItemLength = 3;

  /// Validates a new errand request before creation and publishing.
  static void validateErrandCreation(ErrandModel errand) {
    if (errand.item.trim().length < minItemLength) {
      throw ErrandValidationException(
        'Nama barang titipan minimal harus $minItemLength karakter.',
      );
    }

    if (errand.pickup.trim().isEmpty) {
      throw const ErrandValidationException(
        'Lokasi penjemputan (pickup) tidak boleh kosong.',
      );
    }

    if (errand.dropoff.trim().isEmpty) {
      throw const ErrandValidationException(
        'Lokasi pengantaran (dropoff) tidak boleh kosong.',
      );
    }

    if (errand.pickup.trim().toLowerCase() ==
        errand.dropoff.trim().toLowerCase()) {
      throw const ErrandValidationException(
        'Lokasi penjemputan dan pengantaran tidak boleh sama persis.',
      );
    }

    if (errand.tip < minTipAmount) {
      throw ErrandValidationException(
        'Tip imbalan komuter minimal adalah Rp ${minTipAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}.',
      );
    }

    if (errand.requester.trim().isEmpty) {
      throw const ErrandValidationException(
        'Identitas pemohon (requester) tidak boleh kosong.',
      );
    }
  }

  /// Validates whether a runner can claim/accept an errand.
  /// Prevents invalid state claims and anti-self-dealing.
  static void validateAccept(ErrandModel errand, String runnerName) {
    if (errand.status != OrderStatus.open) {
      if (errand.status == OrderStatus.accepted) {
        throw const ErrandStateException(
          'Pesanan ini sudah diambil oleh komuter lain.',
        );
      }
      throw const ErrandStateException(
        'Pesanan ini sudah selesai dan tidak dapat diambil kembali.',
      );
    }

    final trimmedRunner = runnerName.trim();
    if (trimmedRunner.isEmpty) {
      throw const ErrandValidationException(
        'Nama komuter / runner tidak boleh kosong saat mengambil titipan.',
      );
    }

    if (trimmedRunner.toLowerCase() == errand.requester.trim().toLowerCase()) {
      throw const ErrandBusinessException(
        'Pelanggaran aturan: Pemohon dilarang mengambil atau mengantar titipannya sendiri (Anti-Self-Dealing).',
      );
    }
  }

  /// Validates whether an errand can transition to completed.
  static void validateComplete(ErrandModel errand) {
    if (errand.status == OrderStatus.open) {
      throw const ErrandStateException(
        'Pesanan masih berstatus Terbuka (Open) dan belum diambil oleh runner, sehingga belum dapat diselesaikan.',
      );
    }

    if (errand.status == OrderStatus.completed) {
      throw const ErrandStateException(
        'Pesanan ini sudah ditandai selesai sebelumnya.',
      );
    }
  }

  /// Validates whether an errand can be cancelled or deleted by requester.
  /// Prevents abrupt cancellation when a runner is already actively delivering it (Accepted).
  static void validateCancellation(ErrandModel errand) {
    if (errand.status == OrderStatus.accepted) {
      throw const ErrandStateException(
        'Pesanan yang sedang aktif diantar oleh komuter (Accepted) tidak dapat dibatalkan secara sepihak.',
      );
    }
  }
}
