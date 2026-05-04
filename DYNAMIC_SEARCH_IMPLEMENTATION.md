# Dynamic Search & Location Service Integration Guide

## Overview
This guide explains how to integrate the new **LocationService** and **DynamicSearchService** to replace hardcoded state/LGA/ward data with dynamic Firestore data, enabling simultaneous filtering.

## New Services Created

### 1. LocationService (`lib/services/location_service.dart`)
Manages all location data (States, LGAs, Wards) from Firestore with caching.

**Key Methods:**
- `initialize()` - Load all states from Firestore
- `getLGAsForState(state)` - Get LGAs for a state
- `getWardsForLGA(state, lga)` - Get wards for an LGA
- `getAllLGAsAndWardsForState(state)` - Get all LGAs and wards for bulk initialization

### 2. DynamicSearchService (`lib/services/dynamic_search_service.dart`)
Provides search and filtering with real-time ward list updates.

**Key Methods:**
- `searchStakeholders()` - Search with combined filters
- `getAvailableWards()` - Get wards for selected LGA (enables simultaneous filtering)
- `getAvailableLGAs()` - Get LGAs for a state
- `streamStakeholders()` - Real-time stakeholder stream

## Database Structure (Firestore)

Your wards collection should have this structure:
```
wards/
├── document1
│   ├── state: "Lagos"
│   ├── lga: "Agege"
│   └── ward: "Ward A"
├── document2
│   ├── state: "Lagos"
│   ├── lga: "Agege"
│   └── ward: "Ward B"
├── document3
│   ├── state: "Ogun"
│   ├── lga: "Abeokuta"
│   └── ward: "Ward X"
... etc
```

## Integration Steps

### Step 1: Initialize LocationService in main.dart
```dart
import 'package:risdi/services/location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize LocationService globally
  final locationService = LocationService();
  await locationService.initialize();
  
  runApp(MyApp(locationService: locationService));
}

class MyApp extends StatelessWidget {
  final LocationService locationService;
  
  const MyApp({required this.locationService});
  
  // Use locationService in your app
}
```

### Step 2: Use in Dashboard Screen

Replace hardcoded maps with dynamic loading:

```dart
import 'package:risdi/services/location_service.dart';
import 'package:risdi/services/dynamic_search_service.dart';

class DashboardScreen extends StatefulWidget {
  final LocationService locationService;
  
  const DashboardScreen({required this.locationService});
  
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DynamicSearchService _searchService;
  List<String> lgas = [];
  List<String> wards = [];
  String? selectedLga;
  String? selectedWard;
  
  @override
  void initState() {
    super.initState();
    _searchService = DynamicSearchService(widget.locationService);
    _loadLGAs();
  }
  
  Future<void> _loadLGAs() async {
    if (currentUserState == null) return;
    
    final lgaList = await _searchService.getAvailableLGAs(currentUserState!);
    setState(() {
      lgas = lgaList;
    });
  }
  
  // When LGA is selected, load wards for that LGA
  Future<void> _onLGASelected(String? lga) async {
    if (lga == null || currentUserState == null) return;
    
    final wardList = await _searchService.getAvailableWards(
      state: currentUserState!,
      lga: lga,
    );
    
    setState(() {
      selectedLga = lga;
      selectedWard = null; // Reset ward when LGA changes
      wards = wardList;
    });
    
    // Perform search with new filters
    _performSearch();
  }
  
  // When Ward is selected
  void _onWardSelected(String? ward) {
    setState(() {
      selectedWard = ward;
    });
    _performSearch();
  }
  
  Future<void> _performSearch() async {
    if (currentUserState == null) return;
    
    final results = await _searchService.searchStakeholders(
      state: currentUserState!,
      lga: selectedLga,
      ward: selectedWard,
      searchQuery: _searchController.text,
    );
    
    setState(() {
      filteredStakeholders = results;
    });
  }
  
  void _onSearchQueryChanged(String query) {
    _searchController.text = query;
    _performSearch();
  }
}
```

### Step 3: Update UI Dropdowns

Replace hardcoded dropdown items with dynamic lists:

```dart
// LGA Dropdown
DropdownButtonFormField<String>(
  value: selectedLga,
  hint: const Text('Select LGA'),
  items: lgas.map((lga) {
    return DropdownMenuItem(
      value: lga,
      child: Text(lga),
    );
  }).toList(),
  onChanged: _onLGASelected,
),

const SizedBox(height: 16),

// Ward Dropdown (only shows wards for selected LGA)
DropdownButtonFormField<String>(
  value: selectedWard,
  hint: const Text('Select Ward'),
  items: wards.map((ward) {
    return DropdownMenuItem(
      value: ward,
      child: Text(ward),
    );
  }).toList(),
  onChanged: _onWardSelected,
),
```

## Simultaneous Filtering Logic

The search works simultaneously like this:

1. **User selects State** (loaded from signup/user profile)
   - LGA dropdown loads available LGAs for that state
   
2. **User selects LGA**
   - Ward dropdown loads ONLY wards for that LGA (simultaneous filtering)
   - This is the key improvement: wards change instantly based on LGA
   
3. **User selects Ward** (optional)
   - Stakeholder list filters to that ward
   
4. **User types search query**
   - Results filter by name, association, phone, etc.
   
5. **Combination filters** work together:
   - State + LGA + Ward + Search Query = final results

## Performance Optimizations

1. **Caching**: LocationService caches fetched data to minimize Firestore calls
2. **Lazy Loading**: LGAs and wards loaded only when needed
3. **Stream Support**: Use `streamStakeholders()` for real-time updates
4. **Limit Queries**: Only query necessary fields

## Files to Update

1. **main.dart** - Initialize LocationService
2. **dashboard_screen.dart** - Replace hardcoded maps
3. **admin_dashboard_screen.dart** - Similar updates
4. **stakeholder_list_screen.dart** - Use DynamicSearchService
5. **ward_list_screen.dart** - Dynamic ward loading
6. **lga_list_screen.dart** - Dynamic LGA loading

## Backward Compatibility

If you need to keep hardcoded data as fallback:

```dart
Future<List<String>> getAvailableLGAs(String state) async {
  try {
    return await _locationService.getLGAsForState(state);
  } catch (e) {
    // Fallback to hardcoded data if Firestore fails
    return _fallbackLGAMap[state] ?? [];
  }
}
```

## Testing Checklist

- [ ] Users can sign up and select any of the 6 states
- [ ] LGA dropdown populates correctly for selected state
- [ ] Ward dropdown populates correctly for selected LGA
- [ ] Changing LGA clears and updates ward list
- [ ] Search filters work across all fields
- [ ] Combination of state + LGA + ward + search works
- [ ] Performance is acceptable (< 500ms for queries)
- [ ] Works offline (cached data should show)

## Firestore Indexes Required

For optimal performance, ensure these indexes exist in Firestore:

```
stakeholders collection:
- Index 1: state (ASC)
- Index 2: state (ASC), lg (ASC)
- Index 3: state (ASC), lg (ASC), ward (ASC)
```

These should already be in your `firestore.indexes.json`.

## Migration Path

1. Start with one screen (dashboard_screen)
2. Test thoroughly
3. Expand to other screens
4. Remove hardcoded maps once all screens migrated
5. Update documentation
