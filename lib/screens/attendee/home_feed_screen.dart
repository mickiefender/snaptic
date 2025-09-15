import 'dart:async' show StreamSubscription;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:snaptic/screens/organizer/create_event_screen.dart';
import '../../providers/events_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/event.dart';
import '../../models/story.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../event_detail_screen.dart';
import '../organizer/create_story_screen.dart';
import 'search_screen.dart';
import '../profile_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  late TabController _storyTabController;
  
  List<Event> _feedEvents = [];
  List<Story> _stories = [];
  bool _isLoadingEvents = true;
  bool _isLoadingStories = true;

  final List<Map<String, String>> _sampleEvents = [
    {
      'title': 'TIDAL RAVE',
      'subtitle': 'The New Wave SEQUEL',
      'description': 'The music takes control & the night wave sets Ujira Beats...',
      'imageUrl': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500',
      'location': 'Lagos, Nigeria',
      'date': '2024-12-25',
    },
    {
      'title': 'MADE IN LAGOS',
      'subtitle': 'Concert Experience',
      'description': 'ARE YOU READY? It\'s the biggest show in Ghana and you don\'t wanna miss out...',
      'imageUrl': 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=500',
      'location': 'Accra, Ghana',
      'date': '2024-12-28',
    },
    {
      'title': 'BURNA BOY LIVE',
      'subtitle': 'African Giant Tour',
      'description': 'Experience the African Giant live in concert with special guest appearances...',
      'imageUrl': 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=500',
      'location': 'Johannesburg, SA',
      'date': '2024-12-30',
    },
    {
      'title': 'WIZKID ESSENCE',
      'subtitle': 'More Love Less Ego',
      'description': 'Join Wizkid for an unforgettable night of Afrobeats and good vibes...',
      'imageUrl': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=500',
      'location': 'London, UK',
      'date': '2025-01-02',
    },
    {
      'title': 'DAVIDO CONCERT',
      'subtitle': 'Timeless Tour',
      'description': 'OBO brings the party to you with hits from Timeless and classic favorites...',
      'imageUrl': 'https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?w=500',
      'location': 'Atlanta, USA',
      'date': '2025-01-05',
    },
  ];

  @override
  void initState() {
    super.initState();
    _storyTabController = TabController(length: 2, vsync: this);
    _loadFeedData();
  }

  @override
  void dispose() {
    _storyTabController.dispose();
    _eventsSubscription?.cancel();
    _storiesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadFeedData() async {
    await Future.wait([
      _loadFeedEvents(),
      _loadStories(),
    ]);
  }

  Future<void> _loadFeedEvents() async {
    try {
      final events = await SupabaseService.getFeedEvents();
      if (mounted) {
        setState(() {
          _feedEvents = events;
          _isLoadingEvents = false;
        });
        
        // Setup real-time subscription after initial load
        _setupRealTimeSubscriptions();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingEvents = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load events: $e')),
        );
      }
    }
  }

  StreamSubscription? _eventsSubscription;
  StreamSubscription? _storiesSubscription;

  void _setupRealTimeSubscriptions() {
    // Cancel existing subscriptions
    _eventsSubscription?.cancel();
    _storiesSubscription?.cancel();

    // Subscribe to real-time events updates
    _eventsSubscription = SupabaseService.subscribeToFeedEvents().listen(
      (events) {
        if (mounted) {
          setState(() {
            _feedEvents = events;
          });
        }
      },
      onError: (error) {
        debugPrint('Events subscription error: $error');
      },
    );

    // Subscribe to real-time stories updates
    _storiesSubscription = SupabaseService.subscribeToActiveStories().listen(
      (stories) {
        if (mounted) {
          setState(() {
            _stories = stories;
            _isLoadingStories = false;
          });
        }
      },
      onError: (error) {
        debugPrint('Stories subscription error: $error');
      },
    );
  }

  Future<void> _loadStories() async {
    try {
      final stories = await SupabaseService.getActiveStories();
      if (mounted) {
        setState(() {
          _stories = stories;
          _isLoadingStories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStories = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          _buildHomeFeed(),
          const SearchScreen(),
          Container(), // Add/Create placeholder
          Container(), // Search placeholder - moved to second position
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Consumer<AuthProvider>(
        builder: (context, authProvider, child) => CustomBottomNav(
          currentIndex: _currentIndex,
          isOrganizer: authProvider.isOrganizer,
          onTap: (index) {
            if (index == 2 && authProvider.isOrganizer) {
              // Navigate to create story for organizers
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateEventScreen(),
                ),
              ).then((_) => _loadStories()); // Refresh stories after creation
              return;
            }
            setState(() {
              _currentIndex = index;
            });
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
      ),
    );
  }

  Widget _buildHomeFeed() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header with user info and bell
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Snaptic',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) => Text(
                          authProvider.currentUser?.email ?? 'snaptic.app',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  child: Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  authProvider.currentUser?.name.split(' ').first ?? 'User',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Stories Section
            _buildStoriesSection(),

            const SizedBox(height: 16),

            // Events Feed
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadFeedData,
                child: _isLoadingEvents
                    ? _buildLoadingShimmer()
                    : _feedEvents.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: _feedEvents.length,
                            itemBuilder: (context, index) => _buildEventCard(_feedEvents[index]),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesSection() {
    return SizedBox(
      height: 100,
      child: _isLoadingStories
          ? _buildStoriesLoading()
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _stories.length + 1, // +1 for "Add Story" button
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildAddStoryButton();
                }
                return _buildStoryItem(_stories[index - 1]);
              },
            ),
    );
  }

  Widget _buildStoriesLoading() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: const CircleAvatar(radius: 30),
            ),
            const SizedBox(height: 4),
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 60,
                height: 12,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddStoryButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isOrganizer) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateStoryScreen(),
                ),
              ).then((_) => _loadStories());
            },
            child: Column(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add Story',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoryItem(Story story) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => _viewStory(story),
        child: Column(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.pink, Colors.orange],
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundImage: CachedNetworkImageProvider(story.imageUrl),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              story.caption.length > 12 ? '${story.caption.substring(0, 12)}...' : story.caption,
              style: Theme.of(context).textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: const CircleAvatar(radius: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          height: 16,
                          width: double.infinity,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          height: 12,
                          width: 200,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No events available',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull to refresh or check back later',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  void _viewStory(Story story) {
    // Implement story viewer
    SupabaseService.incrementStoryViews(story.id);
    // TODO: Navigate to story viewer
  }

  Future<void> _toggleEventLike(Event event) async {
    try {
      await SupabaseService.toggleEventLike(event.id);
      _loadFeedEvents(); // Refresh to get updated like status
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle like: $e')),
      );
    }
  }

  Future<void> _toggleEventBookmark(Event event) async {
    try {
      await SupabaseService.toggleEventBookmark(event.id);
      _loadFeedEvents(); // Refresh to get updated bookmark status
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle bookmark: $e')),
      );
    }
  }

  Future<void> _shareEvent(Event event) async {
    try {
      await SupabaseService.recordEventShare(event.id);
      Share.share(
        '🎉 Check out ${event.title}!\n\n'
        '📅 ${DateFormat('MMM dd, yyyy • hh:mm a').format(event.date)}\n'
        '📍 ${event.location ?? 'Location TBA'}\n\n'
        '${event.description}\n\n'
        'Get your tickets now on Snaptic!',
        subject: event.title,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share event: $e')),
      );
    }
  }

  void _navigateToEventDetail(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    ).then((_) => _loadFeedEvents()); // Refresh when returning
  }

  Widget _buildEventCard(Event event) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event organizer info
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: event.organizerImageUrl != null
                      ? CachedNetworkImageProvider(event.organizerImageUrl!)
                      : null,
                  child: event.organizerImageUrl == null
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.organizerName ?? 'Unknown Organizer',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        event.location ?? 'Location TBA',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
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
                const SizedBox(width: 8),
                Icon(
                  Icons.more_vert,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),

          // Event image
          GestureDetector(
            onTap: () => _navigateToEventDetail(event),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: event.imageUrl,
                    height: 400,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 400,
                        color: Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 400,
                      color: Colors.grey[200],
                      child: const Icon(Icons.error),
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Event details overlay
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(event.date),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Category badge
                  if (event.category != null)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.category!.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleEventLike(event),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        event.isLikedByUser ? Icons.favorite : Icons.favorite_border,
                        color: event.isLikedByUser 
                            ? Colors.red 
                            : Theme.of(context).colorScheme.onSurface,
                        size: 24,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.likeCount.toString(),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => _navigateToEventDetail(event),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 24,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.commentCount.toString(),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => _shareEvent(event),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.share,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 24,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.shareCount.toString(),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _toggleEventBookmark(event),
                  child: Icon(
                    event.isBookmarkedByUser ? Icons.bookmark : Icons.bookmark_border,
                    color: event.isBookmarkedByUser 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // Event info
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.currentAttendees > 0)
                  Text(
                    '${event.currentAttendees} people attending',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _navigateToEventDetail(event),
                  child: Text(
                    event.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                if (event.commentCount > 0)
                  GestureDetector(
                    onTap: () => _navigateToEventDetail(event),
                    child: Text(
                      'View all ${event.commentCount} comments',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                Text(
                  DateFormat('dd MMM yyyy').format(event.createdAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}