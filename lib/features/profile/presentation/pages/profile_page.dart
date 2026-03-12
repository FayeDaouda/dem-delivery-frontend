import 'package:delivery_express_mobility_frontend/core/di/service_locator.dart';
import 'package:delivery_express_mobility_frontend/core/storage/secure_storage_service.dart';
import 'package:delivery_express_mobility_frontend/design_system/index.dart';
import 'package:delivery_express_mobility_frontend/core/config/feature_flags.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_express_mobility_frontend/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Page de profil utilisateur avec informations et déconnexion
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SecureStorageService _storage = getIt<SecureStorageService>();
  final Dio _dio = getIt<Dio>();

  String? _fullName;
  String? _phone;
  String? _role;
  String? _driverType;
  String? _profilePhotoUrl;
  double _rating = 0.0;
  int _totalDeliveries = 0;
  int _totalEarnings = 0;
  List<Map<String, dynamic>> _deliveryHistory = [];
  bool _isLoading = true;
  bool _isLoadingHistory = false;
  bool _isOnline = false;
  bool _isUpdatingOnline = false;
  bool _mapMitigationsEnabled = FeatureFlags.mapMitigations;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = await _storage.getUser();
      final role = await _storage.getRole();
      final driverType = await _storage.getDriverType();

      // Charger préférence map mitigations
      try {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.containsKey('map_mitigations_enabled')) {
          _mapMitigationsEnabled = prefs.getBool('map_mitigations_enabled')!;
          FeatureFlags.mapMitigations = _mapMitigationsEnabled;
        }
      } catch (_) {
        // ignore
      }

      if (mounted) {
        setState(() {
          _fullName = user?['fullName'] ?? user?['name'];
          _phone = user?['phone'];
          _role = role;
          _driverType = driverType;
          _profilePhotoUrl =
              user?['profilePhoto']?.toString() ?? user?['avatar']?.toString();
          _isOnline = _toBool(user?['isOnline']);
          _isLoading = false;
        });
      }

      // Charger les données additionnelles depuis l'API
      await _loadProfileFromApi();
      await _loadDeliveryHistory();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadProfileFromApi() async {
    try {
      final response = await _dio.get('/users/me');
      final data = response.data;

      if (data is Map) {
        final userData = data['data'] ?? data;
        if (userData is Map) {
          if (mounted) {
            setState(() {
              _fullName = userData['fullName']?.toString() ??
                  userData['name']?.toString() ??
                  _fullName;
              _phone = userData['phone']?.toString() ?? _phone;
              _profilePhotoUrl = userData['profilePhoto']?.toString() ??
                  userData['avatar']?.toString() ??
                  userData['photoUrl']?.toString() ??
                  _profilePhotoUrl;
              _isOnline = _toBool(userData['isOnline']);
              _rating =
                  _toDouble(userData['rating'] ?? userData['averageRating']);
              _totalDeliveries = _toInt(
                  userData['totalDeliveries'] ?? userData['deliveriesCount']);
              _totalEarnings =
                  _toInt(userData['totalEarnings'] ?? userData['totalGain']);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Erreur chargement profil: $e');
    }
  }

  Future<void> _loadDeliveryHistory() async {
    if (_role != 'DRIVER' && _role != 'driver') return;

    setState(() => _isLoadingHistory = true);

    try {
      final response = await _dio.get('/deliveries/history');
      final data = response.data;

      if (data is Map && data['data'] is List) {
        final List deliveries = data['data'];
        if (mounted) {
          setState(() {
            _deliveryHistory = deliveries.cast<Map<String, dynamic>>();
            _isLoadingHistory = false;
          });
        }
      } else if (data is List) {
        if (mounted) {
          setState(() {
            _deliveryHistory = data.cast<Map<String, dynamic>>();
            _isLoadingHistory = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingHistory = false);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Erreur chargement historique: $e');
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  Future<void> _toggleOnlineStatus(bool value) async {
    if (_isUpdatingOnline) return;
    setState(() => _isUpdatingOnline = true);

    try {
      await _dio.patch('/users/me', data: {'isOnline': value});
      if (!mounted) return;
      setState(() => _isOnline = value);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de changer le statut: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingOnline = false);
    }
  }

  Future<void> _editProfile() async {
    final controller = TextEditingController(text: _fullName ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Modifier le profil'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nom complet'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = controller.text.trim();
              if (value.isEmpty) return;

              try {
                await _dio.patch('/users/me', data: {'fullName': value});
                if (!mounted) return;
                setState(() => _fullName = value);
                Navigator.pop(dialogContext);
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Échec de mise à jour du profil')),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fermer dialog
              context.read<AuthBloc>().add(const AuthLogoutEvent());
              Navigator.pushReplacementNamed(context, '/splash');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DEMColors.error,
              foregroundColor: DEMColors.white,
            ),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DEMColors.gray50,
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: DEMColors.primary,
        foregroundColor: DEMColors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(DEMSpacing.lg),
              child: Column(
                children: [
                  // Avatar & Nom
                  _buildProfileHeader(),

                  const SizedBox(height: DEMSpacing.lg),

                  if (_role == 'DRIVER' || _role == 'driver')
                    _buildDriverProCard(),

                  if (_role == 'DRIVER' || _role == 'driver')
                    const SizedBox(height: DEMSpacing.lg),

                  // Statistiques (pour livreurs)
                  if (_role == 'DRIVER' || _role == 'driver') _buildStatsCard(),

                  const SizedBox(height: DEMSpacing.lg),

                  // Informations
                  _buildInfoCard(),

                  const SizedBox(height: DEMSpacing.lg),
                  _buildDebugSettingsCard(),

                  const SizedBox(height: DEMSpacing.lg),

                  // Historique des livraisons (pour livreurs)
                  if (_role == 'DRIVER' || _role == 'driver')
                    _buildDeliveryHistoryCard(),

                  const SizedBox(height: DEMSpacing.lg),

                  // Bouton déconnexion
                  _buildLogoutButton(),

                  const SizedBox(height: DEMSpacing.xxl),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(DEMSpacing.xl),
      decoration: BoxDecoration(
        color: DEMColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: DEMColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar circulaire
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  DEMColors.primary,
                  DEMColors.primaryLight,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ClipOval(
              child: _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
                  ? Image.network(
                      _profilePhotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          _getInitials(),
                          style: const TextStyle(
                            color: DEMColors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        _getInitials(),
                        style: const TextStyle(
                          color: DEMColors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ),

          const SizedBox(height: DEMSpacing.md),

          // Nom
          Text(
            _fullName ?? 'Utilisateur',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: DEMColors.gray900,
            ),
          ),

          const SizedBox(height: DEMSpacing.xs),

          // Badge rôle
          _buildRoleBadge(),

          // Note moyenne (pour livreurs)
          if ((_role == 'DRIVER' || _role == 'driver') && _rating > 0) ...[
            const SizedBox(height: DEMSpacing.md),
            _buildRatingDisplay(),
          ],
        ],
      ),
    );
  }

  Widget _buildDriverProCard() {
    return Container(
      padding: const EdgeInsets.all(DEMSpacing.lg),
      decoration: BoxDecoration(
        color: DEMColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: DEMColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Espace Livreur PRO',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: DEMColors.gray900,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _editProfile,
                icon: const Icon(Icons.edit),
                label: const Text('Edit profile'),
              ),
            ],
          ),
          const SizedBox(height: DEMSpacing.md),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Statut livreur (online/offline)'),
            subtitle: Text(_isOnline ? 'En ligne' : 'Hors ligne'),
            value: _isOnline,
            onChanged: _isUpdatingOnline ? null : _toggleOnlineStatus,
          ),
          const SizedBox(height: DEMSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DEMSpacing.md),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.green),
                const SizedBox(width: DEMSpacing.sm),
                Text(
                  'Wallet gains: $_totalEarnings FCFA',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DEMSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/driver/history'),
                  icon: const Icon(Icons.history),
                  label: const Text('Historique'),
                ),
              ),
              const SizedBox(width: DEMSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/driver/dashboard/pro'),
                  icon: const Icon(Icons.dashboard_customize),
                  label: const Text('Dashboard'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.star,
          color: Colors.amber,
          size: 24,
        ),
        const SizedBox(width: DEMSpacing.xs),
        Text(
          _rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: DEMColors.gray900,
          ),
        ),
        const Text(
          ' / 5.0',
          style: TextStyle(
            fontSize: 14,
            color: DEMColors.gray600,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge() {
    String roleText = 'Utilisateur';
    Color roleColor = DEMColors.gray500;

    if (_role == 'DRIVER' || _role == 'driver') {
      roleText = 'Livreur';
      roleColor = DEMColors.primary;

      if (_driverType != null) {
        roleText += ' ${_driverType!.toUpperCase()}';
      }
    } else if (_role == 'CLIENT' || _role == 'client') {
      roleText = 'Client';
      roleColor = DEMColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DEMSpacing.md,
        vertical: DEMSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: roleColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: roleColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        roleText,
        style: TextStyle(
          color: roleColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(DEMSpacing.lg),
      decoration: BoxDecoration(
        color: DEMColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: DEMColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistiques',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: DEMColors.gray900,
            ),
          ),
          const SizedBox(height: DEMSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.local_shipping_rounded,
                label: 'Livraisons',
                value: _totalDeliveries.toString(),
                color: DEMColors.primary,
              ),
              Container(
                height: 50,
                width: 1,
                color: DEMColors.gray300,
              ),
              _buildStatItem(
                icon: Icons.payments_rounded,
                label: 'Gains totaux',
                value: '$_totalEarnings F',
                color: Colors.green,
              ),
            ],
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
        Container(
          padding: const EdgeInsets.all(DEMSpacing.md),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(height: DEMSpacing.sm),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: DEMColors.gray600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(DEMSpacing.lg),
      decoration: BoxDecoration(
        color: DEMColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: DEMColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: DEMColors.gray900,
            ),
          ),
          const SizedBox(height: DEMSpacing.md),
          const Divider(),
          const SizedBox(height: DEMSpacing.sm),

          // Téléphone
          _buildInfoRow(
            icon: Icons.phone_rounded,
            label: 'Téléphone',
            value: _phone ?? 'Non renseigné',
          ),

          const SizedBox(height: DEMSpacing.md),

          // Rôle
          _buildInfoRow(
            icon: Icons.badge_rounded,
            label: 'Rôle',
            value: _getRoleDisplay(),
          ),

          if (_driverType != null) ...[
            const SizedBox(height: DEMSpacing.md),
            _buildInfoRow(
              icon: Icons.directions_bike_rounded,
              label: 'Type de véhicule',
              value: _driverType!.toUpperCase(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(DEMSpacing.sm),
          decoration: BoxDecoration(
            color: DEMColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: DEMColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: DEMSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: DEMColors.gray600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DEMColors.gray900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(DEMSpacing.lg),
      decoration: BoxDecoration(
        color: DEMColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: DEMColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Historique des livraisons',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DEMColors.gray900,
                ),
              ),
              if (_isLoadingHistory)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: DEMSpacing.md),
          const Divider(),
          if (_deliveryHistory.isEmpty && !_isLoadingHistory) ...[
            const SizedBox(height: DEMSpacing.lg),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_rounded,
                    size: 48,
                    color: DEMColors.gray400,
                  ),
                  const SizedBox(height: DEMSpacing.sm),
                  Text(
                    'Aucune livraison pour le moment',
                    style: TextStyle(
                      color: DEMColors.gray600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DEMSpacing.lg),
          ] else ...[
            const SizedBox(height: DEMSpacing.sm),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount:
                  _deliveryHistory.length > 5 ? 5 : _deliveryHistory.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: DEMSpacing.lg),
              itemBuilder: (context, index) {
                final delivery = _deliveryHistory[index];
                return _buildDeliveryHistoryItem(delivery);
              },
            ),
            if (_deliveryHistory.length > 5) ...[
              const SizedBox(height: DEMSpacing.md),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/driver/history');
                  },
                  child: const Text('Voir tout l\'historique'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDebugSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(DEMSpacing.lg),
      decoration: BoxDecoration(
        color: DEMColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: DEMColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paramètres avancés',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: DEMColors.gray900,
            ),
          ),
          const SizedBox(height: DEMSpacing.md),
          const Divider(),
          const SizedBox(height: DEMSpacing.sm),
          SwitchListTile(
            title: const Text('Mitigations Google Maps'),
            subtitle: const Text(
                'Débounce/try-catch et throttling pour améliorer la stabilité des cartes.'),
            value: _mapMitigationsEnabled,
            onChanged: (v) async {
              setState(() => _mapMitigationsEnabled = v);
              FeatureFlags.mapMitigations = v;
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('map_mitigations_enabled', v);
              } catch (_) {
                // ignore
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryHistoryItem(Map<String, dynamic> delivery) {
    final status = delivery['status']?.toString() ?? 'UNKNOWN';
    final gain =
        _toInt(delivery['gain'] ?? delivery['amount'] ?? delivery['price']);
    final date =
        delivery['createdAt']?.toString() ?? delivery['date']?.toString();
    final pickupAddress =
        delivery['pickupAddress']?.toString() ?? 'Non spécifié';
    final deliveryAddress =
        delivery['deliveryAddress']?.toString() ?? 'Non spécifié';

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'DELIVERED':
        statusColor = Colors.green;
        statusLabel = 'Livrée';
        statusIcon = Icons.check_circle;
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        statusLabel = 'Annulée';
        statusIcon = Icons.cancel;
        break;
      case 'IN_PROGRESS':
      case 'PICKED_UP':
        statusColor = Colors.orange;
        statusLabel = 'En cours';
        statusIcon = Icons.local_shipping;
        break;
      default:
        statusColor = DEMColors.gray600;
        statusLabel = status;
        statusIcon = Icons.info;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Statut et gain
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: DEMSpacing.xs),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Text(
              '$gain FCFA',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: DEMSpacing.xs),

        // Adresses
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on, size: 16, color: DEMColors.gray600),
            const SizedBox(width: DEMSpacing.xs),
            Expanded(
              child: Text(
                pickupAddress,
                style: const TextStyle(
                  fontSize: 13,
                  color: DEMColors.gray700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.flag, size: 16, color: DEMColors.gray600),
            const SizedBox(width: DEMSpacing.xs),
            Expanded(
              child: Text(
                deliveryAddress,
                style: const TextStyle(
                  fontSize: 13,
                  color: DEMColors.gray700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // Date
        if (date != null && date.isNotEmpty) ...[
          const SizedBox(height: DEMSpacing.xs),
          Text(
            _formatDate(date),
            style: const TextStyle(
              fontSize: 12,
              color: DEMColors.gray500,
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Aujourd\'hui à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Hier à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays} jours';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Se déconnecter'),
        style: ElevatedButton.styleFrom(
          backgroundColor: DEMColors.error,
          foregroundColor: DEMColors.white,
          padding: const EdgeInsets.symmetric(vertical: DEMSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  String _getInitials() {
    if (_fullName == null || _fullName!.isEmpty) return '?';

    final parts = _fullName!.trim().split(' ');
    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  String _getRoleDisplay() {
    if (_role == null) return 'Non défini';

    switch (_role!.toUpperCase()) {
      case 'DRIVER':
        return 'Livreur';
      case 'CLIENT':
        return 'Client';
      default:
        return _role!;
    }
  }
}
