# Phase 1 MVP - Guide du Flux d'Authentification

## 📋 Vue d'ensemble

Le Phase 1 MVP simplifie l'authentification en utilisant :
- **OTP seulement pour l'inscription** : Numéro → OTP → Création de profil
- **Mot de passe pour la connexion existants** : Pour utilisateurs existants + tests internes
- **Navigation unifiée** : Même écran OTP pour CLIENT et DRIVER

## 🔄 Flux d'authentification

```
SplashPage
    ↓
OnboardingPage (première ouverture seulement)
    ↓
LoginPage
    ├─ Connexion existants → AuthLoginEvent (numéro + mot de passe)
    │   ↓
    │   AuthSuccess → ClientHomePage ou LivreurHomePage
    │
    └─ Lien "Créer un compte" → SignupPage
        ↓
    SignupPage (Étape 1: Numéro + Rôle)
        ↓
    OTPVerificationWidget (Étape 2: Vérification OTP)
        ↓
    SignupPage (Étape 3: Création profil)
        ↓
    AuthSuccess → ClientHomePage ou LivreurHomePage
```

## 🔐 Pages et Composants

### 1. **LoginPage** (`lib/pages/login_page.dart`)
**Objectif** : Connexion des utilisateurs existants

**Fonctionnalités** :
- Champ numéro de téléphone
- Champ mot de passe
- Bouton "Se connecter"
- Lien "Créer un compte" → SignupPage

**Événements BLoC** :
```dart
AuthLoginEvent(phone: "+221...", password: "password123")
```

**Navigation** :
- ✅ AuthSuccess(role="CLIENT") → `/clientHome`
- ✅ AuthSuccess(role="DRIVER") → `/livreurHome`
- ✅ AuthFailure → SnackBar avec message d'erreur

---

### 2. **SignupPage** (`lib/pages/signup_page.dart`)
**Objectif** : Inscription des nouveaux utilisateurs

**Structure** :
```dart
// Écran 1: Numéro + Sélection rôle
- Champ numéro de téléphone
- Sélection CLIENT ou DRIVER
- Bouton "Recevoir le code OTP"

// Écran 2: Vérification OTP (utilise OTPVerificationWidget)
- 4 champs OTP
- Bouton "Vérifier"
- Lien "Renvoyer le code" (avec countdown 60s)

// Écran 3: Création profil (futur)
// À implémenter : nom, prénom, adresse, etc.
```

**Événements BLoC** :
```dart
// Étape 1
AuthSendOtpEvent(phone: "+221...")

// Étape 2
AuthVerifyOtpEvent(phone: "+221...", code: "1234")

// Étape 3 (futur)
AuthCreateProfileEvent(...)
```

**États BLoC** :
```dart
AuthLoading         // Envoi OTP ou vérification
AuthSuccess(role)   // Inscription réussie
AuthFailure(msg)    // Erreur OTP
```

---

### 3. **OTPVerificationWidget** (`lib/pages/signup_page.dart`)
**Objectif** : Vérification OTP réutilisable pour CLIENT et DRIVER

**Paramètres** :
```dart
OTPVerificationWidget(
  phoneNumber: "+221701234567",     // Numéro à vérifier
  role: "CLIENT",                   // CLIENT ou DRIVER
  onBackPressed: () { ... },        // Retour à l'étape 1
  onSuccess: (role) { ... },        // Après vérification réussie
)
```

**Caractéristiques** :
- 4 champs OTP (input masqué, auto-focus)
- Auto-avance entre les champs
- Bouton "Renvoyer le code" avec countdown 60s
- Gestion d'erreur
- État de chargement pendant la vérification

---

## 📱 Routes Navigation

Ajouter ces routes à `lib/main.dart` :

```dart
routes: {
  '/splash': (_) => const SplashPage(),
  '/onboarding': (_) => const OnboardingPage(),
  '/login': (_) => const LoginPage(),
  '/signup': (_) => const SignupPage(),
  '/clientHome': (_) => const ClientHomePage(),
  '/livreurHome': (_) => const LivreurHomePage(),
},
initialRoute: '/splash',
```

---

## 🔌 Intégration avec AuthBloc

### AuthBloc Events
```dart
// Phase 1 MVP
AuthLoginEvent(phone, password)           // Connexion existants
AuthSendOtpEvent(phone)                  // Demander OTP
AuthVerifyOtpEvent(phone, code)          // Vérifier OTP
AuthLogoutEvent()                        // Déconnexion

// Phase 2 (futur)
AuthCreateProfileEvent(name, role, ...) // Création profil
AuthCheckStatusEvent()                   // Vérifier statut
```

### AuthBloc States
```dart
AuthInitial                     // État initial
AuthLoading                     // En cours de traitement
AuthSuccess(role, userName)     // Inscription/connexion réussie
AuthFailure(message)            // Erreur
AuthUnauthenticated             // Pas authentifié
```

---

## 📝 Exemple d'utilisation complet

### Flux Client normal
```
1. Splash → vérifie JWT existant
   ├─ JWT valide → ClientHomePage
   └─ Pas de JWT → Onboarding (première ouverture) → LoginPage

2. LoginPage → entre numéro + mot de passe
   └─ Envoie AuthLoginEvent
       └─ AuthSuccess → ClientHomePage

3. OU LoginPage → clique "Créer un compte" → SignupPage
   ├─ Entre numéro (+221701234567) + sélectionne "CLIENT"
   ├─ Envoie AuthSendOtpEvent
   │   └─ Affiche OTPVerificationWidget
   ├─ Entre OTP (1234)
   │   └─ Envoie AuthVerifyOtpEvent
   │       └─ AuthSuccess → ClientHomePage
   └─ OTP accepté → JWT stocké en SecureStorage
```

### Flux Livreur (identique, rôle CLIENT → DRIVER)
```
1. Inscription → sélectionne "DRIVER" au lieu de "CLIENT"
2. Après AuthSuccess(role="DRIVER") → LivreurHomePage (au lieu de ClientHomePage)
```

---

## 🛠️ Checklist d'implémentation

### Phase 1 MVP (Actuel)
- [x] SplashScreenWidget - Vérification JWT + routing
- [x] OnboardingWidget - Première ouverture
- [x] LoginPage - Refactorisé pour MVP (connexion existants)
- [x] SignupPage - Inscription OTP (phone + rôle + OTP)
- [x] OTPVerificationWidget - Vérification OTP réutilisable
- [ ] Routes `/signup` ajoutées à main.dart
- [ ] AuthBloc vérifie que AuthSendOtpEvent et AuthVerifyOtpEvent existent
- [ ] Tests du flux complet

### Phase 2 (Futur)
- [ ] Création profil après OTP (nom, prénom, adresse)
- [ ] ProfileCreationPage avec formulaire
- [ ] AuthCreateProfileEvent dans AuthBloc
- [ ] Middleware API pour vérifier OTP valide

### Post-MVP
- [ ] Récupération mot de passe oublié
- [ ] Login social (Facebook, Google, Apple)
- [ ] 2FA pour utilisateurs sensibles

---

## 🧪 Scénarios de test

### Test 1: Connexion existant ✅
```
1. Ouvrir app → SplashPage
2. Vérifier JWT + rôle → LoginPage
3. Entrer numéro + mot de passe
4. Vérifier navigation ClientHomePage/LivreurHomePage selon rôle
```

### Test 2: Inscription nouveau client ✅
```
1. LoginPage → "Créer un compte"
2. SignupPage: Entrer numéro + sélectionner "CLIENT"
3. Recevoir OTP → OTPVerificationWidget
4. Entrer OTP (mock: "0000" ou vrai OTP)
5. Vérifier AuthSuccess → ClientHomePage
```

### Test 3: Inscription nouveau livreur ✅
```
Identique à Test 2 mais sélectionner "DRIVER"
→ Vérifie LivreurHomePage au lieu de ClientHomePage
```

### Test 4: Renvoi OTP ✅
```
1. SignupPage → Recevoir OTP
2. OTPVerificationWidget → Attendre countdown 60s
3. Vérifier bouton "Renvoyer le code" activé après countdown
4. Envoyer AuthSendOtpEvent à nouveau
```

### Test 5: OTP invalide ❌
```
1. SignupPage → Recevoir OTP
2. OTPVerificationWidget → Entrer mauvais OTP
3. Vérifier AuthFailure affichée + rester sur OTPVerificationWidget
4. Clicker "Retour" → revenir à SignupPage
```

---

## 📦 Fichiers modifiés/créés

```
lib/pages/
  ├─ login_page.dart          (REFACTORISÉ - 394 → ~150 lignes)
  ├─ signup_page.dart         (CRÉÉ - ~300 lignes)
  ├─ splash_page.dart         (REFACTORISÉ - 110 → 20 lignes)
  └─ onboarding_page.dart     (REFACTORISÉ - 257 → 39 lignes)

lib/widgets/
  ├─ splash_screen_widget.dart      (CRÉÉ - 170 lignes)
  ├─ onboarding_widget.dart         (CRÉÉ - 468 lignes)
  └─ [OTPVerificationWidget intégré dans signup_page.dart]

lib/features/auth/presentation/bloc/
  └─ auth_bloc.dart           (À vérifier: AuthSendOtpEvent, AuthVerifyOtpEvent)

lib/main.dart
  └─ Routes: /signup et /login ajoutées
```

---

## 💡 Notes importantes

1. **Sécurité JWT** : Après AuthSuccess, le JWT est automatiquement stocké en SecureStorage par AuthBloc
2. **Rôle déterminé** : Lors de l'inscription, le rôle est choisi au Step 1 et utilisé lors du AuthVerifyOtpEvent
3. **Navigation finale** : Déterminée par le rôle reçu dans AuthSuccess
4. **OTP Réutilisable** : OTPVerificationWidget ne connaît pas le rôle, juste le numéro et le callback
5. **Refresh token** : Géré automatiquement par Dio interceptors

---

## 🚀 Prochaines étapes

1. **Vérifier AuthBloc**
   - Confirmer AuthSendOtpEvent et AuthVerifyOtpEvent
   - Confirmer API endpoints `/auth/send-otp` et `/auth/verify-otp`

2. **Ajouter routes** dans `lib/main.dart`
   ```dart
   '/signup': (_) => const SignupPage(),
   '/login': (_) => const LoginPage(),
   ```

3. **Tests d'intégration**
   - Tester flux complet (Splash → Onboarding → Login/Signup)
   - Vérifier navigation basée sur le rôle

4. **Phase 2: Création profil**
   - Créer ProfileCreationPage après OTP
   - Ajouter formulaire (nom, prénom, adresse, photo)
   - Intégrer au flux SignupPage

---

**Créé par** : CI/CD Pipeline  
**Version** : Phase 1 MVP v1.0  
**Date** : 2024  
**Status** : ✅ Implémentation en cours
