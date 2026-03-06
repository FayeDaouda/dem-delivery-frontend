import 'package:flutter/material.dart';
import '../../design_system/index.dart';

class PassActivationPanel extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onBack;
  final Function(String paymentMethod, String? promoCode) onActivate;

  const PassActivationPanel({
    super.key,
    required this.isLoading,
    required this.onBack,
    required this.onActivate,
  });

  @override
  State<PassActivationPanel> createState() => _PassActivationPanelState();
}

class _PassActivationPanelState extends State<PassActivationPanel> {
  String selectedPayment = "wave";
  bool showPromo = false;

  final TextEditingController promoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// HEADER
          Row(
            children: [
              IconButton(
                onPressed: widget.isLoading ? null : widget.onBack,
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  "Activer Pass",
                  textAlign: TextAlign.center,
                  style: DEMTypography.h3.copyWith(
                    color: DEMColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),

          const SizedBox(height: DEMSpacing.lg),

          /// CARD PASS
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DEMSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: DEMRadii.borderRadiusLg,
              color: DEMColors.gray50,
              border: Border.all(color: DEMColors.gray200),
            ),
            child: Column(
              children: [
                Text("🚀 PASS LIVREUR",
                    style: DEMTypography.h2.copyWith(
                      color: DEMColors.primary,
                      fontWeight: FontWeight.bold,
                    )),

                const SizedBox(height: DEMSpacing.sm),

                Text(
                  "2000 FCFA",
                  style: DEMTypography.h1.copyWith(
                    fontSize: 32,
                    color: Colors.green,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: DEMSpacing.xs),

                Text(
                  "Valable 24 heures",
                  style: DEMTypography.body2.copyWith(
                    color: DEMColors.gray700,
                  ),
                ),

                const SizedBox(height: DEMSpacing.sm),

                Text(
                  "💰 Rentabilisé dès 2 livraisons",
                  style: DEMTypography.body2.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: DEMSpacing.lg),

          /// CODE PROMO
          GestureDetector(
            onTap: () {
              setState(() {
                showPromo = !showPromo;
              });
            },
            child: Text(
              "+ Ajouter un code promo",
              style: DEMTypography.body2.copyWith(
                color: DEMColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          if (showPromo)
            Padding(
              padding: const EdgeInsets.only(top: DEMSpacing.sm),
              child: TextField(
                controller: promoController,
                decoration: InputDecoration(
                  hintText: "Code promo",
                  border: OutlineInputBorder(
                    borderRadius: DEMRadii.borderRadiusMd,
                  ),
                ),
              ),
            ),

          const SizedBox(height: DEMSpacing.xl),

          /// PAIEMENT
          Text(
            "Choisir paiement",
            style: DEMTypography.body1.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: DEMSpacing.md),

          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _paymentOption("wave", "Wave", "W", const Color(0xFF00A3FF)),
                _paymentOption("orange", "Orange", "OM", const Color(0xFFFF6600)),
                _paymentOption("yas", "Yas", "Y", const Color(0xFF9C27B0)),
              ],
            ),
          ),

          const SizedBox(height: DEMSpacing.xl),

          /// BOUTON ACTIVER
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: widget.isLoading
                  ? null
                  : () {
                      widget.onActivate(
                        selectedPayment,
                        promoController.text.isEmpty
                            ? null
                            : promoController.text,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: DEMColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: DEMRadii.borderRadiusMd,
                ),
              ),
              child: widget.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "ACTIVER PASS",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 30),

          Center(
            child: Text(
              "Paiement via opérateur mobile",
              style: DEMTypography.caption.copyWith(
                color: DEMColors.gray500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentOption(
      String value, String label, String icon, Color color) {
    final bool selected = selectedPayment == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPayment = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: DEMSpacing.md),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: selected
                    ? Border.all(color: Colors.black, width: 3)
                    : null,
              ),
              child: Center(
                child: Text(
                  icon,
                  style: DEMTypography.body1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}