# 🎫 Passes

## GET /passes
**Lister les passes disponibles**

**Headers:**
```
Authorization: Bearer {accessToken}
```

**Response (200):**
```json
{
  "message": "Passes retrieved",
  "data": [
    {
      "id": "pass-uuid-1",
      "name": "Pass Gold",
      "description": "Unlimited deliveries for 30 days",
      "price": 15000,
      "currency": "XOF",
      "duration": 30,
      "durationUnit": "days",
      "maxDeliveries": null,
      "discountPercentage": 10,
      "features": [
        "Unlimited deliveries",
        "Priority assignment",
        "Insurance included"
      ],
      "createdAt": "2025-01-01T00:00:00.000Z"
    }
  ]
}
```

---

## POST /passes/:id/purchase
**Acheter un pass**

**Request Body:**
```json
{
  "paymentMethod": "orange_money",
  "phoneNumber": "+221771234567"
}
```

**Response (201):**
```json
{
  "message": "Pass purchased",
  "data": {
    "id": "pass-purchase-uuid",
    "passId": "pass-uuid-1",
    "driverId": "driver-uuid-5678",
    "expiresAt": "2026-04-03T00:00:00.000Z",
    "status": "ACTIVE",
    "purchasedAt": "2026-03-03T21:10:21.311Z"
  }
}
```

---

## GET /passes/me/active
**Obtenir le pass actif du livreur**

**Response (200):**
```json
{
  "message": "Active pass retrieved",
  "data": {
    "id": "pass-purchase-uuid",
    "passName": "Pass Gold",
    "expiresAt": "2026-04-03T00:00:00.000Z",
    "daysRemaining": 31,
    "status": "ACTIVE",
    "features": [
      "Unlimited deliveries",
      "Priority assignment",
      "Insurance included"
    ]
  }
}
```
