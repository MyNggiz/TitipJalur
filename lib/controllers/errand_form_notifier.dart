import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/errand_model.dart';
import '../repositories/errand_repository.dart';

class ErrandFormState {
  const ErrandFormState({
    this.item = '',
    this.pickup = '',
    this.dropoff = '',
    this.tip = '',
    this.category = 'Makanan',
    this.itemError,
    this.pickupError,
    this.dropoffError,
    this.tipError,
    this.isSubmitting = false,
    this.submitError,
    this.isSuccess = false,
    this.lastCreatedErrand,
  });

  final String item;
  final String pickup;
  final String dropoff;
  final String tip;
  final String category;
  final String? itemError;
  final String? pickupError;
  final String? dropoffError;
  final String? tipError;
  final bool isSubmitting;
  final String? submitError;
  final bool isSuccess;
  final ErrandModel? lastCreatedErrand;

  int get parsedTip {
    final cleanTip = tip.replaceAll(RegExp(r'[^0-9]'), '').trim();
    return int.tryParse(cleanTip.isEmpty ? tip.trim() : cleanTip) ?? 0;
  }

  bool get isValid =>
      item.trim().length >= 3 &&
      pickup.trim().length >= 3 &&
      dropoff.trim().length >= 3 &&
      parsedTip >= 2000;

  static const Object _sentinel = Object();

  ErrandFormState copyWith({
    String? item,
    String? pickup,
    String? dropoff,
    String? tip,
    String? category,
    Object? itemError = _sentinel,
    Object? pickupError = _sentinel,
    Object? dropoffError = _sentinel,
    Object? tipError = _sentinel,
    bool? isSubmitting,
    Object? submitError = _sentinel,
    bool? isSuccess,
    Object? lastCreatedErrand = _sentinel,
  }) {
    return ErrandFormState(
      item: item ?? this.item,
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      tip: tip ?? this.tip,
      category: category ?? this.category,
      itemError: identical(itemError, _sentinel)
          ? this.itemError
          : itemError as String?,
      pickupError: identical(pickupError, _sentinel)
          ? this.pickupError
          : pickupError as String?,
      dropoffError: identical(dropoffError, _sentinel)
          ? this.dropoffError
          : dropoffError as String?,
      tipError: identical(tipError, _sentinel)
          ? this.tipError
          : tipError as String?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: identical(submitError, _sentinel)
          ? this.submitError
          : submitError as String?,
      isSuccess: isSuccess ?? this.isSuccess,
      lastCreatedErrand: identical(lastCreatedErrand, _sentinel)
          ? this.lastCreatedErrand
          : lastCreatedErrand as ErrandModel?,
    );
  }
}

class ErrandFormNotifier extends StateNotifier<ErrandFormState> {
  ErrandFormNotifier() : super(const ErrandFormState());

  void setItem(String value) {
    String? error = state.itemError;
    if (error != null) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        error = 'Nama barang wajib diisi';
      } else if (trimmed.length < 3) {
        error = 'Nama barang minimal 3 karakter';
      } else {
        error = null;
      }
    }
    state = state.copyWith(item: value, itemError: error);
  }

  void setPickup(String value) {
    String? error = state.pickupError;
    if (error != null) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        error = 'Lokasi pengambilan wajib diisi';
      } else if (trimmed.length < 3) {
        error = 'Lokasi pickup minimal 3 karakter';
      } else {
        error = null;
      }
    }
    state = state.copyWith(pickup: value, pickupError: error);
  }

  void setDropoff(String value) {
    String? error = state.dropoffError;
    if (error != null) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        error = 'Lokasi tujuan wajib diisi';
      } else if (trimmed.length < 3) {
        error = 'Lokasi dropoff minimal 3 karakter';
      } else {
        error = null;
      }
    }
    state = state.copyWith(dropoff: value, dropoffError: error);
  }

  void setTip(String value) {
    String? error = state.tipError;
    if (error != null) {
      final clean = value.replaceAll(RegExp(r'[^0-9]'), '').trim();
      final parsed = int.tryParse(clean.isEmpty ? value.trim() : clean);
      if (value.trim().isEmpty || parsed == null) {
        error = 'Nominal tip wajib diisi';
      } else if (parsed < 2000) {
        error = 'Nominal tip minimal Rp 2.000';
      } else {
        error = null;
      }
    }
    state = state.copyWith(tip: value, tipError: error);
  }

  void setCategory(String value) {
    state = state.copyWith(category: value);
  }

  bool validate() {
    String? itemError;
    final trimmedItem = state.item.trim();
    if (trimmedItem.isEmpty) {
      itemError = 'Nama barang wajib diisi';
    } else if (trimmedItem.length < 3) {
      itemError = 'Nama barang minimal 3 karakter';
    }

    String? pickupError;
    final trimmedPickup = state.pickup.trim();
    if (trimmedPickup.isEmpty) {
      pickupError = 'Lokasi pengambilan wajib diisi';
    } else if (trimmedPickup.length < 3) {
      pickupError = 'Lokasi pickup minimal 3 karakter';
    }

    String? dropoffError;
    final trimmedDropoff = state.dropoff.trim();
    if (trimmedDropoff.isEmpty) {
      dropoffError = 'Lokasi tujuan wajib diisi';
    } else if (trimmedDropoff.length < 3) {
      dropoffError = 'Lokasi dropoff minimal 3 karakter';
    }

    String? tipError;
    final cleanTip = state.tip.replaceAll(RegExp(r'[^0-9]'), '').trim();
    final parsedTip =
        int.tryParse(cleanTip.isEmpty ? state.tip.trim() : cleanTip);
    if (state.tip.trim().isEmpty || parsedTip == null) {
      tipError = 'Nominal tip wajib diisi';
    } else if (parsedTip < 2000) {
      tipError = 'Nominal tip minimal Rp 2.000';
    }

    state = state.copyWith(
      itemError: itemError,
      pickupError: pickupError,
      dropoffError: dropoffError,
      tipError: tipError,
    );

    return itemError == null &&
        pickupError == null &&
        dropoffError == null &&
        tipError == null;
  }

  Future<bool> submit(
    ErrandRepository repository, {
    required String requesterName,
    bool simulateError = false,
  }) async {
    if (!validate()) {
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      submitError: null,
      isSuccess: false,
    );

    try {
      final cleanTip = state.tip.replaceAll(RegExp(r'[^0-9]'), '').trim();
      final parsedTip =
          int.tryParse(cleanTip.isEmpty ? state.tip.trim() : cleanTip) ?? 0;

      final newErrand = ErrandModel(
        id: 'err_${DateTime.now().millisecondsSinceEpoch}',
        item: state.item.trim(),
        pickup: state.pickup.trim(),
        dropoff: state.dropoff.trim(),
        tip: parsedTip,
        requester: requesterName,
        status: OrderStatus.open,
        distanceKm: 0.8,
        category: state.category.isNotEmpty ? state.category : 'Makanan',
      );

      final created = await repository.createErrand(
        newErrand,
        simulateError: simulateError,
      );
      state = state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        lastCreatedErrand: created,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  void reset() {
    state = const ErrandFormState();
  }
}

final errandFormNotifierProvider =
    StateNotifierProvider<ErrandFormNotifier, ErrandFormState>((ref) {
  return ErrandFormNotifier();
});
