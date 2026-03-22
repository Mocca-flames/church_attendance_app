# Plan: Update PDF Export to Use New Date Parameter

## Status: ✅ COMPLETED

## Problem
The server endpoint now supports a new `date` parameter that takes priority over `date_from/date_to` for single-day exports.

## New API Behavior
- Single Date: `GET /attendance/export?date=2026-02-23` (exports for entire day in SAST timezone)
- Date Range: `GET /attendance/export?date_from=2026-02-23&date_to=2026-02-24`
- The `date` parameter takes priority when provided
- Format: `date=YYYY-MM-DD` (not ISO8601 datetime)

## Implementation Strategy
Use `date` parameter when `dateFrom == dateTo` (single day selected), otherwise use `date_from/date_to` range.

## Changes Required

### 1. Update AttendanceRepository interface ✅
- Added optional `DateTime? date` parameter to `downloadAttendancePdf()`

### 2. Update AttendanceRepositoryImpl ✅
- Pass the new `date` parameter through to remote datasource

### 3. Update AttendanceRemoteDataSource ✅
- Added `DateTime? date` parameter to `downloadAttendancePdf()`
- Logic:
  - If `date` is provided: use `date=YYYY-MM-DD` format
  - Otherwise: use existing `date_from/date_to` logic
  - Note: `date` takes priority over `date_from/date_to`

### 4. Update AttendanceHistoryNotifier (provider) ✅
- In `downloadPdf()` method:
  - Check if `dateFrom == dateTo` (single day)
  - If yes: pass `date` parameter (normalized to date only)
  - If no: pass `dateFrom` and `dateTo` as before
- Added helper method `_isSameDay()` to detect single-day range
