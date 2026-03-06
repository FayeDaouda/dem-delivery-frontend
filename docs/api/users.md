# 👤 Users

## GET /users/me
**Récupérer le profil de l'utilisateur connecté**

**Headers:**
```
Authorization: Bearer {accessToken}
```

**Response (200):**
```json
{
  "message": "Profile retrieved",
  "data": {
    "id": "5b1c9886-28fd-4719-a6be-19310512fc9a",
    "fullName": "John Doe",
    "phone": "+221771234567",
    "avatarUrl": "https://cdn.example.com/avatar.jpg",
    "preferredLanguage": "fr",
    "role": "CLIENT",
    "status": "ACTIVE",
    "isVerified": true,
    "rating": "4.5",
    "ratingCount": 12,
    "completedDeliveries": 25,
    "createdAt": "2026-03-03T21:10:21.311Z",
    "updatedAt": "2026-03-03T21:10:21.311Z"
  }
}
```

---

## PATCH /users/me
**Modifier le profil**

**Headers:**
```
Authorization: Bearer {accessToken}
Content-Type: application/json
```

**Request Body:**
```json
{
  "fullName": "John Updated",
  "avatarUrl": "https://cdn.example.com/new-avatar.jpg"
}
```

**Response (200):**
```json
{
  "message": "Profile updated",
  "data": {
    "id": "5b1c9886-28fd-4719-a6be-19310512fc9a",
    "fullName": "John Updated",
    "avatarUrl": "https://cdn.example.com/new-avatar.jpg"
  }
}
```

---

## PATCH /users/me/language
**Changer la langue préférée**

**Request Body:**
```json
{
  "preferredLanguage": "en"  // ou "fr"
}
```

**Response (200):**
```json
{
  "message": "Language updated",
  "data": {
    "id": "5b1c9886-28fd-4719-a6be-19310512fc9a",
    "preferredLanguage": "en"
  }
}
```
