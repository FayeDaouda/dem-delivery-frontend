import 'package:flutter/material.dart';

class DeliveryActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color? backgroundColor;

  const DeliveryActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
