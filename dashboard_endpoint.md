# `/contacts/dashboard/statistics` Endpoint - Complete Guide

## Overview

The [`GET /contacts/dashboard/statistics`](app/routers/contacts.py:423) endpoint returns comprehensive dashboard statistics for the church contact management system. It provides tag-based categorization and contact activity counts.

---

## Request

### Endpoint
```
GET /contacts/dashboard/statistics
```

### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date_from` | `datetime` | No | Start date for filtering (ISO 8601 format). Examples: `2024-01-01`, `2024-01-01T00:00:00Z` |
| `date_to` | `datetime` | No | End date for filtering (ISO 8601 format). Examples: `2024-01-31`, `2024-01-31T23:59:59Z` |

### Behavior
- **No parameters**: Returns new/modified contact counts for ALL time (from 1970-01-01)
- **With parameters**: Returns counts filtered by the specified date range

### Example Requests

```dart
// No date filter (all-time counts)
GET /contacts/dashboard/statistics

// With date range
GET /contacts/dashboard/statistics?date_from=2024-01-01&date_to=2024-01-31

// With only start date
GET /contacts/dashboard/statistics?date_from=2024-01-01

// With only end date
GET /contacts/dashboard/statistics?date_to=2024-12-31
```

---

## Response

### Response Model

```json
{
  "total_contacts": 230,
  "new_contacts": {
    "count": 25,
    "date_from": "2024-01-01",
    "date_to": "2024-01-31"
  },
  "modified_contacts": {
    "count": 10,
    "date_from": "2024-01-01",
    "date_to": "2024-01-31"
  },
  "locations": {
    "kanana": 45,
    "majaneng": 32,
    "mashemong": 28,
    "soshanguve": 15,
    "kekana": 10,
    "pretoria": 8,
    "custom_location_1": 5
  },
  "roles": {
    "pastor": 3,
    "protocol": 5,
    "worshiper": 150,
    "usher": 12,
    "financier": 4,
    "servant": 20
  },
  "membership": {
    "member": 180,
    "non_member": 50
  }
}
```

### Response Fields Explained

| Field | Type | Description |
|-------|------|-------------|
| `total_contacts` | `int` | Total number of contacts in the database |
| `new_contacts` | `object` | Count of contacts created within date range |
| `modified_contacts` | `object` | Count of contacts updated (excluding new) within date range |
| `locations` | `object` | Tag counts for location-based tags |
| `roles` | `object` | Tag counts for role-based tags |
| `membership` | `object` | Member vs non-member counts |

---

## Tag Categorization Rules

### 1. Location Tags
- **Hardcoded locations**: `kanana`, `majaneng`, `mashemong`, `soshanguve`, `kekana`
- **Dynamic locations**: Any other tag that is NOT in the roles list AND NOT `member`

### 2. Role Tags (Fixed Set)
- `pastor`
- `protocol`
- `worshiper`
- `usher`
- `financier`
- `servant`

### 3. Membership
- **member**: Contacts with `member` tag in their tags
- **non_member**: Contacts WITHOUT `member` tag

---

## Authentication

This endpoint requires authentication via the `Authorization` header:
```
Authorization: Bearer <your_jwt_token>
```