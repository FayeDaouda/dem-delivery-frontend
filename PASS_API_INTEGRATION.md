# 🎟️ Intégration API PASS - Contrat Aligné

**Date :** 6 mars 2026  
**Statut :** ✅ Production Ready  
**Version API Backend :** 06/03/2026

---

## 📋 Conformité au Contrat API

Toutes les modifications ont été alignées avec le **contrat API PASS** fourni.

### ✅ Checklist Conformité

#### 1. POST /passes/purchase

| Aspect | Statut | Détails |
|--------|--------|---------|
| ✅ Ne pas envoyer `price` | Implémenté | Le champ `price` ne peut pas être envoyé |
| ✅ Envoyer `clientRequestId` | Implémenté | UUID v4 généré automatiquement |
| ✅ Validation `phoneNumber` | Implémenté | Obligatoire pour wave/orange_money |
| ✅ Support `promoCode` | Implémenté | Envoyé si fourni |
| ✅ Gestion payement immédiat | Implémenté | Status `success` → pass actif |
| ✅ Gestion paiement pending | Implémenté | Status `pending` → état PassActivationPending |
| ✅ Extraction `validUntil` | Implémenté | Depuis `response.pass.validUntil` |

#### 2. GET /passes/current

| Aspect | Statut | Détails |
|--------|--------|---------|
| ✅ Parsing `hasValidPass` | Implémenté | `true` = pass actif, `false` = inactif |
| ✅ Parsing `pass` object | Implémenté | Structure: `{ id, type, status, validUntil }` |
| ✅ Parsing `remainingSeconds` | Implémenté | Fallback si `validUntil` absent |
| ✅ Gestion 5xx errors | Implémenté | Retourne `null` au lieu de bloquer |
| ✅ Polling 30s | Implémenté | Polling continu pendant utilisation |

#### 3. Gestion des Statuts de Transaction

| Status | Action | Code |
|--------|--------|------|
| `success` | Afficher pass actif | `PassActivationSuccess` → `PassActive` |
| `pending` | Afficher alerte attente | `PassActivationPending` (nouvel état) |
| `failed` | Afficher erreur | `PassError` |
| `cancelled` | (Futur) | Non implémenté |

---

## 🔧 Changements Implémentés

### 1. Nouveau Modèle de Réponse

**Fichier :** [lib/features/passes/data/repositories/pass_repository.dart](lib/features/passes/data/repositories/pass_repository.dart)

```dart
/// Réponse lors de l'activation d'un pass
class PassActivationResponse {
  final DateTime? validUntil;      // Si succès immédiat
  final bool isPending;              // Si paiement en attente
  final String? transactionReference; // Référence paiement
  final int? amount;                 // Montant payé
}
```

Raison: Permet de distinguer succès immédiat vs paiement en attente.

### 2. Suppression du champ `price`

Avant:
```dart
if (price != null) payload['price'] = price;  // ❌ JAMAIS envoyer
```

Après:
```dart
// NOTE: 'price' ne doit JAMAIS être envoyé, il est calculé par le backend
```

### 3. Nouvel État BLoC: PassActivationPending

**Fichier :** [lib/features/passes/presentation/bloc/pass_state.dart](lib/features/passes/presentation/bloc/pass_state.dart)

```dart
class PassActivationPending extends PassState {
  final String reference;    // Référence transaction
  final int amount;          // Montant

  const PassActivationPending({
    required this.reference,
    required this.amount,
  });
}
```

Permet à l'UI de :
- Afficher "Paiement en cours..."
- Montrer la référence transaction pour suivi
- Continuer le polling GET /passes/current jusqu'au succès

### 4. Gestion Paiement Pending dans le BLoC

**Fichier :** [lib/features/passes/presentation/bloc/pass_bloc.dart](lib/features/passes/presentation/bloc/pass_bloc.dart)

```dart
if (response.isPending) {
  // Paiement en attente - afficher état pending
  emit(PassActivationPending(
    reference: response.transactionReference ?? 'UNKNOWN',
    amount: response.amount ?? 0,
  ));
} else {
  // Paiement succès - pass immédiatement actif
  emit(PassActivationSuccess(validUntil: validUntil));
  emit(PassActive(validUntil: validUntil));
}
```

### 5. UI: Gestion du statut Pending

**Fichier :** [lib/pages/livreur_home_page.dart](lib/pages/livreur_home_page.dart#L545-L552)

```dart
} else if (state is PassActivationPending) {
  // Paiement en attente - afficher message
  DEMToast.show(
    context: context,
    message: '⏳ Paiement en cours... Reference: ${state.reference}',
    type: ToastType.warning,
  );
  // Le polling GET /passes/current va détecter la confirmation
}
```

---

## 🔄 Flux d'Activation Complet

### Scénario 1: Paiement Immédiat (Wave, Orange, Yas)

```
1. User saisit numéro + clique "ACTIVER"
   ↓
2. POST /passes/purchase
   {
     "type": "daily",
     "paymentMethod": "wave",
     "phoneNumber": "+221771234567",
     "clientRequestId": "uuid"
   }
   ↓
3. Backend retourne (succès immédiat)
   {
     "pass": { "id": "...", "validUntil": "2026-03-07T..." },
     "transaction": { "status": "success" }
   }
   ↓
4. Frontend
   - Emit PassActivationSuccess → PassActive
   - Affiche ✅ "Pass activé"
   - Affiche countdown "23h 45m"
```

### Scénario 2: Paiement en Attente (Cash, API tiers)

```
1. POST /passes/purchase
   {
     "type": "daily",
     "paymentMethod": "cash"
   }
   ↓
2. Backend retourne (paiement en attente)
   {
     "pass": null,
     "transaction": {
       "reference": "PASS_PURCHASE_ABC123",
       "status": "pending",
       "paymentUrl": "https://..."
     }
   }
   ↓
3. Frontend
   - Emit PassActivationPending
   - Affiche ⏳ "Paiement en cours..."
   - Affiche référence "PASS_PURCHASE_ABC123"
   - Polling GET /passes/current toutes les 30s
   ↓
4. Quand paiement confirmé (webhook backend)
   - GET /passes/current retourne hasValidPass=true
   - Emit PassActive
   - Affiche pass actif
```

---

## 📊 Parsing Réponses Backend

### POST /passes/purchase - Structure Attendue

```json
{
  "pass": {
    "id": "uuid",
    "type": "daily",
    "status": "active|pending",
    "validFrom": "2026-03-06T10:00:00.000Z",
    "validUntil": "2026-03-07T10:00:00.000Z",
    "price": 1650,
    "paymentMethod": "wave"
  },
  "transaction": {
    "reference": "PASS_PURCHASE_ABC123",
    "amount": 1650,
    "status": "success|pending|failed"
  }
}
```

**Parsing implémenté:**
- ✅ `transaction.status` détermine le flux
- ✅ `pass.validUntil` extrait automatiquement
- ✅ Fallback 24h si `validUntil` manquant

### GET /passes/current - Structure Attendue

```json
{
  "hasValidPass": true|false,
  "pass": {
    "id": "uuid",
    "type": "daily",
    "status": "active",
    "validUntil": "2026-03-07T10:00:00.000Z"
  },
  "remainingSeconds": 86399
}
```

**Parsing implémenté:**
- ✅ Vérifie `hasValidPass`
- ✅ Extrait `validUntil` de `pass.validUntil`
- ✅ Fallback `remainingSeconds` si `validUntil` manquant
- ✅ Ignore erreurs 5xx silencieusement

---

## 🧪 Tests Manuels Recommandés

### Test 1: Paiement Wave (immédiat)
```
1. Lancer app
2. Cliquer "Activer Pass"
3. Sélectionner "Wave"
4. Saisir numéro (+221770000066)
5. Cliquer "ACTIVER PASS"
6. ✅ Attendre: "Pass activé" + countdown
```

### Test 2: Paiement Orange Money (immédiat)
```
Même que Test 1, sélectionner "Orange"
```

### Test 3: Paiement Yas (immédiat)
```
Même que Test 1, sélectionner "Yas"
Note: Yas n'a pas besoin de numéro
```

### Test 4: Code Promo
```
1. Activer "Ajouter code promo"
2. Saisir: PROMO2024
3. Cliquer "ACTIVER PASS"
4. ✅ Code transmis au backend
```

### Test 5: Paiement Pending (futur)
```
Simuler côté backend:
- Payload: { "paymentMethod": "cash" }
- Retourner status: "pending"
- UI affiche "⏳ Paiement en cours"
- Polling continue toutes les 30s
- Quand backend confirme: pass devient actif
```

---

## 🚀 Commandes Déploiement

```bash
# Vérifier conformité
flutter analyze --no-fatal-infos lib/

# Tester
flutter run

# Build production
flutter build apk --release   # Android
flutter build ios --release   # iOS
```

---

## 📚 Endpoints Futurs (Non Implémentés)

Ces endpoints du contrat API sont documentés mais non encore intégrés:

| Endpoint | Priorité | Notes |
|----------|----------|-------|
| `GET /passes/history` | Medium | Afficher historique passes |
| `GET /passes/stats` | Low | Admin seulement |
| `POST /passes/:id/cancel` | Low | Annuler un pass |
| `GET /webhooks/payment/status/:ref` | High | Poller statut paiement pending |
| `POST /webhooks/payment/wave` | Backend | Webhook Wave |
| `POST /webhooks/payment/orange-money` | Backend | Webhook Orange |

---

## ✨ Notes de Sécurité

1. ✅ **clientRequestId:** Prévient les doublons (idempotence)
2. ✅ **Validation phoneNumber:** Obligatoire pour wave/orange_money
3. ✅ **Price:** Jamais envoyé du client, toujours calculé backend
4. ✅ **Bearer Token:** Toutes requêtes authentifiées
5. ✅ **Rôle DRIVER:** Vérifié côté backend

---

**Dernière mise à jour:** 6 mars 2026  
**Prêt pour:** Tests UAT & Déploiement Production
