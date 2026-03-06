# 📦 Deliveries

## POST /deliveries
**Créer une nouvelle livraison (CLIENT)**

**Headers:**
```
Authorization: Bearer {accessToken}
Content-Type: application/json
```

**Request Body:**
```json
{
  "pickupAddress": "Bd de la République, Dakar",
  "pickupLat": 14.6928,
  "pickupLng": -17.0469,
  "deliveryAddress": "Avenue Cheikh Anta Diop, Dakar",
  "deliveryLat": 14.7167,
  "deliveryLng": -17.4667,
  "packageType": "document",
  "weight": 0.5,
  "estimatedSize": "small",
  "description": "Important documents",
  "paymentMethod": "cash",
  "destinationPhone": "+221771234568"
}
```

**Response (201):**
```json
{
  "message": "Delivery created",
  "data": {
    "id": "delivery-uuid-1234",
    "clientId": "client-uuid",
    "status": "PENDING",
    "pickupAddress": "Bd de la République, Dakar",
    "deliveryAddress": "Avenue Cheikh Anta Diop, Dakar",
    "estimatedPrice": 2500,
    "packageType": "document",
    "createdAt": "2026-03-03T21:10:21.311Z"
  },
  "nextStep": "AWAITING_DRIVER_ASSIGNMENT"
}
```

---

## GET /deliveries/:id
**Récupérer les détails d'une livraison**

**Headers:**
```
Authorization: Bearer {accessToken}
```

**Response (200):**
```json
{
  "message": "Delivery retrieved",
  "data": {
    "id": "delivery-uuid-1234",
    "clientId": "client-uuid",
    "driverId": "driver-uuid-5678",
    "status": "IN_PROGRESS",
    "pickupAddress": "Bd de la République, Dakar",
    "deliveryAddress": "Avenue Cheikh Anta Diop, Dakar",
    "estimatedPrice": 2500,
    "actualPrice": 2500,
    "driver": {
      "id": "driver-uuid-5678",
      "fullName": "Ahmed Sarr",
      "phone": "+221771234568",
      "avatarUrl": "https://cdn.example.com/driver.jpg",
      "rating": 4.8,
      "vehicleType": "moto"
    },
    "createdAt": "2026-03-03T20:00:00.000Z",
    "updatedAt": "2026-03-03T21:10:21.311Z"
  }
}
```

---

## GET /deliveries
**Lister les livraisons de l'utilisateur**

**Headers:**
```
Authorization: Bearer {accessToken}
```

**Query Parameters:**
```
?status=PENDING&limit=10&page=1&sortBy=createdAt&order=DESC
```

**Response (200):**
```json
{
  "message": "Deliveries retrieved",
  "data": [
    {
      "id": "delivery-uuid-1234",
      "status": "PENDING",
      "pickupAddress": "Bd de la République, Dakar",
      "deliveryAddress": "Avenue Cheikh Anta Diop, Dakar",
      "estimatedPrice": 2500,
      "createdAt": "2026-03-03T21:10:21.311Z"
    }
  ],
  "pagination": {
    "total": 25,
    "page": 1,
    "limit": 10,
    "totalPages": 3
  }
}
```

---

## POST /deliveries/:id/pickup
**Marquer une livraison comme prise (DRIVER)**

**Headers:**
```
Authorization: Bearer {accessToken}
Content-Type: application/json
```

**Request Body:**
```json
{
  "latitude": 14.6928,
  "longitude": -17.0469,
  "photos": ["photo-url-1", "photo-url-2"]
}
```

**Response (200):**
```json
{
  "message": "Delivery picked up",
  "data": {
    "id": "delivery-uuid-1234",
    "status": "PICKED_UP",
    "pickedUpAt": "2026-03-03T21:15:00.000Z"
  }
}
```

---

## POST /deliveries/:id/deliver
**Marquer une livraison comme livrée (DRIVER)**

**Headers:**
```
Authorization: Bearer {accessToken}
Content-Type: application/json
```

**Request Body:**
```json
{
  "latitude": 14.7167,
  "longitude": -17.4667,
  "signatureUrl": "signature-image-url",
  "recipientName": "Jean Dupont",
  "photos": ["delivery-photo-1"]
}
```

**Response (200):**
```json
{
  "message": "Delivery completed",
  "data": {
    "id": "delivery-uuid-1234",
    "status": "DELIVERED",
    "deliveredAt": "2026-03-03T21:45:00.000Z",
    "actualPrice": 2500
  }
}
```

---

## POST /deliveries/:id/cancel
**Annuler une livraison**

**Headers:**
```
Authorization: Bearer {accessToken}
Content-Type: application/json
```

**Request Body:**
```json
{
  "reason": "Client is not available",
  "description": "No one answered the phone"
}
```

**Response (200):**
```json
{
  "message": "Delivery cancelled",
  "data": {
    "id": "delivery-uuid-1234",
    "status": "CANCELLED",
    "cancelledAt": "2026-03-03T21:20:00.000Z",
    "refundAmount": 2500
  }
}
```

---

## POST /deliveries/:id/rate-driver
**Évaluer un livreur (CLIENT)**

**Request Body:**
```json
{
  "rating": 5,
  "comment": "Excellent service, very professional",
  "tags": ["fast", "polite", "careful"]
}
```

**Response (200):**
```json
{
  "message": "Driver rated successfully",
  "data": {
    "deliveryId": "delivery-uuid-1234",
    "driverId": "driver-uuid-5678",
    "rating": 5,
    "comment": "Excellent service, very professional"
  }
}
```

---

## GET /deliveries/:id/track
**Suivi temps réel (CLIENT)**

**Response (200):**
```json
{
  "message": "Delivery tracking",
  "data": {
    "id": "delivery-uuid-1234",
    "status": "IN_PROGRESS",
    "driverLocation": {
      "latitude": 14.7000,
      "longitude": -17.0500,
      "updatedAt": "2026-03-03T21:15:00.000Z"
    },
    "estimatedArrival": "2026-03-03T21:45:00.000Z",
    "driver": {
      "id": "driver-uuid-5678",
      "fullName": "Ahmed Sarr",
      "phone": "+221771234568",
      "avatarUrl": "https://cdn.example.com/driver.jpg"
    }
  }
}
```
