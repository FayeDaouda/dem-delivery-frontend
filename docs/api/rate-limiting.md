# ⏱️ Rate Limiting

## Limites par catégorie

| Catégorie | Limite | Période |
|-----------|--------|---------|
| Authentication | 5 requests | 60 secondes par IP |
| General API | 100 requests | 1 minute par utilisateur |
| File Upload | 10 requests | 1 minute par utilisateur |
| Admin Actions | 50 requests | 1 minute par admin |

---

## Réponse lors du dépassement

Quand la limite est dépassée, vous recevrez une réponse 429:

```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests, please try again later"
  },
  "statusCode": 429,
  "timestamp": "2026-03-03T21:10:21.311Z",
  "retryAfter": 60
}
```

### Headers de rate limiting

Les réponses incluent les headers suivants:

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1646432821
```

---

## Recommandations

- Implémentez une stratégie de retry avec backoff exponentiel
- Conservez les headers `X-RateLimit-*` pour adapter votre stratégie
- Groupez les requêtes quand possible pour réduire le nombre d'appels
