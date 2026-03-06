import 'package:flutter/material.dart';

enum AppDialogType { success, error, warning, info }

class AppDialog {
  const AppDialog._();

  static Future<void> showSuccess(BuildContext context, String message) {
    return _show(context, message, type: AppDialogType.success);
  }

  static Future<void> showError(BuildContext context, String message) {
    return _show(context, message, type: AppDialogType.error);
  }

  static Future<void> showWarning(BuildContext context, String message) {
    return _show(context, message, type: AppDialogType.warning);
  }

  static Future<void> showInfo(BuildContext context, String message) {
    return _show(context, message, type: AppDialogType.info);
  }

  static Future<void> _show(
    BuildContext context,
    String message, {
    required AppDialogType type,
  }) {
    if (!context.mounted) return Future.value();

    final config = _DialogConfig.fromType(type, Theme.of(context));

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: config.bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(config.icon, color: config.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  config.title,
                  style:
                      Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: config.color,
                          ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: Theme.of(dialogContext).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class _DialogConfig {
  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _DialogConfig({
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  factory _DialogConfig.fromType(AppDialogType type, ThemeData theme) {
    switch (type) {
      case AppDialogType.success:
        return _DialogConfig(
          title: 'Succès',
          icon: Icons.check_circle,
          color: Colors.green.shade700,
          bgColor: Colors.green.shade50,
        );
      case AppDialogType.error:
        return _DialogConfig(
          title: 'Erreur',
          icon: Icons.error,
          color: Colors.red.shade700,
          bgColor: Colors.red.shade50,
        );
      case AppDialogType.warning:
        return _DialogConfig(
          title: 'Attention',
          icon: Icons.warning_amber_rounded,
          color: Colors.orange.shade700,
          bgColor: Colors.orange.shade50,
        );
      case AppDialogType.info:
        return _DialogConfig(
          title: 'Information',
          icon: Icons.info,
          color: const Color(0xFF2196F3),
          bgColor: const Color(0xFFEAF4FE),
        );
    }
  }
}
