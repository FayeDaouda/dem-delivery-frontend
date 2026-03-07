import '../../features/auth/data/models/otp_dtos.dart';

/// Helper pour déterminer la route de navigation après authentification
/// Basé sur le rôle, driverType et hasActivePass de l'utilisateur
class NavigationHelper {
  /// Retourne la route d'accueil appropriée selon les données utilisateur
  static String getHomeRoute({
    required String role,
    String? driverType,
    bool? hasActivePass,
  }) {
    // ADMIN
    if (role.toUpperCase() == 'ADMIN') {
      return '/admin/home'; // TODO: Créer page admin
    }

    // CLIENT
    if (role.toUpperCase() == 'CLIENT') {
      return '/clientHome';
    }

    // DRIVER
    if (role.toUpperCase() == 'DRIVER') {
      // Pas de pass actif → Achat pass obligatoire
      if (hasActivePass == false) {
        return '/driver/passes/purchase'; // TODO: Créer page
      }

      // DRIVER MOTO avec pass actif
      if (driverType?.toUpperCase() == 'MOTO') {
        return '/livreurHome';
      }

      // DRIVER VTC avec pass actif
      if (driverType?.toUpperCase() == 'VTC') {
        return '/driver/vtc/home'; // TODO: Créer page
      }

      // DRIVER sans type spécifié → Fallback livreur home
      return '/livreurHome';
    }

    // Fallback général
    return '/splash';
  }

  /// Retourne la route depuis un objet UserProfileData
  static String getHomeRouteFromUser(UserProfileData user) {
    return getHomeRoute(
      role: user.role,
      driverType: user.driverType,
      hasActivePass: user.hasActivePass,
    );
  }

  /// Vérifie si l'utilisateur a besoin d'acheter un pass
  static bool needsPassPurchase({
    required String role,
    bool? hasActivePass,
  }) {
    return role.toUpperCase() == 'DRIVER' && hasActivePass == false;
  }

  /// Retourne un message d'accueil personnalisé
  static String getWelcomeMessage({
    required String role,
    String? driverType,
    bool? hasActivePass,
  }) {
    if (role.toUpperCase() == 'CLIENT') {
      return 'Bienvenue ! Commandez votre livraison';
    }

    if (role.toUpperCase() == 'DRIVER') {
      if (hasActivePass == false) {
        return 'Activez votre pass pour commencer à livrer';
      }

      if (driverType?.toUpperCase() == 'MOTO') {
        return 'Prêt à livrer avec votre moto ?';
      }

      if (driverType?.toUpperCase() == 'VTC') {
        return 'Prêt à conduire des passagers ?';
      }

      return 'Bienvenue livreur !';
    }

    return 'Bienvenue sur DEM';
  }
}
