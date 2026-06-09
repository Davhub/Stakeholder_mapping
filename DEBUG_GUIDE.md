# 🔍 STEP-BY-STEP DEBUG GUIDE - Stakeholder Mapping System

**Last Updated:** May 5, 2026  
**Purpose:** Complete troubleshooting guide for empty LGA/Ward dropdowns and search filter issues

---

## 📋 QUICK DIAGNOSIS CHECKLIST

Use this to quickly identify your issue:

- [ ] **Empty LGA Dropdown?** → See ISSUE #1
- [ ] **Empty Ward Dropdown?** → See ISSUE #2
- [ ] **Search Shows No Results?** → See ISSUE #3
- [ ] **User Can See Other State's Data?** → See ISSUE #4
- [ ] **New Stakeholder Won't Save?** → See ISSUE #5

---

## 🚨 ROOT CAUSES FOUND & FIXED

### FIXED ISSUE #1: Field Name Serialization Bug ✅
**File:** `lib/model/class_stakeholder.dart`  
**Problem:** `toFirestore()` used `'whatsappNumber'` but `fromFirestore()` expected `'whNumber'`  
**Fix Applied:** Changed to `'whNumber'` for consistency  
**Status:** ✅ FIXED

### ISSUE #2: Field Name Usage (Not a Bug - Different Collections)
**Problem:** LocationService queries `wards.lga` but screens query `stakeholders.lg`  
**Why It's OK:** They're different collections with different field names  
- `wards` collection: Uses field `lga`
- `stakeholders` collection: Uses field `lg`  
**This is CORRECT architecture**

### POTENTIAL ISSUE #3: User State Mismatch
**Symptom:** Dropdowns are empty  
**Cause:** User's state from `users` collection doesn't match any state in `wards` collection  
**Example:**
```
User has: state = "Ogun"
Wards collection has: state = "Ogun State"
Result: No LGAs found! ❌
```

**How to Verify:**
1. Open Firebase Console
2. Go to `users` collection
3. Find your user
4. Note the exact value of `state` field
5. Go to `wards` collection
6. Search for a document with that state value
7. If no matches → **THIS IS THE PROBLEM**

### POTENTIAL ISSUE #4: Empty Wards Collection
**Symptom:** All users see empty LGA/Ward dropdowns  
**Cause:** `wards` collection has no documents  
**How to Verify:**
1. Open Firebase Console → `wards` collection
2. Count total documents
3. If 0 → **THIS IS THE PROBLEM**

### POTENTIAL ISSUE #5: Firestore Security Rules Blocking Queries
**Symptom:** No errors in console, but dropdowns empty  
**Cause:** Firestore security rules prevent reading `wards` collection  
**How to Verify:**
1. Check console for errors starting with `Firestore error:`
2. Check `firestore.rules` file
3. Verify rules allow `.collection('wards').where(...).get()`

---

## 🔧 NEW DEBUG LOGGING ADDED

### LocationService Debug Logs
```
🔄 [LGA-QUERY] Fetching LGAs for state: "Lagos"
📊 [LGA-DATA] Query returned 5 documents for state "Lagos"
   Doc 0: lga="Agege" (type: String)
   Doc 1: lga="Ikorodu" (type: String)
✅ [LGA-DATA] Loaded 2 unique LGAs: [Agege, Ikorodu]
```

**What to look for:**
- "Query returned 0 documents" → State mismatch or empty collection
- "lga=null" → Field doesn't exist in Firestore
- "⚠️ Document X missing "lga" field" → Data corruption

### Admin Dashboard Debug Logs
```
🔐 [AUTH] Current user: admin@example.com
📍 [STATE] Admin state retrieved: "Lagos" (type: String, length: 5)
📍 [STATE] User document fields: [email, state, role, createdAt]
🔍 [FILTER-BUILD] State filter: Lagos
🔍 [FILTER-BUILD] Added LGA filter: Agege
🔍 [FILTER-QUERY] Final query - State: Lagos, LGA: Agege, Ward: none
```

### Dashboard Screen Debug Logs
```
🔐 [AUTH] Current user UID: abc123, email: user@example.com
📍 [STATE] User state retrieved: "Ogun" (type: String, length: 4)
📍 [STATE] User document fields: [email, state, preferences]
🔍 [FIRESTORE-SCOPE] Setting Firestore listener scoped to: "Ogun"
📊 [FIRESTORE-DATA] Received 12 stakeholders for state: Ogun
```

---

## 🐛 DEBUGGING STEPS

### STEP 1: Enable Debug Logging
Debug logs are already added with emoji prefixes. Open your IDE's debug console and search for:
- 🔐 = Authentication issues
- 📍 = State retrieval issues
- 🔄 = Query execution
- ✅ = Data received
- ❌ = Errors

### STEP 2: Run Firebase Diagnostic Service
```dart
// Add to your debug screen or press F12 in dev mode
final debugService = FirebaseDebugService();
await debugService.printDiagnostic();
```

This will show:
- User authentication status
- Exact user state value
- All states in wards collection
- Sample documents from each collection
- Actual query results

### STEP 3: Verify Firestore Console Data

**Check wards collection:**
```
Path: /wards
Expected fields: state, lga, ward
Sample document:
{
  "state": "Lagos",
  "lga": "Agege",
  "ward": "Ward 1"
}
```

**Check users collection:**
```
Path: /users/{uid}
Expected field: state
Sample document:
{
  "email": "admin@example.com",
  "state": "Lagos",
  "role": "admin"
}
```

**Check stakeholders collection:**
```
Path: /stakeholders
Expected fields: state, lg, ward, name
Sample document:
{
  "name": "John Doe",
  "state": "Lagos",
  "lg": "Agege",
  "ward": "Ward 1",
  "association": "Some Association"
}
```

### STEP 4: Test Query Manually

In Firebase Console, try these queries:

**Query A: Get LGAs**
```
Collection: wards
Where: state == "Lagos"
Expected result: Multiple documents with different "lga" values
```

**Query B: Get Wards**
```
Collection: wards
Where: state == "Lagos" AND lga == "Agege"
Expected result: Multiple documents with different "ward" values
```

**Query C: Get Stakeholders**
```
Collection: stakeholders
Where: state == "Lagos" AND lg == "Agege"
Expected result: Stakeholder documents
```

If any query returns 0 results → **Data mismatch**

---

## ⚠️ ERROR MESSAGES & MEANINGS

### "No LGA data available. Wards collection may be empty or state mismatch."
**Meaning:** Query for LGAs returned 0 results  
**Possible causes:**
1. `wards` collection is empty
2. User state doesn't exist in `wards` collection
3. User state has extra spaces or different casing

**Fix:**
1. Open Firebase Console
2. Check if `wards` collection has documents
3. Compare user.state with values in `wards.state`
4. Ensure exact match (including spacing and casing)

### "No wards found for LGA: Agege"
**Meaning:** Query returned 0 wards for that state+LGA combination  
**Possible causes:**
1. No wards data exists for this LGA
2. LGA name spelling mismatch

### "Error loading LGAs: PlatformException(...)"
**Meaning:** Firestore query failed  
**Possible causes:**
1. Security rules block read access
2. Network error
3. Firestore service unavailable

**Fix:**
1. Check console for full error
2. Verify Firestore rules allow reads
3. Check network connectivity

---

## 🔐 SECURITY & STATE-SCOPING VERIFICATION

### Verify State Scoping is Enforced

All queries must include `where('state', isEqualTo: userState)`:

**✅ CORRECT:**
```dart
.collection('stakeholders')
.where('state', isEqualTo: userState)  // ← REQUIRED
.where('lg', isEqualTo: selectedLGA)   // Optional
```

**❌ WRONG:**
```dart
.collection('stakeholders')
.where('lg', isEqualTo: selectedLGA)   // Missing state filter!
```

### Verify Admin State Scoping

Admin dashboard queries:
```dart
Query query = stakeholders.where('state', isEqualTo: adminState);
// ✅ All LGA/Ward filters added on top of state filter
```

### Verify New Stakeholder Creation

When creating new stakeholder:
```dart
'state': _stateController.text  // ← Auto-populated from admin's state
// ❌ NOT user-selectable
```

---

## 🧪 TESTING CHECKLIST

Use this to verify the system is working:

### Test 1: Multi-User Multi-State
- [ ] Create User A with state = "Lagos"
- [ ] Create User B with state = "Ogun"
- [ ] User A logs in → Should only see Lagos LGAs/Wards
- [ ] User B logs in → Should only see Ogun LGAs/Wards
- [ ] User A should NOT see User B's data (verify in search results)

### Test 2: Empty State
- [ ] Create a test state with NO stakeholders but has LGAs/Wards in wards collection
- [ ] User with that state should still see LGA/Ward dropdowns
- [ ] Dropdowns should NOT be blocked or show errors

### Test 3: Data Consistency
- [ ] Create stakeholder as Admin for "Lagos"
- [ ] Regular user in "Lagos" should see it in search
- [ ] Regular user in "Ogun" should NOT see it

### Test 4: Cross-State Boundary
- [ ] Add a stakeholder with wrong state value
- [ ] Verify it doesn't appear in any user's search results except that state

---

## 🚀 PRODUCTION VERIFICATION

Before deploying to production, verify:

- [ ] **No error messages in console** when loading screens
- [ ] **LGA dropdowns populate** within 2 seconds
- [ ] **Ward dropdowns populate** after selecting LGA
- [ ] **Search results** are filtered by state
- [ ] **Admin dashboard** shows correct stakeholder count
- [ ] **Add stakeholder** form auto-fills state correctly
- [ ] **Multiple states** can coexist without data leakage
- [ ] **Empty states** don't break UI
- [ ] **Firestore rules** allow reads for correct collections

---

## 📞 TROUBLESHOOTING QUICK REFERENCE

| Symptom | Check | Fix |
|---------|-------|-----|
| Empty LGA dropdown | User.state matches wards.state? | Update user state or add wards data |
| Empty Ward dropdown | wards exists with state+lga? | Add ward documents to wards collection |
| Search shows nothing | stakeholders exists with state? | Add stakeholder documents |
| Can see other state data | Query includes state filter? | Add where('state', isEqualTo: userState) |
| Admin dashboard broken | adminState retrieved correctly? | Check _getAdminState() method |
| New stakeholder won't save | state auto-assigned? | Verify _stateController.text is set |
| Console errors with "lga" | Using correct field name? | Stakeholders use "lg", wards use "lga" |

---

## 📊 DATA STRUCTURE REFERENCE

### Collection: wards
```
/wards/{docId}
├── state (String): "Lagos"
├── lga (String): "Agege"
└── ward (String): "Ward 1"
```

### Collection: stakeholders
```
/stakeholders/{docId}
├── name (String): "John Doe"
├── state (String): "Lagos"
├── lg (String): "Agege"          ← Note: "lg" not "lga"
├── ward (String): "Ward 1"
├── association (String): "..."
├── phNumber (String): "..."
└── whNumber (String): "..."      ← Fixed: was "whatsappNumber"
```

### Collection: users
```
/users/{uid}
├── email (String): "admin@example.com"
├── state (String): "Lagos"
├── role (String): "admin"
└── ...other fields
```

---

## 🎯 NEXT STEPS

1. **If dropdowns are empty:** Run diagnostic service, compare user.state with wards.state
2. **If search shows nothing:** Verify Firestore has stakeholder documents with matching state
3. **If you see other states' data:** Verify all queries include state filter
4. **If unsure:** Follow STEP 1-6 above systematically

---

**Created:** 2026-05-05  
**Debug Service Location:** `lib/services/firebase_debug_service.dart`  
**Main Files Changed:**
- `lib/model/class_stakeholder.dart` - Fixed phone field name
- `lib/services/location_service.dart` - Enhanced logging
- `lib/screens/admin_dashboard_screen.dart` - Added empty state messages
- `lib/screens/dashboard_screen.dart` - Added loading/error states

