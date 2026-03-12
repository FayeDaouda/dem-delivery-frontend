import 'package:delivery_express_mobility_frontend/features/deliveries/domain/repositories/deliveries_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../design_system/index.dart';
import '../../services/driver_location_service.dart';
import '../../services/driver_rides_service.dart';
import '../../services/driver_stats_service.dart';
import '../bloc/driver_bloc.dart';
import '../bloc/driver_event.dart';
import '../bloc/driver_state.dart';
import '../widgets/driver_heatmap_section.dart';
import '../widgets/driver_stats_card.dart';

class DriverDashboardProPage extends StatefulWidget {
  const DriverDashboardProPage({super.key});

  @override
  State<DriverDashboardProPage> createState() => _DriverDashboardProPageState();
}

class _DriverDashboardProPageState extends State<DriverDashboardProPage> {
  late final DriverBloc _bloc;

  static const CameraPosition _dakar = CameraPosition(
    target: LatLng(14.6937, -17.4441),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _bloc = DriverBloc(
      locationService: DriverLocationService(dio: getIt()),
      ridesService: DriverRidesService(
        dio: getIt(),
        deliveriesRepository: getIt<DeliveriesRepository>(),
      ),
      statsService: DriverStatsService(dio: getIt()),
    );
    _bloc.add(const LoadDashboardDataEvent());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DEMColors.gray50,
      appBar: AppBar(
        title: const Text('Dashboard Chauffeur VTC'),
        backgroundColor: DEMColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<DriverBloc, DriverState>(
        bloc: _bloc,
        builder: (context, state) {
          if (state is DriverLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DriverDashboardLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // KPI Cards
                  Row(
                    children: [
                      Expanded(
                        child: DriverStatsCard(
                          title: 'Revenus du jour',
                          value: '${state.todayEarnings} FCFA',
                          icon: Icons.payments,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DriverStatsCard(
                          title: 'Courses',
                          value: '${state.todayDeliveries}',
                          icon: Icons.directions_car,
                          color: DEMColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Online Toggle
                  Card(
                    child: SwitchListTile(
                      title: const Text('Statut chauffeur'),
                      subtitle:
                          Text(state.isOnline ? 'En ligne' : 'Hors ligne'),
                      value: state.isOnline,
                      onChanged: (value) {
                        _bloc.add(ToggleOnlineStatusEvent(value));
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Heatmap
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: DriverHeatmapSection(
                        circles: state.heatmap,
                        initialCameraPosition: _dakar,
                        title: 'Carte de chaleur des courses',
                        height: 260,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is DriverError) {
            return Center(
              child: Text('Erreur: ${state.message}'),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
