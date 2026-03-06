import 'package:flutter/material.dart';

import '../design_system/tokens/colors.dart';
import '../design_system/tokens/spacing.dart';

/// Widget de sélection du type de driver (MOTO ou VTC)
/// Utilisé à l'étape 3 du flux OTP-Only
class DriverTypeSelector extends StatelessWidget {
  final String? selectedType; // "MOTO" ou "VTC" ou null
  final Function(String) onSelected; // Callback : "MOTO" ou "VTC"
  final bool isLoading;

  const DriverTypeSelector({
    super.key,
    required this.selectedType,
    required this.onSelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Titre
        Text(
          'Quel type de driver êtes-vous ?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: DEMColors.gray900,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DEMSpacing.lg),

        // Grille 2 colonnes avec cartes
        Row(
          children: [
            // Carte MOTO
            Expanded(
              child: _DriverTypeCard(
                type: 'MOTO',
                icon: '🏍️',
                title: 'MOTO',
                description: 'Livrez les colis\net commandes',
                price: '~500 CFA/jour',
                benefits: const [
                  'Passe journalier',
                  'Accès illimité',
                  'Paiement direct',
                ],
                isSelected: selectedType == 'MOTO',
                isLoading: isLoading,
                onTap: () => onSelected('MOTO'),
              ),
            ),
            const SizedBox(width: DEMSpacing.md),

            // Carte VTC
            Expanded(
              child: _DriverTypeCard(
                type: 'VTC',
                icon: '🚕',
                title: 'VTC',
                description: 'Transport de\npassagers',
                price: '~500 CFA/jour',
                benefits: const [
                  'Passe journalier',
                  'Accès illimité',
                  'Paiement direct',
                ],
                isSelected: selectedType == 'VTC',
                isLoading: isLoading,
                onTap: () => onSelected('VTC'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Carte individuelle pour un type de driver
class _DriverTypeCard extends StatelessWidget {
  final String type;
  final String icon;
  final String title;
  final String description;
  final String price;
  final List<String> benefits;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;

  const _DriverTypeCard({
    required this.type,
    required this.icon,
    required this.title,
    required this.description,
    required this.price,
    required this.benefits,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? DEMColors.primary
                : DEMColors.gray300.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? DEMColors.primary.withOpacity(0.08)
              : Colors.white,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: DEMColors.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.all(DEMSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Text(
              icon,
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(height: DEMSpacing.sm),

            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? DEMColors.primary
                        : DEMColors.gray900,
                  ),
            ),
            const SizedBox(height: DEMSpacing.xs),

            // Description
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DEMColors.gray600,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: DEMSpacing.md),

            // Price
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DEMSpacing.sm,
                vertical: DEMSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: DEMColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                price,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DEMColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: DEMSpacing.md),

            // Benefits
            ...benefits.map((benefit) => Padding(
              padding: const EdgeInsets.only(bottom: DEMSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '✓',
                    style: TextStyle(
                      color: DEMColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: DEMSpacing.xs),
                  Expanded(
                    child: Text(
                      benefit,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DEMColors.gray900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),

            // Selection indicator
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: DEMSpacing.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DEMSpacing.md,
                    vertical: DEMSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: DEMColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: DEMSpacing.xs),
                      Text(
                        'Sélectionné',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
