import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/di/service_locator.dart';
import '../core/storage/secure_storage_service.dart';
import '../core/widgets/app_dialog.dart';

class KycSubmissionPage extends StatefulWidget {
  const KycSubmissionPage({super.key});

  @override
  State<KycSubmissionPage> createState() => _KycSubmissionPageState();
}

class _KycSubmissionPageState extends State<KycSubmissionPage> {
  final Dio _dio = getIt<Dio>();
  final Dio _uploadDio = Dio();
  final SecureStorageService _storage = getIt<SecureStorageService>();

  final Map<String, TextEditingController> _pathControllers = {
    'drivingLicenseUrl': TextEditingController(),
    'drivingLicenseVersoUrl': TextEditingController(),
    'vehicleRegistrationUrl': TextEditingController(),
    'vehicleRegistrationVersoUrl': TextEditingController(),
    'motorcyclePhotoUrl': TextEditingController(),
    'selfieUrl': TextEditingController(),
  };

  final Map<String, String> _documentTypeByField = {
    'drivingLicenseUrl': 'permis',
    'drivingLicenseVersoUrl': 'permis_verso',
    'vehicleRegistrationUrl': 'carte_grise',
    'vehicleRegistrationVersoUrl': 'carte_grise_verso',
    'motorcyclePhotoUrl': 'moto',
    'selfieUrl': 'selfie',
  };

  final Map<String, String> _labels = {
    'drivingLicenseUrl': 'Permis (Recto)',
    'drivingLicenseVersoUrl': 'Permis (Verso)',
    'vehicleRegistrationUrl': 'Carte grise (Recto)',
    'vehicleRegistrationVersoUrl': 'Carte grise (Verso)',
    'motorcyclePhotoUrl': 'Photo moto',
    'selfieUrl': 'Selfie',
  };

  final Map<String, String?> _uploadedUrls = {
    'drivingLicenseUrl': null,
    'drivingLicenseVersoUrl': null,
    'vehicleRegistrationUrl': null,
    'vehicleRegistrationVersoUrl': null,
    'motorcyclePhotoUrl': null,
    'selfieUrl': null,
  };

  final Map<String, bool> _uploading = {
    'drivingLicenseUrl': false,
    'drivingLicenseVersoUrl': false,
    'vehicleRegistrationUrl': false,
    'vehicleRegistrationVersoUrl': false,
    'motorcyclePhotoUrl': false,
    'selfieUrl': false,
  };

  bool _submitting = false;

  @override
  void dispose() {
    for (final controller in _pathControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _uploadDocument(String fieldKey) async {
    final filePath = _pathControllers[fieldKey]!.text.trim();
    if (filePath.isEmpty) {
      AppDialog.showWarning(context, 'Veuillez saisir le chemin du fichier (${_labels[fieldKey]}).');
      return;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      if (!mounted) return;
      AppDialog.showError(context, 'Fichier introuvable: $filePath');
      return;
    }

    setState(() => _uploading[fieldKey] = true);

    try {
      final fileName = file.uri.pathSegments.isNotEmpty
          ? file.uri.pathSegments.last
          : '${DateTime.now().millisecondsSinceEpoch}.jpg';

      final getUrlResponse = await _dio.post(
        '/drivers/documents/get-upload-url',
        data: {
          'documentType': _documentTypeByField[fieldKey],
          'fileName': fileName,
        },
      );

      final data = (getUrlResponse.data is Map<String, dynamic>)
          ? (getUrlResponse.data as Map<String, dynamic>)
          : <String, dynamic>{};

      final uploadUrl = (data['uploadUrl'] ?? data['data']?['uploadUrl'])?.toString();
      final fileUrl = (data['fileUrl'] ?? data['data']?['fileUrl'])?.toString();

      if (uploadUrl == null || uploadUrl.isEmpty || fileUrl == null || fileUrl.isEmpty) {
        throw Exception('Réponse upload-url invalide');
      }

      final bytes = await file.readAsBytes();
      await _uploadDio.put(
        uploadUrl,
        data: bytes,
        options: Options(
          headers: {
            'Content-Type': 'image/jpeg',
          },
        ),
      );

      if (!mounted) return;
      setState(() {
        _uploadedUrls[fieldKey] = fileUrl;
      });

      AppDialog.showSuccess(context, '${_labels[fieldKey]} uploadé avec succès.');
    } on DioException catch (e) {
      if (!mounted) return;
      String message = 'Upload échoué pour ${_labels[fieldKey]}';
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final apiMessage = data['message'] ?? data['error'];
        if (apiMessage is String && apiMessage.isNotEmpty) {
          message = apiMessage;
        } else if (apiMessage is List && apiMessage.isNotEmpty) {
          message = apiMessage.join('\n');
        }
      }
      AppDialog.showError(context, message);
    } catch (e) {
      if (!mounted) return;
      AppDialog.showError(context, 'Erreur upload (${_labels[fieldKey]}): $e');
    } finally {
      if (mounted) {
        setState(() => _uploading[fieldKey] = false);
      }
    }
  }

  Future<void> _submitKyc() async {
    if (_submitting) return;

    final missing = _uploadedUrls.entries.where((entry) => entry.value == null || entry.value!.isEmpty).toList();
    if (missing.isNotEmpty) {
      AppDialog.showWarning(context, 'Veuillez uploader les 6 documents avant soumission.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final payload = <String, dynamic>{
        'drivingLicenseUrl': _uploadedUrls['drivingLicenseUrl'],
        'drivingLicenseVersoUrl': _uploadedUrls['drivingLicenseVersoUrl'],
        'vehicleRegistrationUrl': _uploadedUrls['vehicleRegistrationUrl'],
        'vehicleRegistrationVersoUrl': _uploadedUrls['vehicleRegistrationVersoUrl'],
        'motorcyclePhotoUrl': _uploadedUrls['motorcyclePhotoUrl'],
        'selfieUrl': _uploadedUrls['selfieUrl'],
      };

      final response = await _dio.post('/drivers/documents/submit', data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await _storage.saveDriverData(
          status: 'PENDING_VERIFICATION',
          kycStatus: 'PENDING',
        );

        if (!mounted) return;
        AppDialog.showSuccess(context, 'Documents soumis. Vérification en cours.');
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        AppDialog.showError(context, 'Soumission KYC échouée (${response.statusCode}).');
      }
    } on DioException catch (e) {
      if (!mounted) return;
      String message = 'Impossible de soumettre les documents.';
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final apiMessage = data['message'] ?? data['error'];
        if (apiMessage is String && apiMessage.isNotEmpty) {
          message = apiMessage;
        } else if (apiMessage is List && apiMessage.isNotEmpty) {
          message = apiMessage.join('\n');
        }
      }
      AppDialog.showError(context, message);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soumission KYC'),
        backgroundColor: const Color(0xFFFF9800),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ajoutez les chemins de fichiers puis uploadez chaque document.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ..._labels.keys.map(_buildDocumentCard),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submitKyc,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send),
                  label: Text(_submitting ? 'Soumission...' : 'Soumettre tous les documents'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard(String key) {
    final uploadedUrl = _uploadedUrls[key];
    final loading = _uploading[key] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _labels[key]!,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pathControllers[key],
            decoration: const InputDecoration(
              hintText: '/Users/.../mon_document.jpg',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: loading ? null : () => _uploadDocument(key),
                icon: loading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload, size: 16),
                label: Text(loading ? 'Upload...' : 'Uploader'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  uploadedUrl == null ? 'Non uploadé' : 'Uploadé ✓',
                  style: TextStyle(
                    color: uploadedUrl == null ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
