/// 🎫 Pass Activation Detail Widget
import 'package:flutter/material.dart';

import '../design_system/index.dart';

class PassActivationPanel extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onActivateWithWave;
  final VoidCallback onActivateWithOrangeMoney;
  final VoidCallback onActivateWithYas;
  final bool isLoading;

  const PassActivationPanel({
    super.key,
    required this.onBack,
    required this.onActivateWithWave,
    required this.onActivateWithOrangeMoney,
    required this.onActivateWithYas,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Back Button + Title
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
            ),
            Expanded(
              child: Text(
                'Activation de pass',
                textAlign: TextAlign.center,
                style: DEMTypography.h3.copyWith(
                  color: DEMColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 48), // Balance with back button
          ],
        ),
        const SizedBox(height: DEMSpacing.lg),

        // Description
        Text(
          'Le pass journalier vous permet de recevoir des demandes de livraison pendant 24 heures, selon votre position.',
          textAlign: TextAlign.center,
          style: DEMTypography.body1.copyWith(
            color: DEMColors.gray700,
            height: 1.5,
          ),
        ),
        const SizedBox(height: DEMSpacing.xl),

        // 📋 Pass Card Details
        Container(
          padding: const EdgeInsets.all(DEMSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.card_membership, color: DEMColors.primary),
                  const SizedBox(width: DEMSpacing.md),
                  Text(
                    'Carte du pass',
                    style: DEMTypography.subtitle1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DEMSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _passInfoChip(
                    icon: Icons.calendar_today,
                    label: 'Pass journalier',
                  ),
                  _passInfoChip(
                    icon: Icons.schedule,
                    label: 'Valable 24h',
                  ),
                  _passInfoChip(
                    icon: Icons.money,
                    label: 'Prix: X FCFA',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: DEMSpacing.xl),

        // 🎁 Promo Code
        Container(
          padding: const EdgeInsets.all(DEMSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_offer, color: DEMColors.primary),
                  const SizedBox(width: DEMSpacing.md),
                  Text(
                    'Code de promo',
                    style: DEMTypography.subtitle1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DEMSpacing.md),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Entrez votre code (optionnel)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: DEMSpacing.md,
                    vertical: DEMSpacing.md,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DEMSpacing.xl),

        // 💳 Payment Methods
        Container(
          padding: const EdgeInsets.all(DEMSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.payment, color: DEMColors.primary),
                  const SizedBox(width: DEMSpacing.md),
                  Text(
                    'Moyens de paiement',
                    style: DEMTypography.subtitle1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DEMSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _paymentMethodButton(
                    label: 'Orange Money',
                    onTap: isLoading ? null : onActivateWithOrangeMoney,
                    isLoading: isLoading,
                  ),
                  _paymentMethodButton(
                    label: 'Yas',
                    onTap: isLoading ? null : onActivateWithYas,
                    isLoading: isLoading,
                  ),
                  _paymentMethodButton(
                    label: 'Wave',
                    onTap: isLoading ? null : onActivateWithWave,
                    isLoading: isLoading,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: DEMSpacing.xl),
      ],
    );
  }

  Widget _passInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: DEMColors.primary, size: 24),
        const SizedBox(height: DEMSpacing.sm),
        Text(
          label,
          textAlign: TextAlign.center,
          style: DEMTypography.caption.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _paymentMethodButton({
    required String label,
    required VoidCallback? onTap,
    required bool isLoading,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.7),
              border: Border.all(
                color: DEMColors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          DEMColors.primary,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      label == 'Wave'
                          ? 'W'
                          : label == 'Yas'
                              ? 'Y'
                              : 'OM',
                      style: DEMTypography.h2.copyWith(
                        color: DEMColors.primary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: DEMSpacing.sm),
          Text(
            label,
            style: DEMTypography.caption.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
