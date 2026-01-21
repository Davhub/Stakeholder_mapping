# Web Admin Dashboard Documentation

## Overview

The Web Admin Dashboard is a comprehensive Flutter Web application built to manage stakeholders for civic engagement projects. It provides real-time analytics, CRUD operations, and state-scoped data management with Firebase backend integration.

## Features

### ✨ Core Capabilities

1. **Real-Time Dashboard**
   - Live KPI metrics (Total Stakeholders, LGAs, Wards, Recent Additions)
   - Growth percentage indicators
   - Recent stakeholders list with auto-refresh
   - State-scoped data filtering

2. **Stakeholder Management**
   - Full CRUD operations (Create, Read, Update, Delete)
   - Advanced search (by name, phone, association)
   - Multi-level filtering (LGA and Ward)
   - Pagination support (50 items per page)
   - Real-time data synchronization
   - Confirmation dialogs for destructive actions

3. **Analytics & Reports**
   - LGA distribution visualization (top 10 bar chart)
   - Ward distribution by LGA
   - 30-day stakeholder addition trends
   - CSV export capability (placeholder)

4. **Admin Profile**
   - View account details (email, state, role, UID)
   - Account creation date
   - Password change functionality (placeholder)

5. **Security**
   - Role-based access control (Admin role required)
   - State-scoped queries (admins only see their state's data)
   - Firebase Authentication integration
   - Secure logout with confirmation

## Architecture

### Directory Structure

```
lib/web_admin/
├── services/
│   └── admin_firestore_service.dart    # Centralized Firestore operations
├── screens/
│   ├── web_admin_dashboard.dart        # Main layout with sidebar
│   ├── web_dashboard_home.dart         # KPI dashboard
│   ├── web_stakeholders_table.dart     # Stakeholder management
│   ├── web_analytics_screen.dart       # Analytics & reports
│   └── web_profile_screen.dart         # Admin profile
├── models/
│   └── dashboard_models.dart           # Data models (KPIs, filters, pagination)
└── widgets/
    └── kpi_card.dart                   # Reusable KPI card components
```

### Key Components

#### 1. AdminFirestoreService
**Location:** `lib/web_admin/services/admin_firestore_service.dart`

Centralized service for all Firestore operations with state-scoped security.

**Key Methods:**
- `getAdminState()` - Retrieve admin's assigned state
- `getAdminProfile()` - Fetch admin user profile
- `getTotalStakeholders(adminState)` - Count total stakeholders
- `getTotalLGAs(adminState)` - Count unique LGAs
- `getTotalWards(adminState)` - Count unique wards
- `getRecentlyAddedStakeholders(adminState)` - Last 7 days count
- `getStakeholdersStream({adminState, lgaFilter, wardFilter, limit, startAfter})` - Real-time paginated data
- `searchStakeholders({adminState, searchQuery})` - Client-side search
- `createStakeholder(data)` - Add new stakeholder
- `updateStakeholder(id, data)` - Update existing stakeholder
- `deleteStakeholder(id)` - Remove stakeholder
- `getStakeholderDistributionByLGA(adminState)` - LGA analytics
- `getStakeholderDistributionByWard(adminState, lga)` - Ward analytics
- `getStakeholderAdditionsTrend(adminState)` - 30-day trend data
- `getUniqueLGAs(adminState)` - Dropdown options
- `getUniqueWards(adminState, [lga])` - Dropdown options with optional LGA filter

#### 2. Data Models
**Location:** `lib/web_admin/models/dashboard_models.dart`

- **DashboardKPIs** - KPI metrics container
- **ChartDataPoint** - Generic chart data structure
- **TimeSeriesDataPoint** - Date-based chart data
- **PaginationState** - Pagination tracking
- **TableFilterState** - Filter and sort state management

#### 3. Main Dashboard Layout
**Location:** `lib/web_admin/screens/web_admin_dashboard.dart`

Responsive sidebar layout with:
- Collapsible/expandable sidebar (250px / 80px)
- Top navigation bar with user info
- Purple gradient theme
- Route-based screen switching
- Logout confirmation dialog

## Platform Detection

The application uses Flutter's `kIsWeb` constant for platform-specific routing:

```dart
// lib/main.dart
home: kIsWeb 
    ? const WebAuthWrapper()  // Web admin dashboard
    : SplashScreen(hasSeenOnboarding: hasSeenOnboarding), // Mobile app
```

**Important:** Hive (local storage) is only initialized for mobile platforms to avoid web compatibility issues.

## Firestore Data Structure

### Collections

#### `stakeholders`
```json
{
  "fullName": "String",
  "phoneNumber": "String",
  "whatsappNumber": "String",
  "email": "String",
  "country": "String",
  "state": "String",        // State assignment (Lagos/Oyo)
  "lg": "String",           // Local Government Area
  "ward": "String",         // Electoral ward
  "association": "String",  // Community association
  "levelOfAdministration": "String",  // State/LGA/Ward
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

#### `users`
```json
{
  "email": "String",
  "state": "String",    // Assigned state for admin
  "role": "String",     // Admin/User
  "uid": "String"       // Firebase Auth UID
}
```

## Security Rules (Recommended)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Stakeholders collection - state-scoped access
    match /stakeholders/{stakeholderId} {
      allow read: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.state == resource.data.state;
      
      allow create: if request.auth != null && 
                       request.resource.data.state == get(/databases/$(database)/documents/users/$(request.auth.uid)).data.state &&
                       request.resource.data.keys().hasAll(['fullName', 'phoneNumber', 'whatsappNumber', 'state', 'lg', 'ward']);
      
      allow update: if request.auth != null && 
                       resource.data.state == get(/databases/$(database)/documents/users/$(request.auth.uid)).data.state &&
                       request.resource.data.state == resource.data.state;
      
      allow delete: if request.auth != null && 
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'Admin' &&
                       resource.data.state == get(/databases/$(database)/documents/users/$(request.auth.uid)).data.state;
    }
    
    // Users collection - read own profile only
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if false; // Only allow writes through Cloud Functions
    }
  }
}
```

## Running the Web Admin Dashboard

### Development

```bash
# Run on web (Chrome recommended)
flutter run -d chrome

# Or specify a different browser
flutter run -d edge
flutter run -d web-server
```

### Production Build

```bash
# Build for production
flutter build web --release

# Output: build/web/

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

### Firebase Hosting Configuration

```json
// firebase.json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

## Usage Guide

### Admin Login

1. Navigate to web application URL
2. Enter admin credentials (email/password)
3. System checks user role in Firestore `users` collection
4. Admins are routed to dashboard, others see error

### Dashboard Navigation

**Left Sidebar:**
- 🏠 Dashboard - KPIs and recent stakeholders
- 👥 Stakeholders - Full table with CRUD
- 📊 Analytics - Distribution charts and trends
- 👤 Profile - Account settings
- 🚪 Logout - Sign out with confirmation

### Managing Stakeholders

**Add New:**
1. Click "Add Stakeholder" button
2. Fill required fields (marked with *)
3. Select LGA and Ward from dropdowns
4. Click "Add" to save

**Edit Existing:**
1. Click edit icon (blue pencil) in table row
2. Modify fields in dialog
3. Click "Update" to save changes

**Delete:**
1. Click delete icon (red trash) in table row
2. Confirm deletion in dialog
3. Data is permanently removed

**Search & Filter:**
- Use search bar for name/phone/association lookup
- Select LGA dropdown to filter by government area
- Select Ward dropdown to filter by specific ward
- Filters are cumulative (AND logic)

### Analytics

**LGA Distribution:**
- Shows top 10 LGAs by stakeholder count
- Progress bars indicate relative distribution
- Sorted by count (descending)

**Ward Distribution:**
- All wards across selected LGA (or all if none selected)
- Useful for identifying coverage gaps

**30-Day Trend:**
- Daily stakeholder additions over past month
- Chart visualization (placeholder - requires chart library)

**CSV Export:**
- Button available (implementation pending)
- Will export current filtered dataset

## Responsive Design

The dashboard adapts to different screen sizes:

- **Desktop (>1024px):** Full sidebar, 4-column KPI grid
- **Tablet (768-1024px):** Collapsible sidebar, 2-column KPI grid
- **Mobile (<768px):** Hidden sidebar (toggle button), stacked KPIs

## Theme & Styling

**Color Palette:**
- Primary: Deep Purple (`Colors.deepPurple`)
- Accent: Purple shades (100-700)
- Success: Green
- Error: Red
- Warning: Orange
- Info: Blue

**Typography:**
- Font Family: System default (Roboto on web)
- Material Design 3 principles
- Bold weights for headers (600-700)
- Regular weights for body (400-500)

## Future Enhancements

### High Priority
1. **Chart Library Integration**
   - Add `fl_chart` package
   - Implement interactive line/bar/pie charts in analytics

2. **CSV Export**
   - Add `csv` package
   - Generate downloadable reports with timestamp

3. **Advanced Pagination**
   - Add page number navigation
   - Jump to page input
   - Items per page selector

### Medium Priority
4. **Real-Time Notifications**
   - Firebase Cloud Messaging for new stakeholder alerts
   - In-app notification center

5. **Bulk Operations**
   - Multi-select stakeholders
   - Bulk delete/export
   - Import from CSV

6. **Advanced Filtering**
   - Date range filters
   - Level of administration filter
   - Custom query builder

### Low Priority
7. **User Management**
   - Admin can create/manage other admins
   - Role permission customization

8. **Audit Logs**
   - Track all CRUD operations
   - View history of changes

9. **Dashboard Customization**
   - Drag-and-drop widgets
   - Save custom layouts

## Troubleshooting

### Issue: "Unable to load admin state"
**Cause:** User document missing `state` field in Firestore
**Solution:** Ensure all admin users have `state` field in `users/{uid}` document

### Issue: No stakeholders showing
**Cause:** State mismatch between admin and stakeholders
**Solution:** Verify admin's `state` field matches stakeholder documents

### Issue: Search not working
**Cause:** Search is client-side, limited by Firestore query results
**Solution:** If dataset is large, consider Algolia or Elasticsearch integration

### Issue: Build errors on web
**Cause:** Hive package not compatible with web
**Solution:** Hive is conditionally initialized only for mobile platforms (already implemented)

## Performance Optimization

1. **Pagination:** Limits Firestore reads to 50 documents per page
2. **Indexing:** Ensure Firestore indexes on `state`, `lg`, `ward`, `createdAt`
3. **Caching:** Firestore caching enabled (`persistenceEnabled: true`)
4. **Lazy Loading:** Screens load data only when activated
5. **Real-Time Efficiency:** Streams scoped by state to minimize bandwidth

## Support

For issues or questions:
- Check Firestore console for data integrity
- Review browser console for JavaScript errors
- Verify Firebase Authentication status
- Test with admin account in different state

## License

This project follows the main application's license.

---

**Last Updated:** January 21, 2026
**Version:** 1.0.0
**Author:** Senior Full-Stack Flutter & Firebase Engineer
