import 'package:flutter/material.dart';

import '../../design_system/index.dart';

/// Panel de bienvenue pour les livreurs sans pass actif
class WelcomePanel extends StatelessWidget {
  final int nearbyDeliveriesCount;
  final VoidCallback onActivatePass;
  final VoidCallback onGoToKyc;
  final bool hasPass;

  const WelcomePanel({
    super.key,
    required this.nearbyDeliveriesCount,
    required this.onActivatePass,
    required this.onGoToKyc,
    this.hasPass = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '👋 Bienvenue sur Dakar Speed Pro',
            textAlign: TextAlign.center,
            style: DEMTypography.h3.copyWith(
              color: DEMColors.primary,
            ),
          ),
          const SizedBox(height: DEMSpacing.md),
          Divider(
            height: 1,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
          const SizedBox(height: DEMSpacing.lg),
          Text(
            'Pour accéder aux livraisons disponibles autour de vous, vous devez activer un pass journalier.',
            textAlign: TextAlign.center,
            style: DEMTypography.body1.copyWith(
              color: DEMColors.gray700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: DEMSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: DEMSpacing.md,
              vertical: DEMSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: DEMColors.gray100,
              borderRadius: DEMRadii.borderRadiusMd,
              border: Border.all(
                color: DEMColors.gray300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_rounded,
                  color: DEMColors.gray600,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🔒 $nearbyDeliveriesCount livraisons verrouillées',
                    style: DEMTypography.body2.copyWith(
                      color: DEMColors.gray700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DEMSpacing.sm),
          Text(
            'Activez un pass pour y accéder',
            style: DEMTypography.caption.copyWith(
              color: DEMColors.gray600,
            ),
          ),
          const SizedBox(height: DEMSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onActivatePass,
              icon: const Icon(Icons.access_time, color: Colors.white),
              label: Text(
                'Activer un pass journalier',
                style: DEMTypography.button.copyWith(
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: DEMColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: DEMSpacing.lg,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: DEMRadii.borderRadiusLg,
                ),
                elevation: 4,
              ),
            ),
          ),
          const SizedBox(height: DEMSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onGoToKyc,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text(
                'Finaliser l\'inscription (Soumettre les documents)',
                textAlign: TextAlign.center,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: DEMColors.primary,
                side: const BorderSide(
                  color: DEMColors.primary,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: DEMSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: DEMRadii.borderRadiusMd,
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
