# Dynamic Search Implementation Guide

## Part 1: Architecture Overview

Your new search system replaces hardcoded state/LGA/ward data with dynamic Firestore queries that enable **simultaneous filtering**:

```
State (Lagos) → LGA Dropdown (loads LGAs for Lagos)
                    ↓ (user selects "Agege")
              Ward Dropdown (loads ONLY wards for Agege)
                    ↓ (user selects "Ward A")
              Search (filters stakeholders for Lagos > Agege > Ward A)
                    ↓ (user types search query)
              Final Results (name + association + phone matched)
```

## Part 2: New Services

### LocationService
**File:** `lib/services/location_service.dart`
**Purpose:** Manages all location data with caching

```dart
// Usage:
final locationService = LocationService();
await locationService.initialize(); // Load states from Firestore

// Get LGAs for a state
final lgas = await locationService.getLGAsForState('Lagos');

// Get wards for an LGA
final wards = await locationService.getWardsForLGA('Lagos', 'Agege');

// Get all LGAs and wards for a state (bulk loading)
final map = await locationService.getAllLGAsAndWardsForState('Lagos');
```

### DynamicSearchService
**File:** `lib/services/dynamic_search_service.dart`
**Purpose:** Provides search with combined filters

```dart
// Usage:
final searchService = DynamicSearchService(locationService);

// Search with all filters combined
final results = await searchService.searchStakeholders(
  state: 'Lagos',
  lga: 'Agege',        // optional
  ward: 'Ward A',      // optional
  searchQuery: 'John', // optional
);

// Get available wards for selected LGA (key for simultaneous filtering)
final wards = await searchService.getAvailableWards(
  state: 'Lagos',
  lga: 'Agege',
);
```

## Part 3: Firestore Data Structure

Your wards collection should look like:

```
Firestore Database
└── wards (collection)
    ├── doc1: {state: "Lagos", lga: "Agege", ward: "Ward A"}
    ├── doc2: {state: "Lagos", lga: "Agege", ward: "Ward B"}
    ├── doc3: {state: "Lagos", lga: "Ikorodu", ward: "Ward X"}
    ├── doc4: {state: "Ogun", lga: "Abeokuta", ward: "Ward 1"}
    ├── doc5: {state: "Ekiti", lga: "Ado-Ekiti", ward: "Ward Alpha"}
    └── ...
```

## Part 4: Integration Steps

### Step 1: Update main.dart

```dart
import 'package:risdi/services/location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize location service
  final locationService = LocationService();
  await locationService.initialize();
  
  runApp(MyApp(locationService: locationService));
}

class MyApp extends StatelessWidget {
  final LocationService locationService;
  
  const MyApp({required this.locationService});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DashboardScreen(locationService: locationService),
    );
  }
}
```

### Step 2: Update Dashboard Screen

Replace your hardcoded `lgaMap` and `wardMap` with:

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
  
  List<String> availableLGAs = [];
  List<String> availableWards = [];
  String? selectedLGA;
  String? selectedWard;
  
  @override
  void initState() {
    super.initState();
    _searchService = DynamicSearchService(widget.locationService);
    _loadLGAsForState();
  }
  
  // Step 1: Load LGAs for user's state
  Future<void> _loadLGAsForState() async {
    if (currentUserState == null) return;
    
    final lgas = await _searchService.getAvailableLGAs(currentUserState!);
    setState(() {
      availableLGAs = lgas;
    });
  }
  
  // Step 2: When LGA is selected, load wards for that LGA
  // THIS IS THE KEY TO SIMULTANEOUS FILTERING
  Future<void> _onLGASelected(String? lga) async {
    if (lga == null || currentUserState == null) {
      setState(() {
        selectedLGA = null;
        selectedWard = null;
        availableWards = [];
      });
      return;
    }
    
    // Load wards for selected LGA
    final wards = await _searchService.getAvailableWards(
      state: currentUserState!,
      lga: lga,
    );
    
    setState(() {
      selectedLGA = lga;
      selectedWard = null; // Reset ward when LGA changes
      availableWards = wards; // Update ward list
    });
    
    // Perform search with new filters
    _performSearch();
  }
  
  // Step 3: When ward is selected
  Future<void> _onWardSelected(String? ward) async {
    setState(() {
      selectedWard = ward;
    });
    _performSearch();
  }
  
  // Step 4: Perform search with all combined filters
  Future<void> _performSearch() async {
    if (currentUserState == null) return;
    
    final results = await _searchService.searchStakeholders(
      state: currentUserState!,
      lga: selectedLGA,
      ward: selectedWard,
      searchQuery: _searchController.text,
    );
    
    setState(() {
      filteredStakeholders = results;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... your appbar
      body: Column(
        children: [
          // Search field
          TextField(
            controller: _searchController,
            onChanged: (_) => _performSearch(),
            decoration: InputDecoration(
              hintText: 'Search stakeholders...',
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          
          // LGA Dropdown
          DropdownButtonFormField<String>(
            value: selectedLGA,
            hint: const Text('Select LGA'),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All LGAs'),
              ),
              ...availableLGAs.map((lga) {
                return DropdownMenuItem(
                  value: lga,
                  child: Text(lga),
                );
              }),
            ],
            onChanged: _onLGASelected,
          ),
          
          // Ward Dropdown (only updates when LGA changes)
          DropdownButtonFormField<String>(
            value: selectedWard,
            hint: const Text('Select Ward'),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All Wards'),
              ),
              ...availableWards.map((ward) {
                return DropdownMenuItem(
                  value: ward,
                  child: Text(ward),
                );
              }),
            ],
            onChanged: _onWardSelected,
          ),
          
          // Stakeholders list
          Expanded(
            child: ListView.builder(
              itemCount: filteredStakeholders.length,
              itemBuilder: (context, index) {
                final stakeholder = filteredStakeholders[index];
                return ListTile(
                  title: Text(stakeholder.fullName),
                  subtitle: Text(
                    '${stakeholder.lg} - ${stakeholder.ward}',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

## Part 5: Key Features

### Feature 1: Simultaneous Filtering
When user selects an LGA, the ward dropdown updates instantly:

```
Before: User sees ALL wards for the state
After selecting LGA "Agege": User sees ONLY wards in Agege
After selecting Ward "Ward A": Results show only stakeholders in Lagos > Agege > Ward A
```

### Feature 2: Real-Time Search
All filters work together:

```dart
// This returns stakeholders matching ALL criteria:
// - State: Lagos
// - LGA: Agege
// - Ward: Ward A
// - Name or Association contains "John" or phone contains "080"
final results = await _searchService.searchStakeholders(
  state: 'Lagos',
  lga: 'Agege',
  ward: 'Ward A',
  searchQuery: 'John',
);
```

### Feature 3: Performance Optimized
- LocationService caches results
- Queries only fetch necessary fields
- Lazy loading (LGAs loaded only when user's state is known)

## Part 6: Files You'll Need to Update

1. **main.dart** - Initialize LocationService
2. **dashboard_screen.dart** - Use DynamicSearchService
3. **admin_dashboard_screen.dart** - Similar changes
4. **stakeholder_list_screen.dart** - Use DynamicSearchService
5. **ward_list_screen.dart** - Use location service for wards
6. **association_list_screen.dart** - Load associations dynamically

## Part 7: Testing Checklist

- [ ] App starts and LocationService initializes
- [ ] User signs up and selects any of the 6 states
- [ ] LGA dropdown shows correct LGAs for user's state
- [ ] Selecting LGA updates ward dropdown
- [ ] Selecting Ward filters stakeholders
- [ ] Search query filters results
- [ ] Combination of state + LGA + ward + search works
- [ ] Clearing filters resets everything
- [ ] App works offline (shows cached data)
- [ ] Performance is good (< 500ms for queries)

## Part 8: Troubleshooting

**Problem:** Ward dropdown shows empty list
**Solution:** Make sure your wards collection has documents with the selected state and LGA

**Problem:** LGA dropdown shows empty list
**Solution:** Make sure LocationService.initialize() was called before using it

**Problem:** Slow queries
**Solution:** Check Firestore indexes in firestore.indexes.json

**Problem:** Search not working
**Solution:** Make sure phone number field exists in Stakeholder model (use phoneNumber not phone)

## Part 9: Next Steps

1. Create the two new services (LocationService and DynamicSearchService)
2. Test with a single screen (dashboard_screen)
3. Once working, expand to other screens
4. Remove hardcoded maps from all files
5. Update documentation
6. Test with all 6 states thoroughly
