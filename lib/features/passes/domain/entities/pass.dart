import 'package:equatable/equatable.dart';

class Pass extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final int validityDays;
  final int usageLimit;
  final int usageCount;
  final bool isActive;
  final DateTime? activatedAt;
  final DateTime? expiresAt;

  const Pass({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.validityDays,
    required this.usageLimit,
    required this.usageCount,
    required this.isActive,
    this.activatedAt,
    this.expiresAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        validityDays,
        usageLimit,
        usageCount,
        isActive,
        activatedAt,
        expiresAt,
      ];
}
