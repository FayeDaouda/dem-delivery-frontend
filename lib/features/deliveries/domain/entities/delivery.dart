import 'package:equatable/equatable.dart';

class Delivery extends Equatable {
  final String id;
  final String pickupAddress;
  final String deliveryAddress;
  final String status; // PENDING, IN_PROGRESS, COMPLETED, CANCELLED
  final String clientName;
  final String clientPhone;
  final double amount;
  final DateTime createdAt;
  final DateTime? completedAt;
  final double? distance; // en km
  final int? estimatedTime; // en minutes

  const Delivery({
    required this.id,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.status,
    required this.clientName,
    required this.clientPhone,
    required this.amount,
    required this.createdAt,
    this.completedAt,
    this.distance,
    this.estimatedTime,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: (json['id'] ?? '').toString(),
      pickupAddress: (json['pickupAddress'] ?? '').toString(),
      deliveryAddress: (json['deliveryAddress'] ?? '').toString(),
      status: (json['status'] ?? 'PENDING').toString(),
      clientName: (json['clientName'] ?? '').toString(),
      clientPhone: (json['clientPhone'] ?? '').toString(),
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse((json['amount'] ?? '0').toString()) ?? 0,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      distance: json['distance'] is num
          ? (json['distance'] as num).toDouble()
          : double.tryParse((json['distance'] ?? '').toString()),
      estimatedTime: json['estimatedTime'] is int
          ? json['estimatedTime'] as int
          : int.tryParse((json['estimatedTime'] ?? '').toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pickupAddress': pickupAddress,
      'deliveryAddress': deliveryAddress,
      'status': status,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'distance': distance,
      'estimatedTime': estimatedTime,
    };
  }

  @override
  List<Object?> get props => [
        id,
        pickupAddress,
        deliveryAddress,
        status,
        clientName,
        clientPhone,
        amount,
        createdAt,
        completedAt,
        distance,
        estimatedTime,
      ];
}
