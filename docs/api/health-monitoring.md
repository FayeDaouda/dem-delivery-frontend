# 🏥 Health & Monitoring

## GET /health
**Vérifier la santé du service**

**Response (200):**
```json
{
  "status": "UP",
  "timestamp": "2026-03-03T21:10:21.311Z",
  "checks": {
    "redis": {
      "status": "up",
      "connected": true,
      "message": "Redis is healthy"
    },
    "postgres": {
      "status": "up",
      "connected": true,
      "message": "PostgreSQL is healthy",
      "latencyMs": 5
    },
    "queue": {
      "connected": true,
      "latencyMs": 2,
      "queues": {
        "otp": {
          "waiting": 0,
          "active": 0,
          "failed": 0
        },
        "email": {
          "waiting": 2,
          "active": 1,
          "failed": 0
        },
        "notification": {
          "waiting": 0,
          "active": 0,
          "failed": 0
        }
      }
    }
  }
}
```

---

## GET /health/live
**Simple liveness check**

**Response (200):**
```json
{
  "status": "UP",
  "timestamp": "2026-03-03T21:10:21.311Z"
}
```
