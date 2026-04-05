import 'package:flutter/material.dart';
import 'package:risdi/model/model.dart';
import 'package:risdi/component/recent_stakeholders_manager.dart';
import 'package:risdi/firebase_services/favorite_service.dart';
import 'package:risdi/services/stakeholder_cache_service.dart';
import 'package:risdi/services/app_state_service.dart';
import 'package:risdi/model/stakeholder_contact_model.dart';
import 'package:url_launcher/url_launcher.dart';

class StakeholderView extends StatefulWidget {
  const StakeholderView({super.key, required this.holder});

  final Stakeholder holder;

  @override
  State<StakeholderView> createState() => _StakeholderViewState();
}

class _StakeholderViewState extends State<StakeholderView>
    with SingleTickerProviderStateMixin {
  final FavoriteService _favoriteService = FavoriteService();
  late StakeholderCacheService _cacheService;
  bool _isFavorite = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _cacheService = StakeholderCacheService();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    // Add this stakeholder to recent views when the screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RecentStakeholdersManager.addToRecentStakeholders(widget.holder);
    });
    _initializeFavoriteStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeFavoriteStatus() async {
    // Check Hive cache first (instant, synchronous)
    bool isFavInCache = _cacheService.isFavorite(widget.holder.fullName);

    // Also check Firestore for sync (in background)
    final isFavInFirestore = await _favoriteService.isFavorite(widget.holder);

    // Use the most up-to-date value, preferring Firestore if they differ
    bool isFav = isFavInFirestore;

    // If Firestore differs from cache, update cache to keep them in sync
    if (isFav != isFavInCache) {
      if (isFav) {
        await _cacheService.addFavorite(widget.holder.fullName);
      } else {
        await _cacheService.removeFavorite(widget.holder.fullName);
      }
    }

    setState(() {
      _isFavorite = isFav;
      if (_isFavorite) {
        _animationController.forward();
      }
    });
  }

  Future<void> _toggleFavorite() async {
    // Update Hive cache immediately (instant local feedback)
    if (_isFavorite) {
      await _cacheService.removeFavorite(widget.holder.fullName);
    } else {
      await _cacheService.addFavorite(widget.holder.fullName);
    }

    // Toggle state for immediate visual feedback
    final newState = !_isFavorite;
    setState(() {
      _isFavorite = newState;
    });

    // Update AppStateService to keep navbar badge in sync
    final appStateService = AppStateService();
    if (newState) {
      appStateService.incrementFavoritesCount();
    } else {
      appStateService.decrementFavoritesCount();
    }

    // Animate the heart icon
    if (newState) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    // Show success popup dialog
    _showFavoriteDialog(newState);

    // Update Firestore in background (eventual consistency)
    try {
      final result = await _favoriteService.toggleFavorite(widget.holder);
      if (result != null && result != newState) {
        // If Firestore result differs from local state, sync cache
        if (result) {
          await _cacheService.addFavorite(widget.holder.fullName);
          appStateService.incrementFavoritesCount();
        } else {
          await _cacheService.removeFavorite(widget.holder.fullName);
          appStateService.decrementFavoritesCount();
        }
        if (mounted) {
          setState(() {
            _isFavorite = result;
          });
        }
      }
    } catch (e) {
      // Firestore sync failed, but local cache is still updated
      print('Error syncing favorite with Firestore: $e');
    }
  }

  void _showFavoriteDialog(bool isFavorited) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isFavorited ? Colors.red.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  isFavorited ? Icons.favorite : Icons.favorite_outline,
                  size: 48,
                  color: isFavorited ? Colors.red : Colors.orange,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isFavorited ? 'Added to Favorites' : 'Removed from Favorites',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isFavorited
                    ? '${widget.holder.fullName} has been saved to your favorites'
                    : '${widget.holder.fullName} has been removed from your favorites',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: isFavorited ? Colors.red : Colors.orange,
              ),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  // Function to launch the phone dialer
  void _launchDialer(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Stakeholder Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: InkWell(
                onTap: _toggleFavorite,
                borderRadius: BorderRadius.circular(24),
                child: ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.2).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_outline,
                    color: _isFavorite ? Colors.red : Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Gradient
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white.withOpacity(0.9), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.holder.fullName.isNotEmpty
                              ? widget.holder.fullName[0].toUpperCase()
                              : 'S',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.holder.fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.holder.association,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Details Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Contact Information Card
                  _buildSectionCard(
                    title: 'Contact Information',
                    icon: Icons.contact_phone,
                    children: [
                      _buildDetailTile(
                        icon: Icons.phone,
                        label: 'Phone Number',
                        value: widget.holder.phoneNumber,
                        onTap: () => _launchDialer(widget.holder.phoneNumber),
                        isClickable: true,
                      ),
                      _buildDetailTile(
                        icon: Icons.chat,
                        label: 'WhatsApp',
                        value: widget.holder.whatsappNumber,
                      ),
                      _buildDetailTile(
                        icon: Icons.email,
                        label: 'Email',
                        value: widget.holder.email,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location Information Card
                  _buildSectionCard(
                    title: 'Location Information',
                    icon: Icons.location_on,
                    children: [
                      _buildDetailTile(
                        icon: Icons.map,
                        label: 'State',
                        value: widget.holder.state,
                      ),
                      _buildDetailTile(
                        icon: Icons.location_city,
                        label: 'Local Government',
                        value: widget.holder.lg,
                      ),
                      _buildDetailTile(
                        icon: Icons.place,
                        label: 'Ward',
                        value: widget.holder.ward,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Administrative Information Card
                  _buildSectionCard(
                    title: 'Administrative Information',
                    icon: Icons.admin_panel_settings,
                    children: [
                      _buildDetailTile(
                        icon: Icons.business,
                        label: 'Association',
                        value: widget.holder.association,
                      ),
                      _buildDetailTile(
                        icon: Icons.layers,
                        label: 'Level of Administration',
                        value: widget.holder.levelOfAdministration,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    bool isClickable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[600], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isClickable ? Colors.blue : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              if (isClickable) Icon(Icons.phone, color: Colors.blue, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
