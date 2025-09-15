import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/event.dart';
import '../models/ticket.dart';
import '../models/story.dart';
import '../models/event_interaction.dart';
import 'dart:io';

class SupabaseService {
  static const String supabaseUrl = 'https://eagslqcdnmimrkqxpfwn.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVhZ3NscWNkbm1pbXJrcXhwZnduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY4MTU4MzgsImV4cCI6MjA3MjM5MTgzOH0.DFHSbUVEP1lKdE3RmJTnetQuW9FECV-2BT4mq6koaPQ';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // Authentication
  static Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static User? get currentUser => client.auth.currentUser;
  static String? get currentUserId => client.auth.currentUser?.id;

    // Profile Management
  static Future<UserProfile?> getUserProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response != null) {
      return UserProfile.fromJson(response);
    }
    return null;
  }
  static Future<void> updateUserProfile(UserProfile profile) async {
    await client
        .from('profiles')
        .update(profile.toJson())
        .eq('user_id', profile.userId);
  }

  // Events Management
  static Future<List<Event>> getEvents() async {
    final userId = currentUserId;
    
    final response = await client
        .from('events')
        .select('''
          *,
          organizer:profiles!organizer_id(name, avatar_url, bio)
        ''')
        .eq('status', 'published')
        .order('created_at', ascending: false);

    final events = (response as List).map((json) {
      final organizer = json['organizer'] as Map<String, dynamic>?;
      json['organizer_name'] = organizer?['name'];
      json['organizer_image_url'] = organizer?['avatar_url'];
      
      // Get interaction states for current user
      if (userId != null) {
        json['is_liked_by_user'] = false;
        json['is_bookmarked_by_user'] = false;
      }
      
      return Event.fromJson(json);
    }).toList();

    // Get user interactions if logged in
    if (userId != null && events.isNotEmpty) {
      final eventIds = events.map((e) => e.id).toList();
      
      // Get likes
      final likes = await client
          .from('event_interactions')
          .select('event_id')
          .eq('user_id', userId)
          .eq('type', 'like')
          .inFilter('event_id', eventIds);
      
      final likedEventIds = Set<String>.from((likes as List).map((l) => l['event_id']));
      
      // Get bookmarks
      final bookmarks = await client
          .from('bookmarks')
          .select('event_id')
          .eq('user_id', userId)
          .inFilter('event_id', eventIds);
      
      final bookmarkedEventIds = Set<String>.from((bookmarks as List).map((b) => b['event_id']));
      
      // Update events with user interaction states
      for (var event in events) {
        event.isLikedByUser = likedEventIds.contains(event.id);
        event.isBookmarkedByUser = bookmarkedEventIds.contains(event.id);
      }
    }
    
    return events;
  }

  static Future<List<Event>> getFeedEvents() async {
    return getEvents(); // Use the enhanced getEvents method
  }

  static Future<List<Event>> getEventsByOrganizer(String organizerId) async {
    final response = await client
        .from('events')
        .select('''
          *,
          organizer:profiles!organizer_id(name, avatar_url, bio)
        ''')
        .eq('organizer_id', organizerId)
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      final organizer = json['organizer'] as Map<String, dynamic>?;
      json['organizer_name'] = organizer?['name'];
      json['organizer_image_url'] = organizer?['avatar_url'];
      return Event.fromJson(json);
    }).toList();
  }

  static Future<Event> createEvent(Event event) async {
    final response = await client
        .from('events')
        .insert(event.toJson())
        .select()
        .single();

    return Event.fromJson(response);
  }

  static Future<void> updateEvent(Event event) async {
    await client
        .from('events')
        .update(event.toJson())
        .eq('id', event.id);
  }

  static Future<void> deleteEvent(String eventId) async {
    await client
        .from('events')
        .delete()
        .eq('id', eventId);
  }

  // Tickets Management
  static Future<List<Ticket>> getTicketsByUser(String userId) async {
    final response = await client
        .from('tickets')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Ticket.fromJson(json))
        .toList();
  }

  static Future<List<Ticket>> getTicketsByEvent(String eventId) async {
    final response = await client
        .from('tickets')
        .select()
        .eq('event_id', eventId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Ticket.fromJson(json))
        .toList();
  }

  static Future<Ticket?> getTicketByUid(String uid) async {
    final response = await client
        .from('tickets')
        .select()
        .eq('uid', uid)
        .maybeSingle();

    if (response != null) {
      return Ticket.fromJson(response);
    }
    return null;
  }

  static Future<Ticket> createTicket(Ticket ticket) async {
    final response = await client
        .from('tickets')
        .insert(ticket.toJson())
        .select()
        .single();

    return Ticket.fromJson(response);
  }

  static Future<void> updateTicketStatus(String ticketId, String status) async {
    final data = {'status': status};
    if (status == 'checked_in') {
      data['checked_in_at'] = DateTime.now().toIso8601String();
    }

    await client
        .from('tickets')
        .update(data)
        .eq('id', ticketId);
  }

  // Storage for images
  static Future<String> uploadImage(File file, String bucket, String path) async {
    final response = await client.storage
        .from(bucket)
        .upload(path, file);

    return client.storage
        .from(bucket)
        .getPublicUrl(path);
  }

  // Analytics with revenue calculation
  static Future<Map<String, dynamic>> getOrganizerStats(String organizerId) async {
    final eventsResponse = await client
        .from('events')
        .select('id, ticket_price, current_attendees')
        .eq('organizer_id', organizerId);
    
    final events = eventsResponse as List;
    final eventIds = events.map((e) => e['id']).toList();
    
    int totalTickets = 0;
    int checkedInTickets = 0;
    double totalRevenue = 0.0;
    
    if (eventIds.isNotEmpty) {
      final ticketsResponse = await client
          .from('tickets')
          .select('status, event_id')
          .inFilter('event_id', eventIds);
      
      final tickets = ticketsResponse as List;
      totalTickets = tickets.length;
      checkedInTickets = tickets.where((t) => t['status'] == 'checked_in').length;
      
      // Calculate total revenue based on tickets sold and event prices
      for (final ticket in tickets) {
        final event = events.firstWhere((e) => e['id'] == ticket['event_id'], 
            orElse: () => null);
        if (event != null && event['ticket_price'] != null) {
          totalRevenue += (event['ticket_price'] as num).toDouble();
        }
      }
    }

    return {
      'total_events': events.length,
      'total_tickets': totalTickets,
      'checked_in_tickets': checkedInTickets,
      'total_revenue': totalRevenue,
    };
  }

  // Stories Management
  static Future<List<Story>> getActiveStories() async {
    final response = await client
        .from('stories')
        .select('''
          *,
          organizer:profiles!organizer_id(name, avatar_url),
          event:events!event_id(title)
        ''')
        .eq('is_active', true)
        .gte('expires_at', DateTime.now().toIso8601String())
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      final organizer = json['organizer'] as Map<String, dynamic>?;
      final event = json['event'] as Map<String, dynamic>?;
      json['organizer_name'] = organizer?['name'];
      json['organizer_avatar_url'] = organizer?['avatar_url'];
      json['event_title'] = event?['title'];
      return Story.fromJson(json);
    }).toList();
  }

  static Future<List<Story>> getStoriesByOrganizer(String organizerId) async {
    final response = await client
        .from('stories')
        .select()
        .eq('organizer_id', organizerId)
        .eq('is_active', true)
        .gte('expires_at', DateTime.now().toIso8601String())
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Story.fromJson(json))
        .toList();
  }

  static Future<Story> createStory(Story story) async {
    final response = await client
        .from('stories')
        .insert(story.toJson())
        .select()
        .single();

    return Story.fromJson(response);
  }

  static Future<void> incrementStoryViews(String storyId) async {
    await client
        .from('stories')
        .update({'view_count': 'view_count + 1'})
        .eq('id', storyId);
  }

  // Event Interactions
  static Future<bool> toggleEventLike(String eventId) async {
    final userId = currentUserId;
    if (userId == null) return false;

    // Check if already liked
    final existing = await client
        .from('event_interactions')
        .select()
        .eq('user_id', userId)
        .eq('event_id', eventId)
        .eq('type', 'like')
        .maybeSingle();

    if (existing != null) {
      // Unlike
      await client
          .from('event_interactions')
          .delete()
          .eq('id', existing['id']);
      return false;
    } else {
      // Like
      await client
          .from('event_interactions')
          .insert({
            'user_id': userId,
            'event_id': eventId,
            'type': 'like',
            'created_at': DateTime.now().toIso8601String(),
          });
      return true;
    }
  }

  static Future<bool> toggleEventBookmark(String eventId) async {
    final userId = currentUserId;
    if (userId == null) return false;

    final existing = await client
        .from('bookmarks')
        .select()
        .eq('user_id', userId)
        .eq('event_id', eventId)
        .maybeSingle();

    if (existing != null) {
      // Remove bookmark
      await client
          .from('bookmarks')
          .delete()
          .eq('id', existing['id']);
      return false;
    } else {
      // Add bookmark
      await client
          .from('bookmarks')
          .insert({
            'user_id': userId,
            'event_id': eventId,
            'created_at': DateTime.now().toIso8601String(),
          });
      return true;
    }
  }

  static Future<void> recordEventShare(String eventId) async {
    final userId = currentUserId;
    if (userId == null) return;

    await client
        .from('event_interactions')
        .insert({
          'user_id': userId,
          'event_id': eventId,
          'type': 'share',
          'created_at': DateTime.now().toIso8601String(),
        });
  }

  static Future<List<EventInteraction>> getEventComments(String eventId) async {
    final response = await client
        .from('event_interactions')
        .select('''
          *,
          user:profiles!user_id(name, avatar_url)
        ''')
        .eq('event_id', eventId)
        .eq('type', 'comment')
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      final user = json['user'] as Map<String, dynamic>?;
      json['user_name'] = user?['name'];
      json['user_avatar_url'] = user?['avatar_url'];
      return EventInteraction.fromJson(json);
    }).toList();
  }

  static Future<EventInteraction> addEventComment(String eventId, String content) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await client
        .from('event_interactions')
        .insert({
          'user_id': userId,
          'event_id': eventId,
          'type': 'comment',
          'content': content,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return EventInteraction.fromJson(response);
  }

  // Search functionality
  static Future<List<Event>> searchEvents(String query) async {
    final response = await client
        .from('events')
        .select('''
          *,
          organizer:profiles!organizer_id(name, avatar_url)
        ''')
        .or('title.ilike.%$query%,description.ilike.%$query%,location.ilike.%$query%,venue.ilike.%$query%')
        .eq('status', 'published')
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      final organizer = json['organizer'] as Map<String, dynamic>?;
      json['organizer_name'] = organizer?['name'];
      json['organizer_image_url'] = organizer?['avatar_url'];
      return Event.fromJson(json);
    }).toList();
  }

  static Future<List<UserProfile>> searchOrganizers(String query) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('role', 'organizer')
        .ilike('name', '%$query%')
        .order('name', ascending: true);

    return (response as List)
        .map((json) => UserProfile.fromJson(json))
        .toList();
  }

  // Enhanced Profile Features
  static Future<Map<String, dynamic>> getUserStats(String userId) async {
    final ticketsCount = await client
        .from('tickets')
        .select('*')
        .eq('user_id', userId);

    final eventsCreatedCount = await client
        .from('events')
        .select('*')
        .eq('organizer_id', userId);

    final likesGivenCount = await client
        .from('event_interactions')
        .select('*')
        .eq('user_id', userId)
        .eq('type', 'like');

    return {
      'total_tickets': (ticketsCount as List).length,
      'events_created': (eventsCreatedCount as List).length,
      'likes_given': (likesGivenCount as List).length,
    };
  }

  static Future<List<Event>> getUserBookmarkedEvents(String userId) async {
    final response = await client
        .from('bookmarks')
        .select('''
          event:events(
            *,
            organizer:profiles!organizer_id(name, avatar_url)
          )
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => item['event'])
        .where((event) => event != null)
        .map((json) {
          final organizer = json['organizer'] as Map<String, dynamic>?;
          json['organizer_name'] = organizer?['name'];
          json['organizer_image_url'] = organizer?['avatar_url'];
          return Event.fromJson(json);
        }).toList();
  }

  // Real-time subscriptions for live updates
  static Stream<List<Event>> subscribeToFeedEvents() {
    return client
        .from('events')
        .stream(primaryKey: ['id'])
        .eq('status', 'published')
        .order('created_at', ascending: false)
        .asyncMap((data) async {
          final events = <Event>[];
          for (final json in data) {
            // Get organizer info for each event
            final organizerResponse = await client
                .from('profiles')
                .select('name, avatar_url')
                .eq('id', json['organizer_id'])
                .maybeSingle();
            
            if (organizerResponse != null) {
              json['organizer_name'] = organizerResponse['name'];
              json['organizer_image_url'] = organizerResponse['avatar_url'];
            }
            
            events.add(Event.fromJson(json));
          }
          return events;
        });
  }

  static Stream<List<Story>> subscribeToActiveStories() {
    return client
        .from('stories')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .gte('expires_at', DateTime.now().toIso8601String())
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Story.fromJson(json)).toList());
  }

  static Stream<Map<String, dynamic>> subscribeToOrganizerStats(String organizerId) {
    return client
        .from('events')
        .stream(primaryKey: ['id'])
        .eq('organizer_id', organizerId)
        .asyncMap((events) async {
          final eventIds = events.map((e) => e['id']).toList();
          
          int totalTickets = 0;
          int checkedInTickets = 0;
          double totalRevenue = 0.0;
          
          if (eventIds.isNotEmpty) {
            final ticketsResponse = await client
                .from('tickets')
                .select('status, event_id')
                .inFilter('event_id', eventIds);
            
            final tickets = ticketsResponse as List;
            totalTickets = tickets.length;
            checkedInTickets = tickets.where((t) => t['status'] == 'checked_in').length;
            
            for (final ticket in tickets) {
              final event = events.firstWhere((e) => e['id'] == ticket['event_id'], 
                  orElse: () => {});
              if (event != null && event['ticket_price'] != null) {
                totalRevenue += (event['ticket_price'] as num).toDouble();
              }
            }
          }
          
          return {
            'total_events': events.length,
            'total_tickets': totalTickets,
            'checked_in_tickets': checkedInTickets,
            'total_revenue': totalRevenue,
          };
        });
  }

  // Enhanced profile management with image upload
  static Future<String> uploadProfileImage(File imageFile, String userId) async {
    final fileExt = imageFile.path.split('.').last;
    final fileName = 'profile_$userId.$fileExt';
    
    await client.storage
        .from('profiles')
        .upload(fileName, imageFile, fileOptions: const FileOptions(upsert: true));
    
    return client.storage
        .from('profiles')
        .getPublicUrl(fileName);
  }

  // NFC Management
  static Future<String> generateNfcUid() async {
    // Generate a unique NFC UID
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
    return 'NFC${timestamp.substring(timestamp.length - 8)}$random';
  }

  static Future<bool> linkTicketToNfc(String ticketId, String nfcUid) async {
    try {
      await client
          .from('tickets')
          .update({'uid': nfcUid})
          .eq('id', ticketId);
      return true;
    } catch (e) {
      return false;
    }
  }

    // Settings management
  static Future<void> updateUserSettings(String userId, Map<String, dynamic> settings) async {
    await client
        .from('profiles')
        .update({'preferences': settings})
        .eq('user_id', userId);
  }

  static Future<Map<String, dynamic>> getUserSettings(String userId) async {
    final response = await client
        .from('profiles')
        .select('preferences')
        .eq('user_id', userId)
        .single();
    
    return response['preferences'] ?? {};
  }

  // Payment Integration - Paystack Split Payment
  static Future<Map<String, dynamic>> initializePaystackPayment({
    required String eventId,
    required double amount,
    required String email,
    required String organizerId,
  }) async {
    try {
           // Get organizer's account details
      final organizerResponse = await client
          .from('profiles')
          .select('bank_account, mobile_money')
          .eq('user_id', organizerId)
          .single();
      
      final organizerAccountDetails = organizerResponse['bank_account'] ?? organizerResponse['mobile_money'];
      
      // Calculate split: App takes 20%, Organizer gets 80%
      final appAmount = (amount * 0.20).round();
      final organizerAmount = (amount * 0.80).round();
      
      // Initialize Paystack transaction with split
      final paymentData = {
        'amount': (amount * 100).toInt(), // Paystack expects kobo
        'email': email,
        'subaccount': organizerAccountDetails['subaccount_code'],
        'transaction_charge': appAmount * 100, // App's 20% in kobo
        'metadata': {
          'event_id': eventId,
          'organizer_id': organizerId,
          'app_fee': appAmount,
          'organizer_amount': organizerAmount,
        }
      };
      
      return paymentData;
    } catch (e) {
      throw Exception('Failed to initialize payment: $e');
    }
  }

  // Create organizer subaccount on Paystack
  static Future<String> createOrganizerSubaccount({
    required String organizerId,
    required String businessName,
    required String accountNumber,
    required String bankCode,
    String? mobileMoneyCode,
  }) async {
    try {
      // This would integrate with Paystack API to create subaccount
      // For demo purposes, return a mock subaccount code
      final subaccountCode = 'ACCT_${organizerId.substring(0, 8)}';
      
            // Store subaccount info in organizer profile
      await client
          .from('profiles')
          .update({
            'bank_account': {
              'account_number': accountNumber,
              'bank_code': bankCode,
              'subaccount_code': subaccountCode,
            },
            'mobile_money': mobileMoneyCode != null ? {
              'code': mobileMoneyCode,
              'subaccount_code': subaccountCode,
            } : null,
          })
          .eq('user_id', organizerId);
      
      return subaccountCode;
    } catch (e) {
      throw Exception('Failed to create subaccount: $e');
    }
  }

  // Ticket purchase with real-time updates
  static Future<Ticket> purchaseTicketWithPayment({
    required String eventId,
    required String userId,
    required double amount,
    required String paymentReference,
  }) async {
    try {
      // Generate NFC UID
      final nfcUid = await generateNfcUid();
      
      // Create ticket with payment info
      final ticket = Ticket(
        id: '',
        eventId: eventId,
        userId: userId,
        uid: nfcUid,
        status: 'purchased',
        createdAt: DateTime.now(),
        paymentReference: paymentReference,
        amount: amount,
      );
      
      final response = await client
          .from('tickets')
          .insert(ticket.toJson())
          .select()
          .single();
      
      // Update event attendee count
      await client.rpc('increment_event_attendees', params: {
        'event_id': eventId,
      });
      
      return Ticket.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create ticket: $e');
    }
  }

  // Real-time ticket updates for organizers
  static Stream<List<Ticket>> subscribeToEventTickets(String eventId) {
    return client
        .from('tickets')
        .stream(primaryKey: ['id'])
        .eq('event_id', eventId)
        .map((data) => data.map((json) => Ticket.fromJson(json)).toList());
  }

  static Future<void> createUserProfile(UserProfile profile) async {}
}

extension on SupabaseStreamBuilder {
  gte(String s, String iso8601string) {}
}