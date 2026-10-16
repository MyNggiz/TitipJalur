import 'package:flutter/material.dart';

enum OrderStatus {
  open,
  accepted,
  completed;

  String get label {
    switch (this) {
      case OrderStatus.open:
        return 'Terbuka';
      case OrderStatus.accepted:
        return 'Diambil';
      case OrderStatus.completed:
        return 'Selesai';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.open:
        return const Color(0xFF059669);
      case OrderStatus.accepted:
        return const Color(0xFFD97706);
      case OrderStatus.completed:
        return const Color(0xFF4B5563);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case OrderStatus.open:
        return const Color(0xFFECFDF5);
      case OrderStatus.accepted:
        return const Color(0xFFFEF3C7);
      case OrderStatus.completed:
        return const Color(0xFFF3F4F6);
    }
  }
}

class ErrandModel {
  final String id;
  final String item;
  final String pickup;
  final String dropoff;
  final int tip;
  final String requester;
  final OrderStatus status;
  final double distanceKm;
  final String category;

  const ErrandModel({
    required this.id,
    required this.item,
    required this.pickup,
    required this.dropoff,
    required this.tip,
    required this.requester,
    this.status = OrderStatus.open,
    this.distanceKm = 1.0,
    this.category = 'Kantin',
  });

  String get formattedTip {
    if (tip <= 0) return 'Rp 0';
    final tipStr = tip.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < tipStr.length; i++) {
      if (i > 0 && (tipStr.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(tipStr[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  ErrandModel copyWith({
    String? id,
    String? item,
    String? pickup,
    String? dropoff,
    int? tip,
    String? requester,
    OrderStatus? status,
    double? distanceKm,
    String? category,
  }) {
    return ErrandModel(
      id: id ?? this.id,
      item: item ?? this.item,
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      tip: tip ?? this.tip,
      requester: requester ?? this.requester,
      status: status ?? this.status,
      distanceKm: distanceKm ?? this.distanceKm,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item': item,
      'pickup': pickup,
      'dropoff': dropoff,
      'tip': tip,
      'requester': requester,
      'status': status.name,
      'distanceKm': distanceKm,
      'category': category,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  /// Strict JSON deserialization according to P6 API Contract specifications.
  /// Throws [FormatException] if any mandatory field is missing, null, or has an invalid type.
  factory ErrandModel.fromJson(Map<String, dynamic> json) {
    // Validate 'id': must be present and must be String or int
    if (!json.containsKey('id') || json['id'] == null) {
      throw const FormatException('Format id salah atau hilang');
    }
    final idRaw = json['id'];
    if (idRaw is! String && idRaw is! int) {
      throw const FormatException('Format id harus berupa string atau integer');
    }
    final idStr = idRaw.toString().trim();
    if (idStr.isEmpty) {
      throw const FormatException('Format id tidak boleh kosong');
    }

    // Validate 'item': must be non-empty String
    if (!json.containsKey('item') || json['item'] is! String) {
      throw const FormatException('Format item salah atau bukan string');
    }
    final itemStr = (json['item'] as String).trim();
    if (itemStr.isEmpty) {
      throw const FormatException('Format item tidak boleh kosong');
    }

    // Validate 'pickup': must be non-empty String
    if (!json.containsKey('pickup') || json['pickup'] is! String) {
      throw const FormatException('Format pickup salah atau bukan string');
    }
    final pickupStr = (json['pickup'] as String).trim();
    if (pickupStr.isEmpty) {
      throw const FormatException('Format pickup tidak boleh kosong');
    }

    // Validate 'dropoff': must be non-empty String
    if (!json.containsKey('dropoff') || json['dropoff'] is! String) {
      throw const FormatException('Format dropoff salah atau bukan string');
    }
    final dropoffStr = (json['dropoff'] as String).trim();
    if (dropoffStr.isEmpty) {
      throw const FormatException('Format dropoff tidak boleh kosong');
    }

    // Validate 'tip': must be a numeric integer/double >= 0
    if (!json.containsKey('tip') || json['tip'] is! num) {
      throw const FormatException('Format tip salah atau bukan angka');
    }
    final tipNum = (json['tip'] as num).toInt();
    if (tipNum < 0) {
      throw const FormatException('Format tip tidak boleh bernilai negatif');
    }

    // Validate 'requester': must be non-empty String
    if (!json.containsKey('requester') || json['requester'] is! String) {
      throw const FormatException('Format requester salah atau bukan string');
    }
    final requesterStr = (json['requester'] as String).trim();
    if (requesterStr.isEmpty) {
      throw const FormatException('Format requester tidak boleh kosong');
    }

    // Optional / Safe defaults: status, distanceKm, category
    final statusStr = json['status'] as String?;
    OrderStatus parsedStatus = OrderStatus.open;
    if (statusStr != null) {
      for (final s in OrderStatus.values) {
        if (s.name.toLowerCase() == statusStr.toLowerCase()) {
          parsedStatus = s;
          break;
        }
      }
    }

    final distanceRaw = json['distanceKm'];
    final double parsedDistance;
    if (distanceRaw is num) {
      parsedDistance = distanceRaw.toDouble();
    } else {
      parsedDistance = 1.0;
    }

    final categoryStr = json['category'] as String?;
    final parsedCategory = (categoryStr != null && categoryStr.isNotEmpty)
        ? categoryStr
        : 'Kantin';

    return ErrandModel(
      id: idStr,
      item: itemStr,
      pickup: pickupStr,
      dropoff: dropoffStr,
      tip: tipNum,
      requester: requesterStr,
      status: parsedStatus,
      distanceKm: parsedDistance,
      category: parsedCategory,
    );
  }

  factory ErrandModel.fromMap(Map<String, dynamic> map) {
    try {
      return ErrandModel.fromJson(map);
    } catch (_) {
      final statusStr = map['status'] as String?;
      OrderStatus parsedStatus = OrderStatus.open;
      if (statusStr != null) {
        for (final s in OrderStatus.values) {
          if (s.name == statusStr) {
            parsedStatus = s;
            break;
          }
        }
      }

      return ErrandModel(
        id: map['id']?.toString() ?? '',
        item: map['item'] as String? ?? '',
        pickup: map['pickup'] as String? ?? '',
        dropoff: map['dropoff'] as String? ?? '',
        tip: (map['tip'] as num?)?.toInt() ?? 0,
        requester: map['requester'] as String? ?? '',
        status: parsedStatus,
        distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
        category: map['category'] as String? ?? 'Umum',
      );
    }
  }

  @override
  String toString() {
    return 'ErrandModel(id: $id, item: $item, pickup: $pickup, dropoff: $dropoff, tip: $tip, requester: $requester, status: $status, distanceKm: $distanceKm, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ErrandModel &&
        other.id == id &&
        other.item == item &&
        other.pickup == pickup &&
        other.dropoff == dropoff &&
        other.tip == tip &&
        other.requester == requester &&
        other.status == status &&
        other.distanceKm == distanceKm &&
        other.category == category;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        item.hashCode ^
        pickup.hashCode ^
        dropoff.hashCode ^
        tip.hashCode ^
        requester.hashCode ^
        status.hashCode ^
        distanceKm.hashCode ^
        category.hashCode;
  }
}
