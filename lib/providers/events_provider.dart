import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/event.dart';
import '../models/story.dart';
import '../services/supabase_service.dart';

class EventsProvider with ChangeNotifier {
  List<Event> _events = [];
  List<Story> _stories = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _eventsSubscription;
  StreamSubscription? _storiesSubscription;

  List<Event> get events => _events;
  List<Story> get stories => _stories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchEvents() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final results = await Future.wait([
        SupabaseService.getEvents(),
        SupabaseService.getActiveStories(),
      ]);
      
      _events = results[0] as List<Event>;
      _stories = results[1] as List<Story>;
      
      // Setup real-time subscriptions
      _setupRealTimeSubscriptions();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchEventsByOrganizer(String organizerId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _events = await SupabaseService.getEventsByOrganizer(organizerId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createEvent(Event event) async {
    try {
      _isLoading = true;
      notifyListeners();

      final newEvent = await SupabaseService.createEvent(event);
      _events.insert(0, newEvent);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateEvent(Event event) async {
    try {
      await SupabaseService.updateEvent(event);
      
      final index = _events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _events[index] = event;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    try {
      await SupabaseService.deleteEvent(eventId);
      
      _events.removeWhere((e) => e.id == eventId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setupRealTimeSubscriptions() {
    // Cancel existing subscriptions
    _eventsSubscription?.cancel();
    _storiesSubscription?.cancel();

    // Subscribe to events changes
    _eventsSubscription = SupabaseService.subscribeToFeedEvents().listen(
      (events) {
        _events = events;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );

    // Subscribe to stories changes
    _storiesSubscription = SupabaseService.subscribeToActiveStories().listen(
      (stories) {
        _stories = stories;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  Future<bool> toggleEventLike(String eventId) async {
    try {
      final isLiked = await SupabaseService.toggleEventLike(eventId);
      
      // Update local state
      final eventIndex = _events.indexWhere((e) => e.id == eventId);
      if (eventIndex != -1) {
        final event = _events[eventIndex];
        event.isLikedByUser = isLiked;
        // The like count will be updated via real-time subscription
        notifyListeners();
      }
      
      return isLiked;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleEventBookmark(String eventId) async {
    try {
      final isBookmarked = await SupabaseService.toggleEventBookmark(eventId);
      
      // Update local state
      final eventIndex = _events.indexWhere((e) => e.id == eventId);
      if (eventIndex != -1) {
        final event = _events[eventIndex];
        event.isBookmarkedByUser = isBookmarked;
        notifyListeners();
      }
      
      return isBookmarked;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> shareEvent(String eventId) async {
    try {
      await SupabaseService.recordEventShare(eventId);
      // Share count will be updated via real-time subscription
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _storiesSubscription?.cancel();
    super.dispose();
  }
}