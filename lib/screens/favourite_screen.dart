import 'package:flutter/material.dart';
import 'package:risdi/model/model.dart';
import 'package:risdi/screens/stakeholder_view.dart';
import 'package:risdi/screens/stakeholder_list_screen.dart';
import 'package:risdi/services/stakeholder_cache_service.dart';
import 'package:risdi/services/app_state_service.dart';
class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen({super.key});

  @override
  State<FavouriteScreen> createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen> {
  late StakeholderCacheService _cacheService;
  late AppStateService _appStateService;
  List<Stakeholder> favorites = [];
  List<Stakeholder> filteredFavorites = [];
  bool isLoading = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cacheService = StakeholderCacheService();
    _appStateService = AppStateService();
    _loadFavorites();
    _appStateService.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    _appStateService.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    // Reload favorites when app state changes (favorite count updated)
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    // Load all stakeholders
    final allStakeholders = _cacheService.getAllStakeholders();

    // Filter to only favorited ones
    final favoriteNames = _cacheService.getAllFavorites();
    final favStakeholders = allStakeholders
        .where((s) => favoriteNames.contains(s.fullName))
        .toList();

    setState(() {
      favorites = favStakeholders;
      filteredFavorites = favStakeholders;
    });
  }

  void _filterFavorites(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredFavorites = favorites;
      } else {
        filteredFavorites = favorites
            .where((stakeholder) =>
                stakeholder.fullName
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                stakeholder.association
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                stakeholder.phoneNumber
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                stakeholder.email.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _removeFavorite(Stakeholder stakeholder) async {
    // Remove from Hive cache
    await _cacheService.removeFavorite(stakeholder.fullName);

    // Update app state
    _appStateService.decrementFavoritesCount();

    setState(() {
      favorites.removeWhere((s) => s.fullName == stakeholder.fullName);
      filteredFavorites.removeWhere((s) => s.fullName == stakeholder.fullName);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${stakeholder.fullName} removed from favorites'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Sync with Firestore in background
    try {
      // Note: FavoriteService.removeFavorite requires a Favorite model
      // We'll skip Firestore sync here since removal is handled via StakeholderView
    } catch (e) {
      print('Error removing favorite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Favourites',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtitle
            Text(
              "Your bookmarked stakeholders for quick access",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Search bar
            TextField(
              onChanged: _filterFavorites,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.pink),
                hintText: "Search favorites...",
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.pink, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Content
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filteredFavorites.isEmpty)
              _buildEmptyState()
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Favorites (${filteredFavorites.length})",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _loadFavorites,
                        icon: Icon(Icons.refresh, color: Colors.pink),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredFavorites.length,
                    itemBuilder: (context, index) {
                      final favorite = filteredFavorites[index];
                      return _buildFavoriteTile(favorite);
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty ? "No Favorites Yet" : "No Matches Found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? "Start browsing stakeholders and mark your favorites for quick access"
                : "Try searching with a different query",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const StakeholderListScreen(),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.explore),
            label: const Text("Explore Stakeholders"),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteTile(Stakeholder stakeholder) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => StakeholderView(holder: stakeholder),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.pink.withOpacity(0.1),
                    radius: 24,
                    child: Text(
                      (stakeholder.fullName).isNotEmpty
                          ? stakeholder.fullName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.pink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stakeholder.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stakeholder.association,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${stakeholder.lg}, ${stakeholder.ward}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _removeFavorite(stakeholder),
                icon: const Icon(Icons.favorite, color: Colors.pink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
