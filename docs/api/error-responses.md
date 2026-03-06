# ❌ Error Responses

## Erreur 400 - Bad Request
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request parameters",
    "details": [
      "phone must be a valid phone number",
      "password must be at least 8 characters"
    ]
  },
  "statusCode": 400,
  "timestamp": "2026-03-03T21:10:21.311Z"
}
```

---

## Erreur 401 - Unauthorized
```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Invalid or expired token"
  },
  "statusCode": 401,
  "timestamp": "2026-03-03T21:10:21.311Z"
}
```

---

## Erreur 403 - Forbidden
```json
{
  "success": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "Access denied - insufficient permissions"
  },
  "statusCode": 403,
  "timestamp": "2026-03-03T21:10:21.311Z"
}
```

---

## Erreur 404 - Not Found
```json
{
  "success": false,
  "error": {
    "code": "NOT_FOUND",
    "message": "Resource not found"
  },
  "statusCode": 404,
  "timestamp": "2026-03-03T21:10:21.311Z"
}
```

---

## Erreur 500 - Internal Server Error
```json
{
  "success": false,
  "error": {
    "code": "INTERNAL_SERVER_ERROR",
    "message": "Une erreur interne s'est produite"
  },
  "statusCode": 500,
  "timestamp": "2026-03-03T21:10:21.311Z",
  "requestId": "abc-123-def"
}
```
