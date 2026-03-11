/// États possibles du panel livreur
enum LivreurPanelState {
  /// Écran de bienvenue (pas de pass actif)
  welcome,

  /// Écran d'activation du pass (choix paiement)
  passActivation,

  /// Pass actif (livraisons disponibles)
  activePass,
}
