# 💰 Payments

## POST /payments
**Initier un paiement**

**Headers:**
```
Authorization: Bearer {accessToken}
Content-Type: application/json
```

**Request Body:**
```json
{
  "deliveryId": "delivery-uuid-1234",
  "amount": 2500,
  "paymentMethod": "orange_money",
  "phoneNumber": "+221771234567"
}
```

**Response (201):**
```json
{
  "message": "Payment initiated",
  "data": {
    "id": "payment-uuid-9876",
    "deliveryId": "delivery-uuid-1234",
    "amount": 2500,
    "currency": "XOF",
    "status": "PENDING",
    "paymentMethod": "orange_money",
    "transactionId": "OMM123456789",
    "redirectUrl": "https://payment-gateway.com/confirm",
    "createdAt": "2026-03-03T21:10:21.311Z"
  },
  "nextStep": "CONFIRM_PAYMENT"
}
```

---

## POST /payments/:id/confirm
**Confirmer un paiement**

**Request Body:**
```json
{
  "confirmationCode": "123456",
  "transactionId": "OMM123456789"
}
```

**Response (200):**
```json
{
  "message": "Payment confirmed",
  "data": {
    "id": "payment-uuid-9876",
    "status": "COMPLETED",
    "amount": 2500,
    "confirmedAt": "2026-03-03T21:15:00.000Z"
  }
}
```

---

## GET /payments
**Lister les paiements de l'utilisateur**

**Query Parameters:**
```
?status=COMPLETED&limit=10&page=1&sortBy=createdAt&order=DESC
```

**Response (200):**
```json
{
  "message": "Payments retrieved",
  "data": [
    {
      "id": "payment-uuid-9876",
      "amount": 2500,
      "status": "COMPLETED",
      "paymentMethod": "orange_money",
      "createdAt": "2026-03-03T21:15:00.000Z"
    }
  ],
  "pagination": {
    "total": 45,
    "page": 1,
    "limit": 10,
    "totalPages": 5
  }
}
```
