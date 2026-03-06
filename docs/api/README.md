# 📚 API Documentation - DEM Delivery Backend

Documentation complète des endpoints pour le développement du frontend.

## 📋 Index

1. [Authentication](./authentication.md)
2. [Users](./users.md)
3. [Deliveries](./deliveries.md)
4. [Drivers](./drivers.md)
5. [Payments](./payments.md)
6. [Passes](./passes.md)
7. [Promo Codes](./promo-codes.md)
8. [Health & Monitoring](./health-monitoring.md)
9. [Error Responses](./error-responses.md)
10. [Rate Limiting](./rate-limiting.md)

---

## 🔌 Base URL

**Production:** `https://dem-delivery-backend.onrender.com`

---

## 🔐 Authentication

Tous les endpoints protégés nécessitent le header:
```
Authorization: Bearer {accessToken}
```

Le token `accessToken` est obtenu après login ou inscription + vérification OTP.

---

## 📝 Conventions

- Tous les requêtes utilisent `Content-Type: application/json`
- Les réponses sont au format JSON
- Les erreurs suivent un format standardisé (voir [Error Responses](./error-responses.md))
- Les timestamps sont au format ISO 8601

---

**Last Updated:** 3 Mars 2026
