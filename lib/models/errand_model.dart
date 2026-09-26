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

  factory ErrandModel.fromMap(Map<String, dynamic> map) {
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
      id: map['id'] as String? ?? '',
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
