import 'package:delivery_express_mobility_frontend/design_system/index.dart';
import 'package:flutter/material.dart';

/// Chip pour mode de paiement
class DriverPaymentChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  const DriverPaymentChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DEMSpacing.md,
          vertical: DEMSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? backgroundColor
              : backgroundColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? backgroundColor
                : backgroundColor.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? textColor : textColor.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.check_circle,
                size: 18,
                color: textColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
