import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/service_locator.dart';
import '../core/storage/secure_storage_service.dart';
import '../design_system/index.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';

/// Page de profil utilisateur avec informations et déconnexion
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SecureStorageService _storage = getIt<SecureStorageService>();

  String? _fullName;
  String? _phone;
  String? _role;
  String? _driverType;
  bool _isLoading = true;

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

      if (mounted) {
        setState(() {
          _fullName = user?['fullName'] ?? user?['name'];
          _phone = user?['phone'];
          _role = role;
          _driverType = driverType;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

                  const SizedBox(height: DEMSpacing.xl),

                  // Informations
                  _buildInfoCard(),

                  const SizedBox(height: DEMSpacing.xl),

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
            child: Center(
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
        ],
      ),
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
