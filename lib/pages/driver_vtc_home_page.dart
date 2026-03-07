import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/di/service_locator.dart';
import '../core/storage/secure_storage_service.dart';
import '../design_system/index.dart';

/// Page d'accueil pour les chauffeurs VTC
/// Affichée lorsque role=DRIVER et driverType=VTC
class DriverVtcHomePage extends StatelessWidget {
  final String? driverName;
  final String? driverId;

  const DriverVtcHomePage({
    super.key,
    this.driverName,
    this.driverId,
  });

  @override
  Widget build(BuildContext context) {
    return _DriverVtcHomeContent(
      driverName: driverName,
      driverId: driverId,
    );
  }
}

class _DriverVtcHomeContent extends StatefulWidget {
  final String? driverName;
  final String? driverId;

  const _DriverVtcHomeContent({
    required this.driverName,
    required this.driverId,
  });

  @override
  State<_DriverVtcHomeContent> createState() => _DriverVtcHomeContentState();
}

class _DriverVtcHomeContentState extends State<_DriverVtcHomeContent> {
  final SecureStorageService _storage = getIt<SecureStorageService>();

  String _driverName = 'Chauffeur VTC';
  GoogleMapController? _mapController;
  bool _isOnline = false;
  Position? _currentPosition;
  int _dailyEarnings = 0;
  int _todayTrips = 0;
  double _rating = 4.8;

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(14.6937, -17.4441), // Dakar
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _initDriverContext();
  }

  Future<void> _initDriverContext() async {
    final user = await _storage.getUser();
    final name = widget.driverName ?? user?['name'];
    setState(() {
      _driverName = name ?? 'Chauffeur VTC';
    });
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    } catch (e) {
      print('❌ Erreur localisation: $e');
    }
  }

  void _toggleOnlineStatus() {
    setState(() {
      _isOnline = !_isOnline;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isOnline ? '✅ Vous êtes en ligne' : '⏸️ Vous êtes hors ligne',
        ),
        backgroundColor: _isOnline ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Carte Google Maps
          GoogleMap(
            initialCameraPosition: _defaultPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_currentPosition != null) {
                controller.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                  ),
                );
              }
            },
          ),

          // Header flottant
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildFloatingHeader(),
          ),

          // Bouton toggle online/offline
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: _buildOnlineToggleButton(),
          ),

          // Panneau des statistiques (si en ligne)
          if (_isOnline)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: _buildStatsPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingHeader() {
    return Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: DEMSpacing.md,
        vertical: DEMSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DEMSpacing.sm),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.drive_eta,
            color: DEMColors.primary,
            size: 28,
          ),
          const SizedBox(width: DEMSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _driverName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Mon Profil',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsPanel() {
    return Container(
      padding: const EdgeInsets.all(DEMSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DEMSpacing.sm),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.monetization_on,
            label: 'Gains du jour',
            value: '$_dailyEarnings FCFA',
            color: Colors.green,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          _buildStatItem(
            icon: Icons.drive_eta,
            label: 'Courses',
            value: '$_todayTrips',
            color: DEMColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineToggleButton() {
    return ElevatedButton(
      onPressed: _toggleOnlineStatus,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isOnline ? Colors.orange : Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DEMSpacing.sm),
        ),
        elevation: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_isOnline ? Icons.pause_circle : Icons.play_circle),
          const SizedBox(width: 8),
          Text(
            _isOnline ? 'Se mettre hors ligne' : 'Se mettre en ligne',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
