import '../../domain/entities/pass.dart';

class PassModel extends Pass {
  const PassModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.validityDays,
    required super.usageLimit,
    required super.usageCount,
    required super.isActive,
    super.activatedAt,
    super.expiresAt,
  });

  factory PassModel.fromJson(Map<String, dynamic> json) {
    return PassModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      validityDays: json['validityDays'] ?? 0,
      usageLimit: json['usageLimit'] ?? 0,
      usageCount: json['usageCount'] ?? 0,
      isActive: json['isActive'] ?? false,
      activatedAt: json['activatedAt'] != null
          ? DateTime.parse(json['activatedAt'])
          : null,
      expiresAt:
          json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'validityDays': validityDays,
      'usageLimit': usageLimit,
      'usageCount': usageCount,
      'isActive': isActive,
      'activatedAt': activatedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}
