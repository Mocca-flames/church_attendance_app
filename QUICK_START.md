# Quick Start Guide - Church Attendance App

## 🚀 Get Started in 5 Steps

### **Step 1: Backend Setup (15 minutes)**

1. **Add servant role and new models** to your FastAPI backend:
   - Copy models from `README.md` → "Step 2: Create New Models"
   - Add to `app/models.py`

2. **Create endpoint files**:
   ```bash
   touch app/routers/attendance.py
   touch app/routers/scenarios.py
   ```
   - Copy code from `README.md` → "Step 4: Create API Endpoints"

3. **Run migration**:
   ```bash
   alembic revision --autogenerate -m "Add attendance and scenarios"
   alembic upgrade head
   ```

4. **Register routers** in `app/main.py`:
   ```python
   from app.routers import attendance, scenarios
   
   app.include_router(attendance.router)
   app.include_router(scenarios.router)
   ```

5. **Start backend**:
   ```bash
   uvicorn app.main:app --reload
   ```

---

### **Step 2: Flutter Setup (5 minutes)**

1. **Update API URL** in `lib/core/network/api_constants.dart`:
   ```dart
   static const String baseUrl = 'http://192.168.1.100:8000'; // Your backend URL
   ```

2. **Install dependencies**:
   ```bash
   cd church_attendance_app
   flutter pub get
   ```

3. **Generate code**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

---

### **Step 3: Test Backend Endpoints (5 minutes)**

Test with curl or Postman:

```bash
# Login as servant
curl -X POST "http://localhost:8000/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=servant@church.com&password=password123"

# Save the access_token from response

# Create attendance record
curl -X POST "http://localhost:8000/attendance/record" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "contact_id": 1,
    "phone": "+27821234567",
    "service_type": "Sunday",
    "service_date": "2025-02-16T10:00:00Z",
    "recorded_by": 1
  }'
```

---

### **Step 4: Implement Data Layer (Refer to IMPLEMENTATION_GUIDE.md)**

Follow **Phase 3** in `IMPLEMENTATION_GUIDE.md`:

1. Create data sources (local + remote)
2. Implement repositories
3. Set up Riverpod providers

**Example files to create:**
- `lib/features/contacts/data/datasources/contact_local_datasource.dart`
- `lib/features/contacts/data/datasources/contact_remote_datasource.dart`
- `lib/features/contacts/data/repositories/contact_repository_impl.dart`
- `lib/features/contacts/presentation/providers/contact_provider.dart`

Code samples are in `IMPLEMENTATION_GUIDE.md`.

---

### **Step 5: Build UI Screens**

Start with essential screens:

1. **Login Screen** - Allow servants to authenticate
2. **Home Screen** - Dashboard with navigation
3. **Contacts List** - View all contacts
4. **QR Scanner** - Record attendance

---

## 📁 Files Created for You

```
church_attendance_app/
├── lib/
│   ├── main.dart                    ✅ Main app entry
│   ├── core/
│   │   ├── database/database.dart   ✅ Complete Drift schema
│   │   ├── network/                 ✅ Dio client + API constants
│   │   ├── sync/sync_manager.dart   ✅ Offline-first sync
│   │   └── enums/                   ✅ All smart enums
│   └── features/
│       ├── auth/domain/models/      ✅ User model
│       ├── contacts/domain/         ✅ Contact model + repository
│       ├── attendance/domain/       ✅ Attendance model
│       └── scenarios/domain/        ✅ Scenario models
├── pubspec.yaml                     ✅ All dependencies
├── analysis_options.yaml            ✅ Linting rules
├── README.md                        ✅ Full documentation
├── IMPLEMENTATION_GUIDE.md          ✅ Step-by-step guide
└── PROJECT_STRUCTURE.md             ✅ Architecture overview
```

---

## ⚡ What You Need to Do

### **Priority 1: Backend (Required first)**
- [ ] Add models to `app/models.py`
- [ ] Create `attendance.py` router
- [ ] Create `scenarios.py` router
- [ ] Run migration
- [ ] Test endpoints

### **Priority 2: Flutter Data Layer**
- [ ] Implement contact data sources
- [ ] Implement contact repository
- [ ] Create contact provider
- [ ] Repeat for attendance/scenarios

### **Priority 3: Flutter UI**
- [ ] Build login screen
- [ ] Build home screen
- [ ] Build contacts list
- [ ] Build QR scanner

---

## 🎯 Testing Checklist

Once implemented, test these scenarios:

### **Offline Functionality**
1. Turn off internet
2. Create 3 contacts
3. Record attendance for 2 contacts
4. Check sync queue (should have 5 pending items)
5. Turn on internet
6. Trigger sync
7. Verify data appears in backend database

### **QR Code Flow**
1. Create contact with name != phone and 'member' tag
2. Generate QR code
3. Scan QR code
4. Verify attendance recorded with correct service type

### **Scenario Flow**
1. Create scenario "Food Parcel - Kanana"
2. Filter by 'kanana' tag
3. Mark 3 tasks as complete
4. Verify scenario auto-completes when all done

---

## 🆘 Troubleshooting

### **"build_runner" errors**
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### **Drift database errors**
- Delete `church_attendance.db` from device
- Restart app to recreate database

### **Network errors**
- Check `ApiConstants.baseUrl` is correct
- Verify backend is running
- Test endpoints with curl first

### **Sync not working**
- Check internet connectivity
- Verify sync queue has pending items
- Check backend logs for errors

---

## 📚 Documentation Structure

1. **README.md** - Overview, setup, backend endpoints
2. **PROJECT_STRUCTURE.md** - Folder organization, file responsibilities
3. **IMPLEMENTATION_GUIDE.md** - Detailed code examples, patterns
4. **QUICK_START.md** (this file) - Fast track to get running

---

## 💡 Pro Tips

1. **Start with backend first** - Frontend depends on it
2. **Test each layer** - Data sources → Repositories → Providers → UI
3. **Use build_runner watch** for auto code generation during development
4. **Keep sync queue clean** - Monitor pending items during testing
5. **Log everything** - Use Logger package to debug offline sync

---

## 🎉 You're Ready!

The architecture is set up. Now:
1. Set up backend endpoints
2. Generate Flutter code
3. Implement data layer (follow IMPLEMENTATION_GUIDE.md)
4. Build UI screens
5. Test offline sync thoroughly

**All the hard architectural decisions are done. You just need to fill in the implementation following the patterns provided!** 🚀

---

**Questions? Check:**
- `README.md` for backend setup
- `IMPLEMENTATION_GUIDE.md` for code examples
- `PROJECT_STRUCTURE.md` for file organization
