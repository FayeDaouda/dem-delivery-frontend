# Routes Required - Phase 1 MVP Navigation

## ⚠️ Action requise : Ajouter les routes dans `lib/main.dart`

### Routes à ajouter/vérifier

```dart
MaterialApp(
  title: 'Delivery Express Mobility',
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2196F3),
    ),
  ),
  home: const SplashPage(),
  routes: {
    // ✅ Routes existantes
    '/splash': (_) => const SplashPage(),
    '/onboarding': (_) => const OnboardingPage(),
    
    // ✅ Routes authentification (MVP Phase 1)
    '/login': (_) => const LoginPage(),          // Existants
    '/signup': (_) => const SignupPage(),        // Nouveaux (OTP)
    
    // ✅ Routes Home (selon rôle)
    '/clientHome': (_) => const ClientHomePage(),
    '/livreurHome': (_) => const LivreurHomePage(),
  },
  initialRoute: '/splash',
)
```

---

## 📋 Vérification des routes

### Routes actuelles (à vérifier)
```
Route                  | Purpose                  | Status
-----------------------|--------------------------|--------
/splash                | JWT check + onboarding   | ✅ Exists
/onboarding            | First-launch intro       | ✅ Exists
/login                 | Existing users           | ✅ Exists (refactored)
/signup                | New users (OTP)          | ⚠️ NEEDS ADDING
/clientHome            | Client dashboard         | ✅ Exists
/livreurHome           | Driver dashboard         | ✅ Exists
```

---

## 🔄 Navigation Flow

### 1. Splash → Check JWT
```
SplashPage
  ├─ JWT valid? → fetch role
  │  ├─ role == "CLIENT" → /clientHome
  │  └─ role == "DRIVER" → /livreurHome
  └─ No JWT → /onboarding OR /login
```

### 2. Onboarding → First time only
```
OnboardingPage (shows only on first launch)
  └─ User completes → /login
```

### 3. Login → Existing users
```
LoginPage
  ├─ Input: phone + password
  │  └─ AuthLoginEvent
  │     └─ AuthSuccess(role)
  │        ├─ role == "CLIENT" → /clientHome
  │        └─ role == "DRIVER" → /livreurHome
  │
  └─ Link: "Créer un compte" → /signup
```

### 4. Signup → New users (OTP)
```
SignupPage
  ├─ Step 1: Phone + Role selection
  │  └─ "Recevoir OTP" button
  │     └─ AuthSendOtpEvent
  │        └─ Show OTPVerificationWidget
  │
  ├─ Step 2: OTP Verification
  │  ├─ Input: 4 OTP digits
  │  │  └─ "Vérifier" button
  │  │     └─ AuthVerifyOtpEvent
  │  │        └─ AuthSuccess(role)
  │  │           ├─ role == "CLIENT" → /clientHome
  │  │           └─ role == "DRIVER" → /livreurHome
  │  │
  │  └─ Back: "← Retour" button → back to Step 1
  │
  └─ Link: "Vous avez un compte ?" → /login
```

---

## 🔗 Route imports in main.dart

Make sure these imports are present:

```dart
// Splash & Onboarding
import 'package:delivery_express_mobility_frontend/pages/splash_page.dart';
import 'package:delivery_express_mobility_frontend/pages/onboarding_page.dart';

// Auth Pages
import 'package:delivery_express_mobility_frontend/pages/login_page.dart';
import 'package:delivery_express_mobility_frontend/pages/signup_page.dart';

// Home Pages
import 'package:delivery_express_mobility_frontend/pages/client_home_page.dart';
import 'package:delivery_express_mobility_frontend/pages/livreur_home_page.dart';
```

---

## ✅ Main.dart Template

Here's the complete `main()` function structure:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize DI (GetIt service locator)
  await setupServiceLocator();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Delivery Express Mobility',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
        ),
      ),
      // ✅ Routes definition
      routes: {
        '/splash': (_) => const SplashPage(),
        '/onboarding': (_) => const OnboardingPage(),
        '/login': (_) => const LoginPage(),
        '/signup': (_) => const SignupPage(),        // ← MUST ADD
        '/clientHome': (_) => const ClientHomePage(),
        '/livreurHome': (_) => const LivreurHomePage(),
      },
      // ✅ Initial entry point
      initialRoute: '/splash',
      home: const SplashPage(),
    );
  }
}
```

---

## 🧪 Route Testing

### Test all routes navigate correctly

```dart
// Test 1: Splash → Login
test('Navigation: Splash to Login', () async {
  // Should show LoginPage after splash
});

// Test 2: Login → Signup
test('Navigation: Login to Signup', () async {
  // Click "Créer un compte" → route to /signup
});

// Test 3: Signup → Home (CLIENT)
test('Navigation: Signup to ClientHome', () async {
  // Complete signup as CLIENT → route to /clientHome
});

// Test 4: Signup → Home (DRIVER)
test('Navigation: Signup to DriverHome', () async {
  // Complete signup as DRIVER → route to /livreurHome
});

// Test 5: Login → Home
test('Navigation: Login to Home', () async {
  // Login existing user → route based on role
});
```

---

## ⚠️ Important Notes

1. **Routes are case-sensitive** → '/signup' NOT '/SignUp'
2. **Must import all pages** before using in routes
3. **initialRoute must exist** in routes map
4. **SplashPage is home entry point** → should check JWT and redirect
5. **Routes use named navigation** → `Navigator.pushReplacementNamed(context, '/signup')`

---

## 🔍 Debugging Routes

If routes don't work:

1. **Check imports** → All pages must be imported in main.dart
2. **Check spelling** → '/signup' vs '/SignUp' vs '/signUp'
3. **Check routes map** → All routes must be defined
4. **Check initialRoute** → Should match a route in the map
5. **Check navigation calls** → Use correct route name in Navigator calls

```dart
// ✅ Correct
Navigator.pushReplacementNamed(context, '/signup');

// ❌ Wrong
Navigator.pushReplacementNamed(context, '/SignUp');
Navigator.pushReplacementNamed(context, 'signup');
Navigator.pushReplacementNamed(context, '/signup/');
```

---

## 📝 Checklist

- [ ] Import all 6 pages in main.dart
- [ ] Define all 6 routes in MaterialApp
- [ ] Set initialRoute to '/splash'
- [ ] Test all navigation paths
- [ ] Verify no route conflicts
- [ ] Run `flutter analyze` (no errors)
- [ ] Test on device/emulator

---

**Status**: ⏳ Waiting for routes to be added to main.dart  
**Blocker**: `/signup` route must be added  
**Estimated time to fix**: 2 minutes
