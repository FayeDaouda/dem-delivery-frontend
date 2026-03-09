# 🧪 Guide de Tests E2E - Phase 5

**Application**: Delivery Express Mobility Frontend  
**Date**: 7 mars 2026  
**Objectif**: Valider le flux OTP-Only complet avec navigation conditionnelle

---

## 🎯 Prérequis Tests

### Backend Requis
- ✅ Backend DEM démarré sur `http://localhost:3000`
- ✅ Endpoints fonctionnels:
  - `POST /auth/otp/request`
  - `POST /auth/otp/verify`
  - `POST /auth/otp/create-profile`
  - `POST /auth/resend-otp`

### Application Frontend
- ✅ `flutter run` lancé
- ✅ Émulateur/Simulateur connecté
- ✅ Compilation réussie

---

## 📋 Checklist Tests Complets

### ✅ Test 1: Nouveau CLIENT - Signup Complet
**Objectif**: Créer un nouveau compte CLIENT et vérifier navigation

#### Étapes:
1. **Splash Screen** → Auto-navigation vers Onboarding
2. **Onboarding** → Cliquer "Commencer" → Login
3. **Login** → Cliquer "Créer un compte" → Signup
4. **Signup Step 1**: Entrer numéro téléphone
   - Format: `+221 XX XXX XX XX` (Sénégal)
   - Exemple: `+221 77 123 45 67`
   - Cliquer "Continuer"
5. **Signup Step 2**: Saisir code OTP reçu
   - 6 chiffres
   - Backend doit répondre `nextStep: "CREATE_PROFILE"`
   - Vérifier bouton "Renvoyer le code"
6. **Signup Step 3**: Créer profil
   - Nom complet: "Test CLIENT"
   - Password: minimum 6 caractères
   - **NE PAS sélectionner driver type** (CLIENT par défaut)
   - Cliquer "Créer mon compte"
7. **Navigation attendue**: `/clientHome`
8. **Vérifications**:
   - ✅ Page ClientHomePage affichée
   - ✅ Message "Bonjour, Test CLIENT!"
   - ✅ Bouton profil accessible

**Backend Response Attendue**:
```json
POST /auth/otp/create-profile
{
  "user": {
    "id": "...",
    "name": "Test CLIENT",
    "phone": "+221771234567",
    "role": "CLIENT",
    "hasActivePass": null
  },
  "accessToken": "...",
  "refreshToken": "..."
}
```

---

### ✅ Test 2: Nouveau DRIVER MOTO - SANS Pass
**Objectif**: Vérifier redirection vers page achat de pass

#### Étapes:
1-4. *Même que Test 1 (phone + OTP)*
5. **Signup Step 3**: Créer profil DRIVER
   - Nom: "Test MOTO"
   - Password: ••••••
   - **Sélectionner driver type: MOTO** 🏍️
   - Cliquer "Créer mon compte"
6. **Navigation attendue**: `/driver/passes/purchase`
7. **Vérifications**:
   - ✅ Page DriverPassesPurchasePage affichée
   - ✅ Liste de pass disponibles:
     * Pass Journalier (1000 FCFA)
     * Pass Hebdomadaire (5000 FCFA)
   - ✅ Boutons "Acheter ce pass" fonctionnels
8. **Test Achat**: Cliquer "Acheter Pass Journalier"
   - Dialog de confirmation
   - Confirmer achat
   - ✅ SnackBar "Achat en cours..."
   - ✅ Redirection vers `/livreurHome` après 2 secondes

**Backend Response Attendue**:
```json
{
  "user": {
    "role": "DRIVER",
    "driverType": "MOTO",
    "hasActivePass": false
  }
}
```

---

### ✅ Test 3: Nouveau DRIVER MOTO - AVEC Pass
**Objectif**: Vérifier navigation directe vers page livreur

#### Étapes:
1-5. *Créer profil DRIVER MOTO*
6. **Backend mock**: Configurer `hasActivePass: true`
7. **Navigation attendue**: `/livreurHome`
8. **Vérifications**:
   - ✅ Page LivreurHomePage affichée
   - ✅ Carte Google Maps
   - ✅ Panel "Bienvenue" ou "Activation pass"
   - ✅ Badges et statistiques

---

### ✅ Test 4: Nouveau DRIVER VTC - SANS Pass
**Objectif**: Vérifier page achat de pass pour VTC

#### Étapes:
1-4. *Phone + OTP*
5. **Signup Step 3**:
   - Nom: "Test VTC"
   - **Sélectionner driver type: VTC** 🚗
6. **Navigation attendue**: `/driver/passes/purchase`
7. *Même vérifications que Test 2*

---

### ✅ Test 5: Nouveau DRIVER VTC - AVEC Pass
**Objectif**: Vérifier navigation vers page VTC spécifique

#### Étapes:
1-5. *Créer profil VTC avec hasActivePass: true*
6. **Navigation attendue**: `/driver/vtc/home`
7. **Vérifications**:
   - ✅ Page DriverVtcHomePage affichée
   - ✅ Carte Google Maps
   - ✅ Bouton "Se mettre en ligne" / "Se mettre hors ligne"
   - ✅ Header avec nom chauffeur + rating
   - ✅ Panel statistiques (si en ligne):
     * Gains du jour
     * Nombre de courses

**Test Toggle Online**:
- Cliquer "Se mettre en ligne"
- ✅ SnackBar "Vous êtes en ligne"
- ✅ Panel statistiques s'affiche
- ✅ Bouton change "Se mettre hors ligne"

---

### ✅ Test 6: Login Utilisateur Existant - CLIENT
**Objectif**: Vérifier navigation directe sans étape profil

#### Étapes:
1. **Login Page**: Entrer téléphone existant
   - Exemple: `+221 77 999 88 77` (CLIENT existant)
2. **Saisir OTP**
3. **Backend Response**: `nextStep: "COMPLETE"`
4. **Navigation attendue**: `/clientHome` (direct)
5. **Vérifications**:
   - ✅ Pas d'étape création profil
   - ✅ Navigation immédiate après OTP
   - ✅ Données user chargées depuis backend

**Backend Response Attendue**:
```json
POST /auth/otp/verify
{
  "nextStep": "COMPLETE",
  "accessToken": "...",
  "refreshToken": "...",
  "user": {
    "id": "...",
    "role": "CLIENT",
    ...
  }
}
```

---

### ✅ Test 7: Login Utilisateur Existant - DRIVER avec Pass
**Objectif**: Navigation conditionnelle selon driverType

#### Test 7A: DRIVER MOTO avec Pass
- Phone: `+221 76 111 22 33`
- Backend: `role: DRIVER, driverType: MOTO, hasActivePass: true`
- **Navigation attendue**: `/livreurHome`

#### Test 7B: DRIVER VTC avec Pass
- Phone: `+221 76 222 33 44`
- Backend: `role: DRIVER, driverType: VTC, hasActivePass: true`
- **Navigation attendue**: `/driver/vtc/home`

#### Test 7C: DRIVER sans Pass
- Phone: `+221 76 333 44 55`
- Backend: `hasActivePass: false`
- **Navigation attendue**: `/driver/passes/purchase`

---

### ✅ Test 8: Resend OTP
**Objectif**: Vérifier fonctionnalité de renvoi de code

#### Étapes:
1. **Signup/Login**: Arriver à l'étape OTP
2. **Attendre 5 secondes** (timer "Renvoyer le code")
3. **Cliquer**: "Renvoyer le code"
4. **Vérifications**:
   - ✅ SnackBar "Code OTP renvoyé"
   - ✅ Backend appelé `POST /auth/resend-otp`
   - ✅ Nouveau code reçu
   - ✅ Possibilité de re-saisir

---

### ✅ Test 9: Gestion Erreurs

#### Test 9A: OTP Invalide
- Saisir code incorrect
- ✅ Dialog erreur "Code OTP invalide"
- ✅ Possibilité de réessayer

#### Test 9B: Téléphone Déjà Utilisé (Signup)
- Tenter signup avec numéro existant
- Backend devrait rediriger vers login ou créer profil

#### Test 9C: Connexion Backend Échouée
- Couper backend temporairement
- Tenter OTP
- ✅ Dialog erreur réseau
- ✅ Message clair pour l'utilisateur

---

## 🔍 Tests NavigationHelper

### Matrice de Vérification

| Role   | DriverType | hasActivePass | Route Attendue               | Status |
|--------|-----------|---------------|------------------------------|--------|
| CLIENT | null      | null          | `/clientHome`                | ⏳     |
| DRIVER | MOTO      | false         | `/driver/passes/purchase`    | ⏳     |
| DRIVER | MOTO      | true          | `/livreurHome`               | ⏳     |
| DRIVER | VTC       | false         | `/driver/passes/purchase`    | ⏳     |
| DRIVER | VTC       | true          | `/driver/vtc/home`           | ⏳     |
| ADMIN  | null      | null          | `/admin/home`                | ⏳     |

**Méthode de Test**:
- Créer logs dans `NavigationHelper.getHomeRoute()`
- Vérifier console pour chaque cas
- Valider que route retournée = route attendue

---

## 📊 Résultats Attendus

### Compilation
- ✅ `flutter analyze` sans erreurs critiques
- ⚠️ Info warnings acceptables (avoid_print, prefer_const)

### Fonctionnel
- ✅ Tous les flux de navigation fonctionnent
- ✅ Backend responses gérées correctement
- ✅ UI/UX cohérent sur toutes les pages
- ✅ Pas de crash ou erreur runtime

### Performance
- ✅ Temps de navigation < 500ms
- ✅ Pas de lag sur cartes Google Maps
- ✅ Animations fluides

---

## 🐛 Bugs Connus à Vérifier

### À Surveiller
1. **Timer Resend OTP**: S'assurer qu'il ne bloque pas l'UI
2. **Google Maps**: Permissions localisation
3. **Redirection après achat pass**: Vérifier mounted avant pushReplacementNamed
4. **Gestion état BLoC**: Pas de memory leak sur navigation

---

## 📝 Rapport de Tests

### Remplir après tests:

**Test 1 - CLIENT**: ⏳ En attente  
**Test 2 - MOTO sans pass**: ⏳ En attente  
**Test 3 - MOTO avec pass**: ⏳ En attente  
**Test 4 - VTC sans pass**: ⏳ En attente  
**Test 5 - VTC avec pass**: ⏳ En attente  
**Test 6 - Login CLIENT**: ⏳ En attente  
**Test 7 - Login DRIVER**: ⏳ En attente  
**Test 8 - Resend OTP**: ⏳ En attente  
**Test 9 - Gestion erreurs**: ⏳ En attente  

---

## ✅ Critères de Validation Phase 5

Pour considérer Phase 5 comme ✅ **TERMINÉE**:

1. ✅ Tous les tests 1-9 réussis
2. ✅ Matrice navigation 100% validée
3. ✅ Aucune erreur critique détectée
4. ✅ Documentation mise à jour avec résultats
5. ✅ Commit final avec rapport de tests

---

**Prochaine étape**: Exécuter les tests manuellement et remplir le rapport ci-dessus.

