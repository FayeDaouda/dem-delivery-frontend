# 🎁 Promo Codes

## POST /promo-codes/validate
**Valider un code promo**

**Headers:**
```
Authorization: Bearer {accessToken}
Content-Type: application/json
```

**Request Body:**
```json
{
  "code": "WELCOME2024",
  "deliveryId": "delivery-uuid-1234",
  "amount": 2500
}
```

**Response (200):**
```json
{
  "message": "Promo code validated",
  "data": {
    "code": "WELCOME2024",
    "discountType": "percentage",
    "discountValue": 10,
    "maxDiscount": 500,
    "applicableDiscount": 250,
    "finalAmount": 2250,
    "description": "Welcome offer: 10% off"
  }
}
```

---

## POST /promo-codes/apply
**Appliquer un code promo**

**Request Body:**
```json
{
  "code": "WELCOME2024",
  "deliveryId": "delivery-uuid-1234"
}
```

**Response (200):**
```json
{
  "message": "Promo code applied",
  "data": {
    "deliveryId": "delivery-uuid-1234",
    "appliedDiscount": 250,
    "newAmount": 2250,
    "promoCode": "WELCOME2024"
  }
}
```
