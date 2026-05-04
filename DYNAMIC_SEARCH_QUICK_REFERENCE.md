# Dynamic Search - Quick Reference Card

## 🚀 Quick Start (Copy-Paste Ready)

### 1. Initialize in main.dart

```dart
import 'package:risdi/services/location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize LocationService
  final locationService = LocationService();
  await locationService.initialize();
  
  runApp(MyApp(locationService: locationService));
}
```

### 2. Use in Dashboard Screen

```dart
import 'package:risdi/services/location_service.dart';
import 'package:risdi/services/dynamic_search_service.dart';

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
    _loadLGAs();
  }

  Future<void> _loadLGAs() async {
    final lgas = await _searchService.getAvailableLGAs(currentUserState);
    setState(() => availableLGAs = lgas);
  }

  Future<void> _onLGAChanged(String? lga) async {
    if (lga == null) {
      setState(() => selectedLGA = null);
      return;
    }
    
    final wards = await _searchService.getAvailableWards(
      state: currentUserState,
      lga: lga,
    );
    
    setState(() {
      selectedLGA = lga;
      selectedWard = null;
      availableWards = wards;
    });
    
    _performSearch();
  }

  Future<void> _performSearch() async {
    final results = await _searchService.searchStakeholders(
      state: currentUserState,
      lga: selectedLGA,
      ward: selectedWard,
      searchQuery: _searchController.text,
    );
    
    setState(() => filteredStakeholders = results);
  }
}
```

## 📊 API Reference

### LocationService

```dart
// Initialize
await locationService.initialize();

// Get all states
List<String> states = locationService.getAllStates();

// Get LGAs for a state
List<String> lgas = await locationService.getLGAsForState('Lagos');

// Get wards for an LGA
List<String> wards = await locationService.getWardsForLGA('Lagos', 'Agege');

// Get all LGAs and wards for state
Map<String, List<String>> map = 
    await locationService.getAllLGAsAndWardsForState('Lagos');

// Clear cache
locationService.clearCache();

// Get cached values (no query)
List<String> cachedLGAs = locationService.getCachedLGAsForState('Lagos');
List<String> cachedWards = 
    locationService.getCachedWardsForLGA('Lagos', 'Agege');

// Validate ward
bool isValid = await locationService.isValidWard('Lagos', 'Agege', 'Ward A');
```

### DynamicSearchService

```dart
// Search with filters
List<Stakeholder> results = await searchService.searchStakeholders(
  state: 'Lagos',          // required
  lga: 'Agege',            // optional
  ward: 'Ward A',          // optional
  searchQuery: 'John',     // optional
);

// Get available wards for selected LGA
List<String> wards = await searchService.getAvailableWards(
  state: 'Lagos',
  lga: 'Agege',
);

// Get available LGAs for state
List<String> lgas = await searchService.getAvailableLGAs('Lagos');

// Real-time stream
Stream<List<Stakeholder>> stream = searchService.streamStakeholders(
  state: 'Lagos',
  lga: 'Agege',
  ward: 'Ward A',
);

// Count stakeholders
int count = await searchService.getStakeholderCount(
  state: 'Lagos',
  lga: 'Agege',
  ward: 'Ward A',
);

// Get LGAs and wards map (for UI initialization)
Map<String, List<String>> map = 
    await searchService.getLGAsAndWardsMap('Lagos');
```

## 🎯 Common Patterns

### Pattern 1: Load LGAs on State Change
```dart
Future<void> _onStateChanged(String state) async {
  final lgas = await _searchService.getAvailableLGAs(state);
  setState(() {
    selectedLGA = null;
    selectedWard = null;
    availableLGAs = lgas;
    availableWards = [];
  });
}
```

### Pattern 2: Update Wards on LGA Change
```dart
Future<void> _onLGAChanged(String lga) async {
  final wards = await _searchService.getAvailableWards(
    state: currentState,
    lga: lga,
  );
  setState(() {
    selectedWard = null;
    availableWards = wards;
  });
}
```

### Pattern 3: Perform Combined Search
```dart
Future<void> _search() async {
  final results = await _searchService.searchStakeholders(
    state: currentState,
    lga: selectedLGA,
    ward: selectedWard,
    searchQuery: searchText,
  );
  setState(() => filteredStakeholders = results);
}
```

### Pattern 4: Real-Time Updates
```dart
@override
Widget build(BuildContext context) {
  return StreamBuilder<List<Stakeholder>>(
    stream: _searchService.streamStakeholders(
      state: currentState,
      lga: selectedLGA,
      ward: selectedWard,
    ),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return ListView(...);
      }
      return const CircularProgressIndicator();
    },
  );
}
```

## 🔧 UI Components

### Dropdown with Dynamic Items
```dart
DropdownButtonFormField<String>(
  value: selectedLGA,
  items: [
    const DropdownMenuItem(value: null, child: Text('All LGAs')),
    ...availableLGAs.map((lga) => DropdownMenuItem(
      value: lga,
      child: Text(lga),
    )),
  ],
  onChanged: _onLGAChanged,
  decoration: InputDecoration(
    labelText: 'Select LGA',
    border: OutlineInputBorder(),
  ),
)
```

### Search Field
```dart
TextField(
  controller: _searchController,
  onChanged: (_) => _performSearch(),
  decoration: InputDecoration(
    hintText: 'Search by name, association, phone...',
    prefixIcon: const Icon(Icons.search),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  ),
)
```

## ⚡ Performance Tips

1. **Cache aggressively:**
   ```dart
   // First call: ~100ms (from Firestore)
   // Second call: ~10ms (from cache)
   final lgas = await locationService.getLGAsForState('Lagos');
   ```

2. **Use streams for real-time:**
   ```dart
   // More efficient than polling
   final stream = searchService.streamStakeholders(...);
   ```

3. **Limit search scope:**
   ```dart
   // Better: filters before searching
   final results = await searchService.searchStakeholders(
     state: 'Lagos',
     lga: 'Agege', // narrows search
     searchQuery: 'John',
   );
   ```

## 🐛 Debugging

### Check what's in cache
```dart
debugPrint('LGAs for Lagos: ${locationService.getCachedLGAsForState('Lagos')}');
debugPrint('Wards for Agege: ${locationService.getCachedWardsForLGA('Lagos', 'Agege')}');
```

### Clear cache if data seems stale
```dart
locationService.clearCache();
await locationService.initialize();
```

### Enable debug prints
```dart
// Uncomment in location_service.dart:
// debugPrint('Loaded states: ${_stateCache['all']}');
// debugPrint('Loaded LGAs for $state: $lgaList');
```

## 📝 Database Structure

Ensure your wards collection looks like this:

```
Firestore > wards collection
Document {
  state: "Lagos" (String)
  lga: "Agege" (String)
  ward: "Ward A" (String)
}
```

All three fields are required for the service to work properly.

## ✅ Testing Checklist

- [ ] LocationService initializes without errors
- [ ] getAllStates() returns 6 states
- [ ] getLGAsForState() returns correct LGAs
- [ ] getWardsForLGA() returns correct wards
- [ ] DynamicSearchService searches correctly
- [ ] Selecting LGA updates ward dropdown
- [ ] Combined filters work together
- [ ] Search query filters results
- [ ] Cache speeds up subsequent calls
- [ ] App handles Firestore errors gracefully

## 🔐 Error Handling

```dart
try {
  final lgas = await _searchService.getAvailableLGAs(state);
  setState(() => availableLGAs = lgas);
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error loading LGAs: $e')),
  );
}
```

## 📚 Full Documentation

- **DYNAMIC_SEARCH_IMPLEMENTATION.md** - Architecture overview
- **DYNAMIC_SEARCH_INTEGRATION_GUIDE.md** - Step-by-step integration
- **DYNAMIC_SEARCH_SUMMARY.md** - Complete summary

## 🎓 Learning Path

1. Read DYNAMIC_SEARCH_SUMMARY.md (5 min)
2. Review location_service.dart code (10 min)
3. Review dynamic_search_service.dart code (10 min)
4. Follow DYNAMIC_SEARCH_INTEGRATION_GUIDE.md (30 min)
5. Integrate with one screen (30 min)
6. Test thoroughly (30 min)

Total: ~2 hours to full integration

---

**Status:** ✅ Ready to implement
**Services:** ✅ Created and tested
**Documentation:** ✅ Complete
**Next Step:** Integration with dashboard_screen.dart
