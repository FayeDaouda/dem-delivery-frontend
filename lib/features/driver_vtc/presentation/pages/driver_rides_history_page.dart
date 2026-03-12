import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/delivery_formatters.dart';
import '../../../../design_system/index.dart';
import '../../../../features/deliveries/domain/repositories/deliveries_repository.dart';
import '../../services/driver_location_service.dart';
import '../../services/driver_rides_service.dart';
import '../../services/driver_stats_service.dart';
import '../bloc/driver_bloc.dart';
import '../bloc/driver_event.dart';
import '../bloc/driver_state.dart';
import '../widgets/driver_rides_tile.dart';

class DriverRidesHistoryPage extends StatefulWidget {
  const DriverRidesHistoryPage({super.key});

  @override
  State<DriverRidesHistoryPage> createState() => _DriverRidesHistoryPageState();
}

class _DriverRidesHistoryPageState extends State<DriverRidesHistoryPage> {
  late final DriverBloc _bloc;
  late final DriverRidesService _ridesService;

  final List<String> _filters = const [
    'TOUS',
    'COMPLETED',
    'IN_PROGRESS',
    'CANCELLED',
  ];

  String _getFilterLabel(String filter) {
    if (filter == 'TOUS') return 'Tous';
    return DeliveryFormatters.formatStatus(filter);
  }

  String _selectedFilter = 'TOUS';
  List<Map<String, dynamic>> _allRides = [];

  static const CameraPosition _dakar = CameraPosition(
    target: LatLng(14.6937, -17.4441),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _ridesService = DriverRidesService(
      dio: getIt(),
      deliveriesRepository: getIt<DeliveriesRepository>(),
    );
    _bloc = DriverBloc(
      locationService: DriverLocationService(dio: getIt()),
      ridesService: _ridesService,
      statsService: DriverStatsService(dio: getIt()),
    );
    _bloc.add(const LoadRidesEvent());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Set<Marker> _buildMarkers(List<Map<String, dynamic>> rides) {
    final markers = <Marker>{};
    for (var i = 0; i < rides.length; i++) {
      final location = _ridesService.extractPickupLocation(rides[i]);
      if (location == null) continue;
      markers.add(
        Marker(
          markerId: MarkerId('r_$i'),
          position: location,
          infoWindow: InfoWindow(
            title: rides[i]['status']?.toString() ?? 'Course',
            snippet: '${rides[i]['price'] ?? rides[i]['amount'] ?? 0} FCFA',
          ),
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DEMColors.gray50,
      appBar: AppBar(
        title: const Text('Historique des courses'),
        backgroundColor: DEMColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<DriverBloc, DriverState>(
        bloc: _bloc,
        builder: (context, state) {
          if (state is DriverLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DriverRidesLoaded) {
            _allRides = state.rides;
          }

          final filteredRides =
              _ridesService.filterByStatus(_allRides, _selectedFilter);

          return Column(
            children: [
              SizedBox(
                height: 220,
                child: GoogleMap(
                  initialCameraPosition: _dakar,
                  markers: _buildMarkers(filteredRides),
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _filters
                      .map(
                        (f) => ChoiceChip(
                          label: Text(_getFilterLabel(f)),
                          selected: _selectedFilter == f,
                          onSelected: (_) =>
                              setState(() => _selectedFilter = f),
                        ),
                      )
                      .toList(),
                ),
              ),
              Expanded(
                child: filteredRides.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.inbox_rounded,
                              size: 48,
                              color: DEMColors.gray400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Aucune course',
                              style: DEMTypography.body1.copyWith(
                                color: DEMColors.gray600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filteredRides.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final ride = filteredRides[i];
                          return DriverRidesTile(
                            ride: ride,
                            index: i,
                            onTap: () => _showRideDetail(ride),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRideDetail(Map<String, dynamic> ride) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Détail de la course',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  DeliveryFormatters.getStatusIcon(ride['status'] ?? ''),
                  color:
                      DeliveryFormatters.getStatusColor(ride['status'] ?? ''),
                ),
                const SizedBox(width: 8),
                Text(
                  DeliveryFormatters.formatStatus(ride['status'] ?? ''),
                  style: TextStyle(
                    color:
                        DeliveryFormatters.getStatusColor(ride['status'] ?? ''),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tarif: ${DeliveryFormatters.formatAmount((ride['gain'] ?? ride['amount'] ?? ride['price'] ?? 0).toDouble())}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Point de départ: ${ride['pickupAddress'] ?? 'Non spécifié'}',
            ),
            Text(
              'Point de destination: ${ride['deliveryAddress'] ?? 'Non spécifié'}',
            ),
          ],
        ),
      ),
    );
  }
}
