import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import '../../models/event.dart';
import '../../models/user_profile.dart';
import '../../services/supabase_service.dart';
import '../event_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  List<Event> _searchResults = [];
  List<UserProfile> _organizerResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _currentQuery = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  final List<Map<String, String>> _eventPosters = [
    {
      'title': 'TIDAL RAVE',
      'imageUrl': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300',
    },
    {
      'title': 'Face Paint Festival',
      'imageUrl': 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=300',
    },
    {
      'title': 'Dark Vibes',
      'imageUrl': 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=300',
    },
    {
      'title': 'MADE IN LAGOS',
      'imageUrl': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300',
    },
    {
      'title': 'BURNA BOY LIVE',
      'imageUrl': 'https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?w=300',
    },
    {
      'title': 'WIZKID ESSENCE',
      'imageUrl': 'https://images.unsplash.com/photo-1460723237483-7a6dc9d0b212?w=300',
    },
    {
      'title': 'Lagos Vibes',
      'imageUrl': 'https://images.unsplash.com/photo-1493676304819-0d7a8d026dcf?w=300',
    },
    {
      'title': 'Neon Nights',
      'imageUrl': 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=300',
    },
    {
      'title': 'Street Party',
      'imageUrl': 'https://images.unsplash.com/photo-1516719223973-4c0b4a9e40db?w=300',
    },
    {
      'title': 'Concert Lights',
      'imageUrl': 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=300',
    },
    {
      'title': 'Festival Crowd',
      'imageUrl': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300',
    },
    {
      'title': 'Stage Performance',
      'imageUrl': 'https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?w=300',
    },
    {
      'title': 'Electric Dance',
      'imageUrl': 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=300',
    },
    {
      'title': 'Party Lights',
      'imageUrl': 'https://images.unsplash.com/photo-1493676304819-0d7a8d026dcf?w=300',
    },
    {
      'title': 'Music Festival',
      'imageUrl': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300',
    },
  ];

  Timer? _debounceTimer;

  Future<void> _performSearch(String query) async {
    // Debounce search to avoid too many API calls
    _debounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _organizerResults.clear();
        _hasSearched = false;
        _currentQuery = '';
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      
      setState(() {
        _isSearching = true;
        _currentQuery = query.trim();
      });

      try {
        final results = await Future.wait([
          SupabaseService.searchEvents(query.trim()),
          SupabaseService.searchOrganizers(query.trim()),
        ]);

        if (mounted) {
          setState(() {
            _searchResults = results[0] as List<Event>;
            _organizerResults = results[1] as List<UserProfile>;
            _hasSearched = true;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Search failed: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSearching = false;
          });
        }
      }
    });
  }

  void _navigateToEventDetail(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search events, organizers...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey[600],
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                          )
                        : Icon(
                            Icons.mic,
                            color: Colors.grey[600],
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                  onChanged: _performSearch,
                ),
              ),
            ),
            
            // Search Results or Featured Events Grid
            if (_hasSearched && (_searchResults.isNotEmpty || _organizerResults.isNotEmpty)) ...[
              // Search Results Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  tabs: [
                    Tab(text: 'Events (${_searchResults.length})'),
                    Tab(text: 'Organizers (${_organizerResults.length})'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Search Results Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEventResults(),
                    _buildOrganizerResults(),
                  ],
                ),
              ),
            ] else if (_isSearching) ...[
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else ...[
              // Default grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _eventPosters.length,
                    itemBuilder: (context, index) {
                      final poster = _eventPosters[index];
                      
                      return GestureDetector(
                        onTap: () {
                          // Handle poster tap
                          _showEventDetails(context, poster);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: poster['imageUrl']!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  color: Colors.white,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEventResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('No events found'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final event = _searchResults[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildOrganizerResults() {
    if (_organizerResults.isEmpty) {
      return const Center(
        child: Text('No organizers found'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _organizerResults.length,
      itemBuilder: (context, index) {
        final organizer = _organizerResults[index];
        return _buildOrganizerCard(organizer);
      },
    );
  }

  Widget _buildEventCard(Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => _navigateToEventDetail(event),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: event.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (event.organizerName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'by ${event.organizerName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                    if (event.location != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.location!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (event.ticketPrice != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '\$${event.ticketPrice!.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrganizerCard(UserProfile organizer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: organizer.avatarUrl != null
                ? CachedNetworkImageProvider(organizer.avatarUrl!)
                : null,
            child: organizer.avatarUrl == null
                ? const Icon(Icons.person, size: 30)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  organizer.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ORGANIZER',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (organizer.bio != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    organizer.bio!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(BuildContext context, Map<String, String> poster) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Event image
              Container(
                height: 300,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: poster['imageUrl']!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Event details
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poster['title']!,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Text(
                        'December 25, 2024 • 8:00 PM',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Lagos, Nigeria',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Text(
                        'About Event',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Experience an unforgettable night of music, lights, and energy. Join thousands of music lovers for this epic event featuring top artists and DJs.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Buy Ticket Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showTicketPurchase(context, poster);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Buy Ticket - \$25',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTicketPurchase(BuildContext context, Map<String, String> poster) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Purchase Ticket',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poster['title']!,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Price: \$25.00'),
            const SizedBox(height: 16),
            const Text('This ticket will be linked to your NFC wristband. Make sure to bring your wristband to the event for entry.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPurchaseSuccess(context, poster);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Purchase'),
          ),
        ],
      ),
    );
  }

  void _showPurchaseSuccess(BuildContext context, Map<String, String> poster) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Ticket Purchased!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your ticket for ${poster['title']} has been successfully purchased and linked to your NFC wristband.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'NFC UID: A1B2C3D4',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                backgroundColor: Colors.grey[100],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
}