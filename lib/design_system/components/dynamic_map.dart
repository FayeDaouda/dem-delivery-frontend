import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../tokens/colors.dart';
import 'map_background.dart';

class DynamicMap extends StatefulWidget {
  final bool showUserLocation;
  final Function(Position)? onLocationUpdated;
  final Set<Marker>? customMarkers;
  final Function(GoogleMapController)? onMapCreated;

  const DynamicMap({
    super.key,
    this.showUserLocation = true,
    this.onLocationUpdated,
    this.customMarkers,
    this.onMapCreated,
  });

  @override
  State<DynamicMap> createState() => _DynamicMapState();
}

class _DynamicMapState extends State<DynamicMap> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  bool _hasError = false;
  String? _errorMessage;
  Set<Marker> _markers = {};
  CameraPosition? _initialPosition;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    debugPrint('🗺️ DynamicMap: Initialisation démarrée');
    try {
      // Vérifier et demander les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('🗺️ Permission status: $permission');
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('🗺️ Permission après demande: $permission');
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Permission refusée définitivement');
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Permission localisation refusée';
            _isLoadingLocation = false;
          });
        }
        return;
      }

      // Obtenir la position actuelle avec timeout
      debugPrint('📍 Récupération position GPS...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏱️ Timeout localisation');
          throw Exception('Timeout: localisation trop longue');
        },
      );

      debugPrint(
          '✅ Position obtenue: ${position.latitude}, ${position.longitude}');

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _initialPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15.5,
          );
          _isLoadingLocation = false;
          _updateMarkers();
        });
        debugPrint('🗺️ État mis à jour, carte prête à s\'afficher');
      }

      widget.onLocationUpdated?.call(position);

      // Écouter les changements de position en temps réel
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _updateMarkers();
          });
          widget.onLocationUpdated?.call(position);
        }
      });
    } catch (e) {
      debugPrint('❌ Erreur initialisation map: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _updateMarkers() {
    if (_currentPosition == null) return;

    final userMarker = Marker(
      markerId: const MarkerId('user_location'),
      position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      infoWindow: const InfoWindow(title: '📍 Votre position'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );

    setState(() {
      _markers = {userMarker, ...?widget.customMarkers};
    });
  }

  Future<void> _goToCurrentLocation() async {
    if (_currentPosition == null || _mapController == null) return;

    final cameraPosition = CameraPosition(
      target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      zoom: 15.5,
    );

    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(cameraPosition),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        '🗺️ DynamicMap build: _hasError=$_hasError, _isLoadingLocation=$_isLoadingLocation, _initialPosition=${_initialPosition != null}');

    // Fallback vers MapBackground si erreur ou pas de Google Play Services
    if (_hasError || (_isLoadingLocation && _errorMessage != null)) {
      debugPrint('🗺️ Fallback vers MapBackground: $_errorMessage');
      return const MapBackground();
    }

    if (_isLoadingLocation || _initialPosition == null) {
      debugPrint('🗺️ Affichage du loader...');
      return Container(
        color: DEMColors.gradientDark1,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  DEMColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Chargement de la carte...',
                style: TextStyle(color: DEMColors.gray300),
              ),
            ],
          ),
        ),
      );
    }

    debugPrint(
        '🗺️ Rendu GoogleMap avec position: ${_initialPosition!.target}');

    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (controller) {
            _mapController = controller;
            widget.onMapCreated?.call(controller); // Exposer le controller
            // Appliquer le style sombre
            try {
              _mapController!.setMapStyle(_getDarkMapStyle());
            } catch (e) {
              debugPrint('⚠️ Erreur application style map: $e');
              // Si le style échoue, utiliser fallback
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _errorMessage = 'Google Maps non disponible';
                });
              }
            }
          },
          initialCameraPosition: _initialPosition!,
          markers: _markers,
          myLocationEnabled: true, // Activer le point bleu natif
          myLocationButtonEnabled: false, // On gère notre propre bouton
          zoomControlsEnabled: false, // On gère nos propres boutons
          compassEnabled: false, // Désactiver la boussole pour optimisation
          mapToolbarEnabled: false,
          trafficEnabled: false,
          liteModeEnabled: false, // Mode lite pour bas de gamme si besoin
        ),
        // Bouton pour aller à la position actuelle
        Positioned(
          bottom: 100,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: _goToCurrentLocation,
            backgroundColor: DEMColors.primary,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ),
      ],
    );
  }

  String _getDarkMapStyle() {
    return '''
    [
      {
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#1a1a2e"
          }
        ]
      },
      {
        "elementType": "labels.icon",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#212121"
          }
        ]
      },
      {
        "featureType": "administrative",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "featureType": "administrative.country",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#9e9e9e"
          }
        ]
      },
      {
        "featureType": "administrative.land_parcel",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "featureType": "administrative.locality",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#bdbdbd"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#181818"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#616161"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "geometry.fill",
        "stylers": [
          {
            "color": "#2c2c2c"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#8a8a8a"
          }
        ]
      },
      {
        "featureType": "road.arterial",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#373737"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#3c3c3c"
          }
        ]
      },
      {
        "featureType": "road.highway.controlled_access",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#4e4e4e"
          }
        ]
      },
      {
        "featureType": "road.local",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#616161"
          }
        ]
      },
      {
        "featureType": "transit",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#0c1428"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#3d3d3d"
          }
        ]
      }
    ]
    ''';
  }
}
