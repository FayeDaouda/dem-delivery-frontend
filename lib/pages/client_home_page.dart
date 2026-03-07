import 'package:flutter/material.dart';

import '../core/di/service_locator.dart';
import '../core/storage/secure_storage_service.dart';

class ClientHomePage extends StatelessWidget {
  final String? userName;

  const ClientHomePage({super.key, this.userName});

  @override
  Widget build(BuildContext context) {
    return _ClientHomePageContent(userName: userName);
  }
}

class _ClientHomePageContent extends StatelessWidget {
  final String? userName;

  const _ClientHomePageContent({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bonjour, ${userName ?? "Client"}!'),
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(height: 40),
            Container(
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
                    value: userName ?? 'Non défini',
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
                        value: snapshot.data != null
                            ? 'Authentifié ✓'
                            : 'Non connecté',
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
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
