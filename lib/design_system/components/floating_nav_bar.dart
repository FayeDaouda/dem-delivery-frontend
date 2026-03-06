/// 📱 Bottom Navigation Bar - Simple & Clean
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/colors.dart';

class FloatingNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<FloatingNavItem> items;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar> {
  void _onItemTap(int index) {
    HapticFeedback.lightImpact();
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: 8,
      left: 16,
      right: 16,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding > 0 ? 0 : 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 18,
                      spreadRadius: -4,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    widget.items.length,
                    (index) => _NavItem(
                      item: widget.items[index],
                      isActive: index == widget.currentIndex,
                      onTap: () => _onItemTap(index),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final FloatingNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? DEMColors.primary : Colors.transparent,
        ),
        child: Icon(
          item.icon,
          color: isActive ? Colors.white : Colors.black,
          size: 22,
        ),
      ),
    );
  }
}

class FloatingNavItem {
  final IconData icon;
  final String? label;

  FloatingNavItem({required this.icon, this.label});
}
