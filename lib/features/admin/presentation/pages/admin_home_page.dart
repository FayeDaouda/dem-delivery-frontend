import 'package:delivery_express_mobility_frontend/core/di/service_locator.dart';
import 'package:delivery_express_mobility_frontend/core/utils/delivery_formatters.dart';
import 'package:delivery_express_mobility_frontend/features/deliveries/domain/entities/delivery.dart';
import 'package:delivery_express_mobility_frontend/features/deliveries/presentation/bloc/deliveries_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
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
          title: const Text('Admin Dashboard'),
          actions: [
            IconButton(
              tooltip: 'Rafraîchir',
              onPressed: () =>
                  _deliveriesBloc.add(const FetchDeliveriesEvent()),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: BlocBuilder<DeliveriesBloc, DeliveriesState>(
          builder: (context, state) {
            if (state is DeliveriesLoading || state is DeliveriesInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DeliveriesFailure) {
              return Center(
                child: Text('Erreur chargement livraisons: ${state.message}'),
              );
            }

            final deliveries =
                state is DeliveriesLoaded ? state.deliveries : <Delivery>[];

            final pending = deliveries
                .where((d) => d.status.toUpperCase() == 'PENDING')
                .length;
            final inProgress = deliveries
                .where((d) => d.status.toUpperCase() == 'IN_PROGRESS')
                .length;
            final completed = deliveries
                .where((d) => d.status.toUpperCase() == 'COMPLETED')
                .length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatCard(
                      label: 'Total',
                      value: deliveries.length.toString(),
                      color: Colors.blue,
                    ),
                    _StatCard(
                      label: 'En attente',
                      value: pending.toString(),
                      color: Colors.orange,
                    ),
                    _StatCard(
                      label: 'En cours',
                      value: inProgress.toString(),
                      color: Colors.purple,
                    ),
                    _StatCard(
                      label: 'Terminées',
                      value: completed.toString(),
                      color: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Dernières livraisons',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 10),
                if (deliveries.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('Aucune livraison disponible'),
                    ),
                  )
                else
                  ...deliveries.take(10).map(
                        (delivery) => Card(
                          child: ListTile(
                            leading: Icon(
                              DeliveryFormatters.getStatusIcon(delivery.status),
                              color: DeliveryFormatters.getStatusColor(
                                  delivery.status),
                            ),
                            title: Text(delivery.deliveryAddress),
                            subtitle: Text(
                              'Départ: ${delivery.pickupAddress}\n${DeliveryFormatters.formatStatus(delivery.status)} • ${DeliveryFormatters.formatRelativeDate(delivery.createdAt)}',
                              style: TextStyle(
                                color: DeliveryFormatters.getStatusColor(
                                    delivery.status),
                              ),
                            ),
                            trailing: Text(
                              DeliveryFormatters.formatAmount(delivery.amount),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
