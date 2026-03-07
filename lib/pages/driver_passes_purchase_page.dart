import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/service_locator.dart';
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
            // Rediriger vers la page livreur après achat
            Future.delayed(const Duration(seconds: 2), () {
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/livreurHome');
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
          if (state is PassLoading) {
            return const Center(child: CircularProgressIndicator());
          }

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
                    onPressed: () =>
                        context.read<PassBloc>().add(const LoadPassStateEvent()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          // Pour l'instant, affichons une liste de pass fictive en attendant l'API
          return _buildPassList(context);
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
    final passId = pass['id'] ?? pass['_id'] ?? '';
    final name = pass['name'] ?? 'Pass';
    final duration = pass['durationDays'] ?? 1;
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
                  _showPurchaseConfirmation(context, passId, name, price);
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

  void _showPurchaseConfirmation(
    BuildContext context,
    String passId,
    String passName,
    int price,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmer l\'achat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vous êtes sur le point d\'acheter:'),
            const SizedBox(height: 12),
            Text(
              passName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prix: $price FCFA',
              style: TextStyle(
                color: DEMColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Pour l'instant, juste afficher un message de succès
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Achat en cours...'),
                  backgroundColor: Colors.green,
                ),
              );
              // TODO: Intégrer avec l'API d'achat réelle
              context.read<PassBloc>().add(
                    ActivatePassEvent(
                      paymentMethod: 'WAVE',
                      passType: passId,
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DEMColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
