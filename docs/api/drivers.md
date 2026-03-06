# 🛵 Drivers

## GET /drivers/me/profile
**Profil du livreur**

**Headers:**
```
Authorization: Bearer {accessToken}
```

**Response (200):**
```json
{
  "message": "Driver profile retrieved",
  "data": {
    "id": "driver-uuid-5678",
    "fullName": "Ahmed Sarr",
    "phone": "+221771234568",
    "email": "ahmed@example.com",
    "avatarUrl": "https://cdn.example.com/driver.jpg",
    "rating": 4.8,
    "ratingCount": 156,
    "completedDeliveries": 342,
    "totalEarnings": 125000,
    "kycStatus": "APPROVED",
    "verificationDeadline": null,
    "dailyDeliveriesLimit": 20,
    "currentDeliveriesToday": 5,
    "hasActivePass": true,
    "passExpiresAt": "2026-04-03T00:00:00.000Z",
    "createdAt": "2025-09-15T10:00:00.000Z"
  }
}
```

---

## PATCH /drivers/me/profile
**Mettre à jour le profil du livreur**

**Request Body:**
```json
{
  "fullName": "Ahmed Sarr Updated",
  "avatarUrl": "https://cdn.example.com/new-avatar.jpg",
  "email": "newemail@example.com"
}
```

**Response (200):**
```json
{
  "message": "Driver profile updated",
  "data": {
    "id": "driver-uuid-5678",
    "fullName": "Ahmed Sarr Updated"
  }
}
```

---

## GET /drivers/me/statistics
**Statistiques du livreur**

**Response (200):**
```json
{
  "message": "Driver statistics",
  "data": {
    "totalDeliveries": 342,
    "completedDeliveries": 340,
    "cancelledDeliveries": 2,
    "averageRating": 4.8,
    "totalEarnings": 125000,
    "earningsThisMonth": 18500,
    "earningsThisWeek": 4200,
    "acceptanceRate": 98.5,
    "cancellationRate": 0.6,
    "onTimeDeliveryRate": 97.3,
    "averageDeliveryTime": 28,
    "topRatedFeature": "politeness",
    "lastDeliveryAt": "2026-03-03T21:45:00.000Z"
  }
}
```

---

## GET /drivers/me/available-deliveries
**Lister les livraisons disponibles**

**Query Parameters:**
```
?latitude=14.6928&longitude=-17.0469&radius=5&limit=10&status=PENDING
```

**Response (200):**
```json
{
  "message": "Available deliveries",
  "data": [
    {
      "id": "delivery-uuid-1234",
      "clientName": "John Doe",
      "pickupAddress": "Bd de la République, Dakar",
      "deliveryAddress": "Avenue Cheikh Anta Diop, Dakar",
      "distance": 2.3,
      "estimatedPrice": 2500,
      "packageType": "document",
      "weight": 0.5,
      "clientRating": 4.7,
      "createdAt": "2026-03-03T21:10:21.311Z"
    }
  ],
  "pagination": {
    "total": 15,
    "page": 1,
    "limit": 10
  }
}
```

---

## POST /drivers/me/accept-delivery/:id
**Accepter une livraison**

**Request Body:**
```json
{
  "latitude": 14.6928,
  "longitude": -17.0469,
  "estimatedArrivalTime": "2026-03-03T21:35:00.000Z"
}
```

**Response (200):**
```json
{
  "message": "Delivery accepted",
  "data": {
    "id": "delivery-uuid-1234",
    "status": "ASSIGNED",
    "driverId": "driver-uuid-5678",
    "assignedAt": "2026-03-03T21:15:00.000Z"
  }
}
```

---

## POST /drivers/me/reject-delivery/:id
**Rejeter une livraison**

**Request Body:**
```json
{
  "reason": "Too far away",
  "description": "Outside my usual service area"
}
```

**Response (200):**
```json
{
  "message": "Delivery rejected",
  "data": {
    "id": "delivery-uuid-1234",
    "rejectedAt": "2026-03-03T21:15:00.000Z"
  }
}
```
