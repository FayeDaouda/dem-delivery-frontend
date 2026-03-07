# Plan d'alignement Frontend-Backend DEM

## 📋 État actuel

### Backend (selon documentation fournie)

#### Flux recommandé : **OTP-Only**
1. `POST /auth/otp/request` - Envoie OTP
2. `POST /auth/otp/verify` - Vérifie OTP + retourne userId/tempToken si nouveau user
3. `POST /auth/otp/create-profile` - Crée profil complet (fullName, password, driverType)

#### Flux classique (déprécié mais actif)
1. `POST /auth/user/register` - Inscription avec fullName, phone, password, role → Envoie OTP
2. `POST /auth/verify-otp` - Vérifie OTP → Retourne tokens

### Frontend actuel

#### Pages existantes
- ✅ `otp_signup_page.dart` - Flux OTP-Only 3 étapes (DÉJÀ CRÉÉ, ALIGNÉ)
- ⚠️ `signup_page.dart` - Ancien flux à migrer
- ⚠️ `login_page.dart` - Flux login OTP à vérifier
- ✅ `profile_page.dart` - Page profil (DÉJÀ CRÉÉ)

#### Infrastructure
- ✅ DTOs OTP-Only (`otp_dtos.dart`)
- ✅ Méthodes datasource OTP-Only
- ✅ BLoC events/states pour OTP-Only
- ⚠️ Méthodes classiques à vérifier

---

## 🎯 Plan d'action

### Phase 1 : Vérifier alignement endpoints ✅

**Objectif :** S'assurer que les endpoints frontend correspondent au backend

#### Endpoints à vérifier/créer dans `auth_remote_data_source.dart`

| Backend Endpoint | Frontend Method | Status | Action |
|------------------|-----------------|--------|--------|
| `POST /auth/otp/request` | `sendOtp(phone)` | ✅ Existe | Vérifier payload |
| `POST /auth/otp/verify` | `verifyOtp(phone, code)` | ✅ Existe | Vérifier réponse |
| `POST /auth/otp/create-profile` | `createProfileOtp(...)` | ✅ Existe | Vérifier payload |
| `POST /auth/user/register` | `registerUser(...)` | ❌ Manque | Créer si besoin |
| `POST /auth/user/login` | `login(phone, password)` | ✅ Existe | Vérifier |
| `POST /auth/verify-otp-phone` | `verifyOtpPhone(...)` | ❌ Manque | Créer si besoin |
| `POST /auth/resend-otp` | `resendOtp(phone)` | ❌ Manque | Créer |
| `POST /auth/refresh-token` | `refresh(refreshToken)` | ✅ Existe | OK |
| `POST /auth/logout` | `logout()` | ✅ Existe | OK |

**Actions :**
1. ✅ Vérifier que `sendOtp()` envoie bien `{ "phone": "+221..." }`
2. ✅ Vérifier que `verifyOtp()` envoie `{ "phone", "code" }`
3. ✅ Vérifier réponse `verifyOtp()` contient `userId`, `tempToken`, `nextStep`
4. ⏳ Créer `resendOtp()` si nécessaire
5. ⏳ Créer `registerUser()` si flux classique utilisé

---

### Phase 2 : Adapter les DTOs

**Objectif :** Aligner les modèles Dart avec les réponses backend

#### DTOs à créer/adapter

##### 1. Request DTOs (déjà OK)
- ✅ `RequestOtpDto` - { phone }
- ✅ `VerifyOtpDto` - { phone, code }
- ✅ `CreateProfileOtpDto` - { userId, fullName, password, driverType, tempToken }

##### 2. Response DTOs à vérifier

**Backend `/auth/otp/request` response:**
```json
{
  "message": "OTP sent successfully",
  "data": { "phone": "+221..." },
  "otp": {
    "channel": "sms",
    "codeLength": 4,
    "expiresInSeconds": 300,
    "autofill": { ... }
  },
  "nextStep": "VERIFY_OTP"
}
```

**Backend `/auth/otp/verify` response (nouveau user):**
```json
{
  "message": "OTP verified",
  "data": {
    "userId": "uuid",
    "phone": "+221...",
    "tempToken": "temp-jwt"
  },
  "nextStep": "CREATE_PROFILE"
}
```

**Backend `/auth/otp/verify` response (user existant):**
```json
{
  "accessToken": "jwt...",
  "refreshToken": "jwt...",
  "user": {
    "id": "uuid",
    "phone": "+221...",
    "fullName": "...",
    "role": "CLIENT|DRIVER",
    "driverType": "MOTO|VTC",
    "status": "ACTIVE",
    "isVerified": true,
    "hasActivePass": false
  },
  "nextStep": "COMPLETE"
}
```

**Actions :**
1. ⏳ Adapter `VerifyOtpResponse` pour gérer 2 cas (nouveau vs existant)
2. ⏳ Ajouter champ `otp.autofill` dans `RequestOtpResponse`
3. ⏳ S'assurer que `user.hasActivePass` est bien récupéré

---

### Phase 3 : Adapter les pages UI

#### 3.1 Page d'inscription principale

**Option A : Utiliser `otp_signup_page.dart` (RECOMMANDÉ)**
- ✅ Déjà créé
- ✅ Flux OTP-Only 3 étapes
- ✅ Sélection MOTO/VTC intégrée
- ⏳ Modifier route dans `main.dart` pour pointer vers cette page

**Option B : Adapter `signup_page.dart`**
- ⏳ Supprimer champs inutiles
- ⏳ Rediriger vers `otp_signup_page.dart`

**Décision :** Remplacer `/signup` par `otp_signup_page.dart` et supprimer l'ancienne

#### 3.2 Page de login

**Adapter `login_page.dart` :**
- ✅ Flux OTP-only déjà OK
- ⏳ Gérer redirection selon `hasActivePass` pour drivers
- ⏳ Ajouter gestion `nextStep` depuis backend

**Flow login :**
```
1. User entre phone
2. Backend envoie OTP
3. User entre OTP
4. Backend vérifie:
   - Si nouveau → nextStep: CREATE_PROFILE → redirect /signup
   - Si existant CLIENT → redirect /clientHome
   - Si existant DRIVER + hasActivePass → redirect /livreurHome
   - Si existant DRIVER + !hasActivePass → redirect /driver/passes
```

---

### Phase 4 : Adapter la navigation post-auth

**Créer helper de navigation basé sur user data :**

```dart
String getHomeRouteAfterAuth(Map<String, dynamic> user) {
  final role = user['role'];
  final driverType = user['driverType'];
  final hasActivePass = user['hasActivePass'] ?? false;
  final status = user['status'];

  if (role == 'ADMIN') return '/admin/home';
  if (role == 'CLIENT') return '/clientHome';
  
  if (role == 'DRIVER') {
    if (!hasActivePass) {
      return '/driver/passes/purchase'; // TODO: Créer page
    }
    
    if (driverType == 'MOTO') {
      return '/livreurHome'; // Déjà existe
    }
    
    if (driverType == 'VTC') {
      return '/driver/vtc/home'; // TODO: Créer page
    }
  }
  
  return '/splash'; // Fallback
}
```

**Actions :**
1. ⏳ Créer helper `NavigationHelper.getHomeRoute()`
2. ⏳ Créer page `/driver/passes/purchase` (achat pass)
3. ⏳ Créer page `/driver/vtc/home` (accueil VTC)
4. ⏳ Intégrer helper dans auth_bloc après login/signup

---

### Phase 5 : Tester le flux complet

#### Tests à effectuer

**Nouveau CLIENT :**
1. ✅ Ouvrir app → Splash → Onboarding → Login
2. ⏳ Clic "S'inscrire" → `otp_signup_page.dart`
3. ⏳ Étape 1 : Entre phone → Reçoit OTP
4. ⏳ Étape 2 : Entre OTP → Backend vérifie
5. ⏳ Étape 3 : Entre fullName + password + sélectionne CLIENT
6. ⏳ Submit → Backend crée profil → Tokens reçus
7. ⏳ Redirect → `/clientHome`

**Nouveau DRIVER MOTO :**
1. ⏳ Inscription comme ci-dessus
2. ⏳ Étape 3 : Sélectionne DRIVER + MOTO
3. ⏳ Backend crée driver MOTO
4. ⏳ Redirect selon `hasActivePass`:
   - Si false → `/driver/passes/purchase`
   - Si true → `/livreurHome`

**User existant (login) :**
1. ⏳ Login page → Entre phone
2. ⏳ Reçoit OTP → Entre code
3. ⏳ Backend reconnaît user existant → Envoie tokens + user data
4. ⏳ Redirect automatique selon role + driverType + hasActivePass

---

## 📝 Checklist d'implémentation

### Datasource & API
- [ ] Vérifier payload `sendOtp()` = `{ "phone": "..." }`
- [ ] Vérifier réponse `verifyOtp()` gère 2 cas (nouveau vs existant)
- [ ] Ajouter méthode `resendOtp(String phone)`
- [ ] Vérifier `createProfileOtp()` envoie bon payload
- [ ] Tester tous endpoints avec Postman/cURL

### DTOs
- [ ] Adapter `VerifyOtpResponse` pour `nextStep` + `tempToken` + `userId`
- [ ] Ajouter champ `hasActivePass` dans user response
- [ ] Créer DTO pour `ResendOtpResponse`

### BLoC
- [ ] Adapter handler `_onVerifyOtpEvent` pour gérer 2 cas backend
- [ ] Créer event `AuthResendOtpEvent`
- [ ] Adapter states pour inclure `hasActivePass`
- [ ] Implémenter navigation conditionnelle post-auth

### UI Pages
- [ ] Remplacer route `/signup` vers `otp_signup_page.dart`
- [ ] Supprimer ancien `signup_page.dart` ou le rediriger
- [ ] Adapter `login_page.dart` pour gérer `nextStep` backend
- [ ] Créer page `/driver/passes/purchase`
- [ ] Créer page `/driver/vtc/home`

### Navigation
- [ ] Créer `NavigationHelper.getHomeRoute(user)`
- [ ] Intégrer helper dans auth success
- [ ] Tester redirections pour tous cas (CLIENT, DRIVER MOTO, DRIVER VTC, Pass actif/inactif)

### Tests
- [ ] Test nouveau CLIENT complet
- [ ] Test nouveau DRIVER MOTO
- [ ] Test nouveau DRIVER VTC
- [ ] Test login user existant (tous rôles)
- [ ] Test achat pass driver
- [ ] Test navigation selon hasActivePass

---

## 🚀 Ordre d'exécution

1. **Vérifier/adapter datasource** (1h)
2. **Adapter DTOs** (30min)
3. **Adapter BLoC** (1h)
4. **Remplacer page signup** (30min)
5. **Adapter page login** (30min)
6. **Créer helper navigation** (30min)
7. **Créer pages manquantes** (2h)
8. **Tests E2E** (2h)

**Total estimé : ~8h**

---

## 📌 Notes importantes

### Différences Backend vs Frontend actuel

1. **Backend envoie `nextStep`** dans réponses → Frontend doit le gérer
2. **Backend distingue nouveau user vs existant** dans `/auth/otp/verify` → Frontend doit gérer 2 cas
3. **Backend gère `hasActivePass`** pour drivers → Frontend doit rediriger en conséquence
4. **Backend supporte `driverType` : MOTO | VTC** → Frontend doit gérer les 2 types

### Points d'attention

- ⚠️ **Password dans OTP-Only ?** Doc backend mentionne password dans `create-profile`. À clarifier.
- ⚠️ **Autofill OTP** : Backend retourne config autofill SMS. Frontend peut l'utiliser.
- ⚠️ **Rate limiting** : Backend limite à 5 req/min. Frontend doit gérer erreurs 429.
- ⚠️ **Format téléphone** : Backend attend format Sénégal `+221...`. Valider côté frontend.

---

**Dernière mise à jour :** 7 mars 2026
**Status :** 🟡 En cours d'implémentation
