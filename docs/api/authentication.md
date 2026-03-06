# 🔐 Authentication

## POST /auth/user/register
**Inscription unifiée (CLIENT ou DRIVER)**

**Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "phone": "+221771234567",
  "password": "Test@1234",
  "fullName": "John Doe",
  "role": "CLIENT"  // ou "DRIVER"
}
```

**Response (201):**
```json
{
  "message": "Client registered, OTP sent",
  "data": {
    "id": "5b1c9886-28fd-4719-a6be-19310512fc9a",
    "fullName": "John Doe",
    "phone": "+221771234567",
    "avatarUrl": null,
    "preferredLanguage": "fr",
    "referralCode": "CE32DF51",
    "role": "CLIENT",
    "status": "PENDING_OTP",
    "isVerified": false,
    "createdAt": "2026-03-03T21:10:21.311Z",
    "updatedAt": "2026-03-03T21:10:21.311Z"
  },
  "otp": {
    "channel": "sms",
    "codeLength": 4,
    "expiresInSeconds": 300,
    "autofill": {
      "enabled": true,
      "inputHint": "one-time-code",
      "androidSmsRetrieverFormat": true
    },
    "smsTemplate": "<#> Dakar Speed Pro: votre code est {code}. Ne le partagez jamais."
  },
  "nextStep": "VERIFY_OTP"
}
```

---

## POST /auth/user/login
**Login unifié (tous les rôles)**

**Request Body:**
```json
{
  "phone": "+221771234567",
  "password": "Test@1234"
}
```

**Response (200):**
```json
{
  "message": "Login successful",
  "role": "CLIENT",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 900
  }
}
```

---

## POST /auth/verify-otp
**Vérifier le code OTP après inscription**

**Request Body:**
```json
{
  "phone": "+221771234567",
  "code": "1234"
}
```

**Response (200):**
```json
{
  "message": "OTP verified",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 900,
    "user": {
      "id": "5b1c9886-28fd-4719-a6be-19310512fc9a",
      "phone": "+221771234567",
      "role": "CLIENT",
      "isVerified": true
    }
  }
}
```

---

## POST /auth/refresh-token
**Rafraîchir les tokens**

**Headers:**
```
Authorization: Bearer {refreshToken}
```

**Response (200):**
```json
{
  "message": "Token refreshed",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 900
  }
}
```

---

## POST /auth/logout
**Déconnexion**

**Headers:**
```
Authorization: Bearer {accessToken}
```

**Response (200):**
```json
{
  "message": "Logout successful"
}
```
