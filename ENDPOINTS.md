# Attendance & Scenarios API Endpoints

This document provides a comprehensive guide to the Attendance and Scenario API endpoints, their functionalities, and authorization requirements.

## Authentication & Authorization

All endpoints in this document **require a valid Bearer token** in the Authorization header, except for the authentication endpoints (`/auth/login` and `/auth/register`).

**Header Format:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

### User Roles
The system supports the following user roles:
- `super_admin` - Full system access
- `secretary` - Manage communications, contacts
- `it_admin` - Technical administration
- `servant` - Attendance recording, task completion

**Note:** Currently, any active user can access these endpoints. Role-based restrictions can be added in `app/dependencies.py` if needed.

---

# Authentication

After a successful login or registration, you will receive an `access_token`. This token must be included in the `Authorization` header of subsequent requests to protected endpoints. The format should be `Authorization: Bearer YOUR_ACCESS_TOKEN`.

All endpoints require a valid `Bearer` token in the `Authorization` header, except for the `/auth/login` and `/auth/register` endpoints.

### `POST /auth/login`

Authenticates a user and returns an access token.

**Request Body (form-data):**

- `username`: The user's email address.
- `password`: The user's password.

**Example using `curl`:**

```bash
curl -X POST "http://your-api-url/auth/login" \
-H "Content-Type: application/x-www-form-urlencoded" \
-d "username=user@example.com&password=your_password"
```

**Response:**

```json
{
  "access_token": "your_access_token",
  "token_type": "bearer",
  "refresh_token": "your_refresh_token"
}
```

**Example of using the obtained token:**

```bash
# Assuming you stored the access_token in a variable
ACCESS_TOKEN="your_access_token"

curl -X GET "http://your-api-url/auth/me" \
-H "Authorization: Bearer $ACCESS_TOKEN"
```

### `POST /auth/register`

Registers a new user.

**Request Body:**

```json
{
  "email": "user@example.com",
  "password": "your_password",
  "role": "super_admin",
  "is_active": true
}
```

**Response:**

```json
{
    "email": "juniorbypassfrp@gmail.com",
    "role": "admin",
    "is_active": true,
    "id": 4,
    "created_at": "2025-07-18T23:28:55.533033Z",
    "access_token": "your_access_token",
    "token_type": "bearer"
}
```

For a successful registration, the backend is expected to return a JSON object containing:

- `access_token`: A string representing the authentication token.
- `token_type`: A string indicating the type of token (e.g., "Bearer").

**Example of using the obtained token:**

```bash
# Assuming you stored the access_token in a variable
ACCESS_TOKEN="your_access_token"

curl -X GET "http://your-api-url/auth/me" \
-H "Authorization: Bearer $ACCESS_TOKEN"
```

### `POST /auth/refresh`

Refreshes an access token using a refresh token.

**Request Body (JSON):**

```json
{
  "refresh_token": "your_refresh_token_here"
}
```

**Response:**

```json
{
  "access_token": "your_new_access_token",
  "token_type": "bearer"
}
```

### `GET /auth/me`

Returns the currently authenticated user's information.

**Response:**

The user object.

## Attendance Endpoints

### `POST /attendance/record`

Records attendance for a contact. Prevents duplicate check-ins for the same service on the same day.

**Headers:**
- `Authorization: Bearer YOUR_ACCESS_TOKEN`
- `Content-Type: application/json`

**Request Body:**
```json
{
  "contact_id": 123,
  "phone": "+27821234567",
  "service_type": "Sunday",
  "service_date": "2024-01-14T09:00:00Z",
  "recorded_by": 1
}
```

**Service Types:**
- `Sunday` - Sunday Service
- `Tuesday` - Tuesday Service
- `Special Event` - Special Event

**Example using curl:**
```bash
curl -X POST "http://your-api-url/attendance/record" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "contact_id": 123,
    "phone": "+27821234567",
    "service_type": "Sunday",
    "service_date": "2024-01-14T09:00:00Z",
    "recorded_by": 1
  }'
```

**Success Response (201):**
```json
{
  "id": 1,
  "contact_id": 123,
  "phone": "+27821234567",
  "service_type": "Sunday",
  "service_date": "2024-01-14T09:00:00Z",
  "recorded_by": 1,
  "recorded_at": "2024-01-14T10:30:00Z"
}
```

**Error Response (400) - Duplicate:**
```json
{
  "detail": "Attendance already recorded for this contact on 2024-01-14 for Sunday"
}
```

---

### `GET /attendance/records`

Retrieves attendance records with optional filters.

**Headers:**
- `Authorization: Bearer YOUR_ACCESS_TOKEN`

**Query Parameters (all optional):**
- `date_from` - Filter from date (ISO 8601 format)
- `date_to` - Filter to date (ISO 8601 format)
- `service_type` - Filter by service type
- `contact_id` - Filter by contact ID

**Example:**
```bash
curl -X GET "http://your-api-url/attendance/records?service_type=Sunday&date_from=2024-01-01T00:00:00Z" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Success Response (200):**
```json
[
  {
    "id": 1,
    "contact_id": 123,
    "phone": "+27821234567",
    "service_type": "Sunday",
    "service_date": "2024-01-14T09:00:00Z",
    "recorded_by": 1,
    "recorded_at": "2024-01-14T10:30:00Z"
  }
]
```

---

### `GET /contacts/`

Returns a list of all contacts.


**Query Parameters:**

- `skip`: The number of contacts to skip.
- `limit`: The maximum number of contacts to return.
- `search`: Optional. Search term for name or phone.
- `status`: Optional. Filter by contact status (e.g., 'active', 'inactive', 'lead', 'customer').
- `tags`: Optional. Filter contacts by tags (e.g., `?tags=lead&tags=customer`).
**Response:**

A list of contact objects.

### `GET /attendance/summary`

Gets attendance summary statistics.

**Headers:**
- `Authorization: Bearer YOUR_ACCESS_TOKEN`

**Query Parameters (all optional):**
- `date_from` - Filter from date
- `date_to` - Filter to date

**Example:**
```bash
curl -X GET "http://your-api-url/attendance/summary?date_from=2024-01-01T00:00:00Z" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Success Response (200):**
```json
{
  "total_attendance": 150,
  "by_service_type": {
    "Sunday": 100,
    "Tuesday": 40,
    "Special Event": 10
  }
}
```


### `POST /contacts/add-list`

Adds a list of contacts. This endpoint is suitable for manually adding multiple contacts via a JSON array.


**Request Body:**

```json
{
  "contacts": [
    {
      "name": "Alice Smith",
      "phone": "27712345678",
      "status": "active"
    },
    {
      "name": "Bob Johnson",
      "phone": "0601234567",
      "status": "lead"
    },
    {
      "name": "Invalid Number",
      "phone": "12345"
    }
  ]
}
```
*Note: Phone numbers will be automatically formatted to `+27XXXXXXXXX` and validated for South African format. Malformed numbers will be skipped and reported.*

**Response:**

A summary of the import process.

```json
{
  "success": true,
  "imported_count": 2,
  "skipped_count": 1,
  "total_contacts_in_list": 3,
  "errors": [
    {
      "contact": "Invalid Number",
      "error": "Invalid South African phone number length: '12345'. Formatted number '+12345' must be 13 characters long (+27XXXXXXXXX)."
    }
  ],
  "message": "Imported 2 contacts, skipped 1 due to errors or duplicates."
}
```

### `PUT /contacts/{contact_id}`

Updates an existing contact.


**Path Parameters:**

- `contact_id`: The ID of the contact to update.

**Request Body:**

```json
{
  "name": "Jane Doe",
  "status": "inactive",
  "opt_out_sms": true,
  "phone": "0729876543"
}
```
*Note: `name` is now optional. Phone numbers will be automatically formatted to `+27XXXXXXXXX` and validated for South African format.*

**Response:**

The updated contact object.

### `POST /contacts/{contact_id}/tags/add`

Adds tags to a specific contact.

**Path Parameters:**

- `contact_id`: The ID of the contact to update.

**Request Body:**

```json
{
  "tags": ["new_tag", "another_tag"]
}
```

**Response:**

The updated contact object.

### `POST /contacts/{contact_id}/tags/remove`

Removes tags from a specific contact.

**Path Parameters:**

- `contact_id`: The ID of the contact to update.

**Request Body:**

```json
{
  "tags": ["tag_to_remove"]
}
```

**Response:**

The updated contact object.

### `PUT /contacts/{contact_id}/tags`

Sets tags for a contact, replacing all existing tags.

**Path Parameters:**

- `contact_id`: The ID of the contact to update.

**Request Body:**

```json
{
  "tags": ["tag1", "tag2"]
}
```

**Response:**

The updated contact object.

### `GET /contacts/{contact_id}/tags`

Returns tags for a specific contact.

**Path Parameters:**

- `contact_id`: The ID of the contact.

**Response:**

```json
["tag1", "tag2"]
```

### `GET /contacts/tags/all`

Returns all unique tags across all contacts.

**Response:**

```json
["tag1", "tag2", "tag3"]
```

### `GET /contacts/tags/statistics`

Returns tag usage statistics (tag name -> count).

**Response:**

```json
{
  "tag1": 10,
  "tag2": 5
}
```

### `POST /contacts/tags/bulk-add`

Adds tags to multiple contacts.

**Request Body:**

```json
{
  "contact_ids": [1, 2, 3],
  "tags": ["new_tag", "common_tag"]
}
```

**Response:**

```json
{
  "success": true,
  "updated_count": 3,
  "errors": []
}
```

### `POST /contacts/tags/bulk-remove`

Removes tags from multiple contacts.

**Request Body:**

```json
{
  "contact_ids": [1, 2, 3],
  "tags": ["old_tag"]
}
```

**Response:**

```json
{
  "success": true,
  "updated_count": 3,
  "errors": []
}
```


### `POST /contacts/import-vcf-file`

Imports contacts from a VCF file upload.


**Request Body (form-data):**

- `file`: The VCF file to import.

**Response:**

A summary of the import process.

```json
{
  "success": true,
  "imported_count": 50,
  "failed_count": 2,
  "errors": [
    "Card for Jane Doe is missing a phone number.",
    "Error processing phone number +27123456789 for 'John Doe': Contact with phone number +27123456789 already exists."
  ]
}
```

---

### `GET /attendance/contacts/{contact_id}`

Gets all attendance records for a specific contact.

**Headers:**
- `Authorization: Bearer YOUR_ACCESS_TOKEN`

**Path Parameters:**
- `contact_id` - The contact ID

**Example:**
```bash
curl -X GET "http://your-api-url/attendance/contacts/123" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Success Response (200):**
```json
[
  {
    "id": 1,
    "contact_id": 123,
    "phone": "+27821234567",
    "service_type": "Sunday",
    "service_date": "2024-01-14T09:00:00Z",
    "recorded_by": 1,
    "recorded_at": "2024-01-14T10:30:00Z"
  }
]
```

---

### `DELETE /attendance/{attendance_id}`

Deletes an attendance record.

**Headers:**
- `Authorization: Bearer YOUR_ACCESS_TOKEN`

**Path Parameters:**
- `attendance_id` - The attendance record ID

**Example:**
```bash
curl -X DELETE "http://your-api-url/attendance/1" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Success Response (200):**
```json
{
  "message": "Attendance record deleted successfully"
}
```

---

## Scenario Endpoints

### `POST /scenarios/`

Creates a new scenario and automatically generates tasks for contacts matching the filter tags.

**Headers:**
- `Authorization: Bearer YOUR_ACCESS_TOKEN`
- `Content-Type: application/json`

**Request Body:**
```json
{
  "name": "Food Parcel - Kanana",
  "description": "Distribute food parcels to kanana members",
  "filter_tags": ["kanana"],
  "created_by": 1
}
```

**Filter Tags:**
Common tags include: `member`, `servant`, `pastor`, `kanana`, `majaneng`, or any custom tags added to contacts.

**Example:**
```bash
curl -X POST "http://your-api-url/scenarios/" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Food Parcel - Kanana",
    "description": "Distribute food parcels to kanana members",
    "filter_tags": ["kanana"],
    "created_by": 1
  }'
```

**Success Response (201):**
```json
{
  "id": 1,
  "name": "Food Parcel - Kanana",
  "description": "Distribute food parcels to kanana members",
  "filter_tags": ["kanana"],
  "status": "active",
  "created_by": 1,
  "created_at": "2024-01-14T10:30:00Z",
  "completed_at": null
}
```

---

### `GET /scenarios/`

Retrieves all scenarios with optional status filter.

**Headers:**
- `Authorization: Bearer YOUR_ACCESS_TOKEN`

**Query Parameters (optional):**
- `status` - Filter by status: `active` or `completed`

**Example:**
```bash
curl -X GET "http://your-api-url/scenarios/?status=active" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Success Response (200):**
```json
[
  {
    "id": 1,
    "name": "Food Parcel - Kanana",
    "description": "Distribute food parcels to kanana members",
    "filter_tags": ["kanana"],
    "status": "active",
    "created_by": 1,
    "created_at": "2024-01-14T10:30:00Z",
    "completed_at": null
  }
]
```

---

### `GET /scenarios/{scenario_id}`

Gets a single scenario by ID.

**Headers:**
- `Authorization: Bearer YOUR_ACCESS_TOKEN`

**Path Parameters:**
- `scenario_id` - The scenario ID

**Example:**
```bash
curl -X GET "http://your-api-url/scenarios/1" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

### `GET /scenarios/{scenario_id}/tasks`

Gets all tasks for a scenario.

**Headers:**
- `Authorization: Bearer YOUR_ACCESS_TOKEN`

**Path Parameters:**
- `scenario_id` - The scenario ID

**Example:**
```bash
curl -X GET "http://your-api-url/scenarios/1/tasks" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Success Response (200):**
```json
[
  {
    "id": 1,
    "scenario_id": 1,
    "contact_id": 123,
    "phone": "+27821234567",
    "name": "John Doe",
    "is_completed": false,
    "completed_by": null,
    "completed_at": null
  }
]
```

---

### `GET /scenarios/{scenario_id}/statistics`

Gets statistics for a scenario (total tasks, completed, pending, completion percentage).

**Headers:**
- `Authorization: Bearer YOUR_ACCESS_TOKEN`

**Path Parameters:**
- `scenario_id` - The scenario ID

**Example:**
```bash
curl -X GET "http://your-api-url/scenarios/1/statistics" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Success Response (200):**
```json
{
  "scenario_id": 1,
  "scenario_name": "Food Parcel - Kanana",
  "total_tasks": 50,
  "completed_tasks": 30,
  "pending_tasks": 20,
  "completion_percentage": 60.0
}
```

---

### `PUT /scenarios/{scenario_id}/tasks/{task_id}/complete`

Marks a task as completed. When all tasks are completed, the scenario status is automatically set to `completed`.

**Headers:**
- `Authorization: Bearer YOUR_ACCESS_TOKEN`
- `Content-Type: application/json`

**Path Parameters:**
- `scenario_id` - The scenario ID
- `task_id` - The task ID

**Request Body:**
```json
{
  "completed_by": 1
}
```

**Example:**
```bash
curl -X PUT "http://your-api-url/scenarios/1/tasks/1/complete" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"completed_by": 1}'
```

**Success Response (200):**
```json
{
  "message": "Task completed successfully",
  "scenario_completed": false
}
```

**When all tasks are completed:**
```json
{
  "message": "Task completed successfully",
  "scenario_completed": true
}
```

**Error Response (400) - Already completed:**
```json
{
  "detail": "Task is already completed"
}
```

---

### `DELETE /scenarios/{scenario_id}`

Soft deletes a scenario (marks as deleted without removing from database).

**Headers:**
- `Authorization: Bearer YOUR_ACCESS_TOKEN`

**Path Parameters:**
- `scenario_id` - The scenario ID

**Example:**
```bash
curl -X DELETE "http://your-api-url/scenarios/1" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Success Response (200):**
```json
{
  "message": "Scenario deleted successfully"
}
```

---

## Common Error Responses

**401 Unauthorized:**
```json
{
  "detail": "Could not validate credentials"
}
```

**404 Not Found:**
```json
{
  "detail": "Scenario not found"
}
```

**500 Internal Server Error:**
```json
{
  "detail": "Internal server error message"
}
```

---

## Integration Notes for Frontend

1. **QR Code Flow for Attendance:**
   - Scan member's QR code to get their phone number
   - Look up contact by phone to get `contact_id`
   - Call `/attendance/record` with the contact details

2. **Service Types:**
   - The app should present service type as a dropdown with: Sunday, Tuesday, Special Event

3. **Scenario Task Completion:**
   - Display tasks as a TODO list for each scenario
   - When a task is marked complete, it cannot be undone (per requirements)
   - When all tasks are complete, scenario status changes to "completed" automatically

4. **Offline-First Considerations:**
   - Store attendance and task data locally
   - Sync when internet is available
   - Handle conflicts with server wins strategy
