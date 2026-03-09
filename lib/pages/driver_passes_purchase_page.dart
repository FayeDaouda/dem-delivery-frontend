import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/service_locator.dart';
import '../core/storage/secure_storage_service.dart';
import '../design_system/index.dart';
import '../features/passes/presentation/bloc/pass_bloc.dart';

/// Page d'achat de pass pour les livreurs qui n'ont pas de pass actif
/// Affichée lorsque hasActivePass = false
class DriverPassesPurchasePage extends StatelessWidget {
  const DriverPassesPurchasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PassBloc>()..add(const LoadPassStateEvent()),
      child: const _DriverPassesPurchaseContent(),
    );
  }
}

class _DriverPassesPurchaseContent extends StatelessWidget {
  const _DriverPassesPurchaseContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Acheter un Pass'),
        backgroundColor: DEMColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Mon Profil',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: BlocConsumer<PassBloc, PassState>(
        listener: (context, state) {
          if (state is PassActivationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Pass acheté avec succès!'),
                backgroundColor: Colors.green,
              ),
            );
            // Rediriger vers la page home selon le type driver
            Future.delayed(const Duration(seconds: 2), () async {
              if (context.mounted) {
                final storage = getIt<SecureStorageService>();
                final driverType =
                    (await storage.getDriverType())?.toUpperCase();
                final route =
                    driverType == 'VTC' ? '/driver/vtc/home' : '/livreurHome';
                Navigator.pushReplacementNamed(context, route);
              }
            });
          }
          if (state is PassError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is PassLoading;

          if (state is PassError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context
                        .read<PassBloc>()
                        .add(const LoadPassStateEvent()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          // Affiche la liste immédiatement + indicateur discret de chargement
          return Stack(
            children: [
              _buildPassList(context),
              if (isLoading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPassList(BuildContext context) {
    // Pass fictifs pour demonstration - à remplacer par API
    final passes = [
      {
        'id': '1',
        'name': 'Pass Journalier',
        'durationDays': 1,
        'price': 1000,
        'description': 'Valable 24 heures',
        'features': ['Livraisons illimitées', 'Support prioritaire'],
      },
      {
        'id': '2',
        'name': 'Pass Hebdomadaire',
        'durationDays': 7,
        'price': 5000,
        'description': 'Valable 7 jours',
        'features': [
          'Livraisons illimitées',
          'Support prioritaire',
          'Économie de 28%'
        ],
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DEMSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête informative
          Container(
            padding: const EdgeInsets.all(DEMSpacing.md),
            decoration: BoxDecoration(
              color: DEMColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DEMSpacing.sm),
              border: Border.all(
                color: DEMColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: DEMColors.primary),
                const SizedBox(width: DEMSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activez votre pass',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: DEMColors.primary,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Achetez un pass pour commencer à accepter des livraisons',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DEMSpacing.xl),

          // Liste des pass disponibles
          ...passes.map((pass) => _buildPassCard(context, pass)),
        ],
      ),
    );
  }

  Widget _buildPassCard(BuildContext context, dynamic pass) {
    final duration = pass['durationDays'] ?? 1;
    final passType =
        (pass['type']?.toString() ?? (duration > 1 ? 'weekly' : 'daily'))
            .toLowerCase();
    final name = pass['name'] ?? 'Pass';
    final price = pass['price'] ?? 0;
    final description = pass['description'] ?? '';
    final features = (pass['features'] as List?)?.cast<String>() ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: DEMSpacing.md),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DEMSpacing.sm),
        side: BorderSide(
          color: DEMColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DEMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du pass
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: DEMColors.primary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$duration jour${duration > 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: DEMColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$price FCFA',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),

            if (description.isNotEmpty) ...[
              const SizedBox(height: DEMSpacing.sm),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],

            if (features.isNotEmpty) ...[
              const SizedBox(height: DEMSpacing.md),
              const Divider(),
              const SizedBox(height: DEMSpacing.sm),
              ...features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 20,
                          color: Colors.green[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],

            const SizedBox(height: DEMSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showPurchaseCheckout(
                    context,
                    passType,
                    name,
                    price,
                    duration,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DEMColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DEMSpacing.sm),
                  ),
                ),
                child: const Text(
                  'Acheter ce pass',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPurchaseCheckout(
    BuildContext context,
    String passType,
    String passName,
    int price,
    int durationDays,
  ) {
    final promoController = TextEditingController();
    String selectedMethod = 'wave';
    int discountAmount = 0;
    int finalAmount = price;
    bool isVerifyingPromo = false;
    bool promoValidated = false;
    String? promoMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: DEMSpacing.md,
                  right: DEMSpacing.md,
                  top: DEMSpacing.md,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
                      DEMSpacing.md,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Finaliser l\'achat du pass',
                        style: Theme.of(sheetContext)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: DEMSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(DEMSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: DEMColors.gray200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(passName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                )),
                            const SizedBox(height: 6),
                            Text(
                                'Durée: $durationDays jour${durationDays > 1 ? 's' : ''}'),
                            const SizedBox(height: 4),
                            Text('Prix: $price FCFA'),
                            if (discountAmount > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Remise: -$discountAmount FCFA',
                                style: const TextStyle(color: Colors.green),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total: $finalAmount FCFA',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: DEMColors.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: DEMSpacing.md),
                      TextField(
                        controller: promoController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Code promo (optionnel)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: DEMSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: isVerifyingPromo
                            ? null
                            : () async {
                                final code = promoController.text.trim();
                                if (code.isEmpty) {
                                  setSheetState(() {
                                    promoValidated = false;
                                    discountAmount = 0;
                                    finalAmount = price;
                                    promoMessage =
                                        'Saisissez un code promo avant vérification.';
                                  });
                                  return;
                                }

                                setSheetState(() {
                                  isVerifyingPromo = true;
                                  promoMessage = null;
                                });

                                try {
                                  final dio = getIt<Dio>();
                                  final response = await dio.post(
                                    '/promo-codes/validate',
                                    data: {
                                      'code': code,
                                      'amount': price,
                                    },
                                  );

                                  final data = response.data;
                                  final promoData = data is Map
                                      ? (data['data'] as Map?)
                                      : null;
                                  final applicableDiscount =
                                      (promoData?['applicableDiscount'] as num?)
                                              ?.toInt() ??
                                          0;
                                  final computedFinal =
                                      (promoData?['finalAmount'] as num?)
                                              ?.toInt() ??
                                          (price - applicableDiscount);

                                  setSheetState(() {
                                    promoValidated = true;
                                    discountAmount = applicableDiscount;
                                    finalAmount =
                                        computedFinal < 0 ? 0 : computedFinal;
                                    promoMessage =
                                        data is Map && data['message'] != null
                                            ? data['message'].toString()
                                            : 'Code promo valide.';
                                  });
                                } on DioException catch (e) {
                                  final message = e.response?.data?['message']
                                          ?.toString() ??
                                      'Code promo invalide.';
                                  setSheetState(() {
                                    promoValidated = false;
                                    discountAmount = 0;
                                    finalAmount = price;
                                    promoMessage = message;
                                  });
                                } catch (_) {
                                  setSheetState(() {
                                    promoValidated = false;
                                    discountAmount = 0;
                                    finalAmount = price;
                                    promoMessage =
                                        'Impossible de vérifier le code promo.';
                                  });
                                } finally {
                                  setSheetState(() {
                                    isVerifyingPromo = false;
                                  });
                                }
                              },
                        icon: isVerifyingPromo
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.verified),
                        label: const Text('Vérifier le code promo'),
                      ),
                      if (promoMessage != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          promoMessage!,
                          style: TextStyle(
                            color: promoValidated ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: DEMSpacing.md),
                      const Text(
                        'Mode de paiement',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: DEMSpacing.sm),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Wave'),
                            selected: selectedMethod == 'wave',
                            onSelected: (_) => setSheetState(() {
                              selectedMethod = 'wave';
                            }),
                          ),
                          ChoiceChip(
                            label: const Text('Orange Money'),
                            selected: selectedMethod == 'orange_money',
                            onSelected: (_) => setSheetState(() {
                              selectedMethod = 'orange_money';
                            }),
                          ),
                          ChoiceChip(
                            label: const Text('Yas'),
                            selected: selectedMethod == 'yas',
                            onSelected: (_) => setSheetState(() {
                              selectedMethod = 'yas';
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: DEMSpacing.lg),
                      ElevatedButton(
                        onPressed: () async {
                          final storage = getIt<SecureStorageService>();
                          final user = await storage.getUser();
                          final phone = user?['phone']?.toString();

                          if (!sheetContext.mounted) return;
                          Navigator.pop(sheetContext);

                          context.read<PassBloc>().add(
                                ActivatePassEvent(
                                  paymentMethod: selectedMethod,
                                  passType: passType,
                                  phoneNumber: phone,
                                  promoCode: promoController.text.trim().isEmpty
                                      ? null
                                      : promoController.text.trim(),
                                  clientRequestId:
                                      'driver-${DateTime.now().millisecondsSinceEpoch}',
                                ),
                              );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DEMColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: DEMSpacing.md),
                        ),
                        child:
                            Text('Finaliser le paiement ($finalAmount FCFA)'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      promoController.dispose();
    });
  }
}
