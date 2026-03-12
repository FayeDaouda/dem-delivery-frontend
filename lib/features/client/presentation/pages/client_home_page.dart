import 'package:delivery_express_mobility_frontend/core/di/service_locator.dart';
import 'package:delivery_express_mobility_frontend/core/storage/secure_storage_service.dart';
import 'package:delivery_express_mobility_frontend/core/utils/delivery_formatters.dart';
import 'package:delivery_express_mobility_frontend/features/deliveries/domain/entities/delivery.dart';
import 'package:delivery_express_mobility_frontend/features/deliveries/presentation/bloc/deliveries_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClientHomePage extends StatelessWidget {
  final String? userName;

  const ClientHomePage({super.key, this.userName});

  @override
  Widget build(BuildContext context) {
    return _ClientHomePageContent(userName: userName);
  }
}

class _ClientHomePageContent extends StatefulWidget {
  final String? userName;

  const _ClientHomePageContent({required this.userName});

  @override
  State<_ClientHomePageContent> createState() => _ClientHomePageContentState();
}

class _ClientHomePageContentState extends State<_ClientHomePageContent> {
  final DeliveriesBloc _deliveriesBloc = getIt<DeliveriesBloc>();

  @override
  void initState() {
    super.initState();
    _deliveriesBloc.add(const FetchDeliveriesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DeliveriesBloc>.value(
      value: _deliveriesBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Bonjour, ${widget.userName ?? "Client"}!'),
          elevation: 0,
          backgroundColor: const Color(0xFF2196F3),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_circle),
              tooltip: 'Mon Profil',
              onPressed: () => Navigator.pushNamed(context, '/profile'),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            _deliveriesBloc.add(const FetchDeliveriesEvent());
          },
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Connexion réussie!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.green[600],
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildAccountInfoCard(context),
              const SizedBox(height: 24),
              _buildRecentDeliveriesCard(context),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.account_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Mon Profil',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            label: 'Utilisateur',
            value: widget.userName ?? 'Non défini',
          ),
          const SizedBox(height: 16),
          FutureBuilder<String?>(
            future: getIt<SecureStorageService>().getRole(),
            builder: (context, snapshot) {
              final role = snapshot.data ?? 'CLIENT';
              return _InfoRow(
                label: 'Rôle',
                value: role == 'CLIENT' ? 'Client' : 'Livreur',
              );
            },
          ),
          const SizedBox(height: 16),
          FutureBuilder<String?>(
            future: getIt<SecureStorageService>().getAccessToken(),
            builder: (context, snapshot) {
              return _InfoRow(
                label: 'Statut',
                value: snapshot.data != null ? 'Authentifié ✓' : 'Non connecté',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDeliveriesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: BlocBuilder<DeliveriesBloc, DeliveriesState>(
        builder: (context, state) {
          if (state is DeliveriesLoading || state is DeliveriesInitial) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (state is DeliveriesFailure) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mes livraisons récentes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Impossible de charger les livraisons.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
          }

          final deliveries =
              state is DeliveriesLoaded ? state.deliveries : <Delivery>[];
          final recent = deliveries.take(3).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mes livraisons récentes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              if (recent.isEmpty)
                Text(
                  'Aucune livraison pour le moment.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...recent.map(
                  (delivery) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      DeliveryFormatters.getStatusIcon(delivery.status),
                      color: DeliveryFormatters.getStatusColor(delivery.status),
                    ),
                    title: Text(delivery.deliveryAddress),
                    subtitle: Text(
                      DeliveryFormatters.formatStatus(delivery.status),
                      style: TextStyle(
                        color:
                            DeliveryFormatters.getStatusColor(delivery.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Text(
                      DeliveryFormatters.formatAmount(delivery.amount),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF2196F3),
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
