/// 🎬 Animation Constants - Réutilisables partout
import 'package:flutter/material.dart';

class DEMAnimationConstants {
  // Glass Panel Animations
  static const Duration glassAppearDuration = Duration(milliseconds: 600);
  static const Duration glassBlurDuration = Duration(milliseconds: 800);
  static const Curve glassEntryCurve = Curves.easeOutCubic;

  // Shadow Premium (Multi-layer)
  static const double shadowElevation = 24;
  static const double shadowBlurRadius = 32;
  static const double shadowSpreadRadius = -8;

  // Gradient Glass
  static const double gradientOpacityStart = 0.15;
  static const double gradientOpacityEnd = 0.02;

  // Performance Maps
  static const Duration blurInitDelay = Duration(milliseconds: 100);
}
