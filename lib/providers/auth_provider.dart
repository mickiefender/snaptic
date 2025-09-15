import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';

class AuthProvider with ChangeNotifier {
  UserProfile? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get isOrganizer => _currentUser?.isOrganizer ?? false;
  bool get isAttendee => _currentUser?.isAttendee ?? false;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      _handleAuthStateChange(data.session);
    });

    final session = SupabaseService.client.auth.currentSession;
    _handleAuthStateChange(session);
  }

  Future<void> _handleAuthStateChange(Session? session) async {
    if (session?.user != null) {
      await _loadUserProfile(session!.user.id);
    } else {
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final profile = await SupabaseService.getUserProfile(userId);
      _currentUser = profile;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await SupabaseService.signIn(email, password);
      if (response.user != null) {
        // Load user profile after successful login
        await _loadUserProfile(response.user!.id);
        if (_currentUser != null) {
          return true;
        } else {
          _errorMessage = 'Profile not found. Please contact support.';
          return false;
        }
      } else {
        _errorMessage = 'Invalid email or password';
        return false;
      }
    } catch (e) {
      String errorMsg = 'Login failed';
      if (e.toString().contains('Invalid login credentials')) {
        errorMsg = 'Invalid email or password';
      } else if (e.toString().contains('Email not confirmed')) {
        errorMsg = 'Please check your email and confirm your account';
      }
      _errorMessage = errorMsg;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp(String email, String password, String name, String role) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Check if user already exists in profiles table
      final existingUser = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('email', email)
          .maybeSingle();
      
      if (existingUser != null) {
        _errorMessage = 'An account with this email already exists';
        return false;
      }

      final response = await SupabaseService.signUp(email, password);
      if (response.user != null) {
        final profile = UserProfile(
          userId: response.user!.id,
          name: name,
          email: email,
          role: role,
          createdAt: DateTime.now(),
        );

        try {
          await SupabaseService.createUserProfile(profile);
          _currentUser = profile;
          return true;
        } catch (profileError) {
          // If profile creation fails, clean up the auth user
          await SupabaseService.signOut();
          _errorMessage = 'Failed to create user profile. Please try again.';
          return false;
        }
      } else {
        _errorMessage = 'Failed to create account';
        return false;
      }
    } catch (e) {
      String errorMsg = 'Registration failed';
      if (e.toString().contains('already registered')) {
        errorMsg = 'An account with this email already exists';
      } else if (e.toString().contains('weak password')) {
        errorMsg = 'Password is too weak. Please use at least 6 characters';
      } else if (e.toString().contains('invalid email')) {
        errorMsg = 'Please enter a valid email address';
      } else if (e.toString().contains('Duplicate key')) {
        errorMsg = 'An account with this email already exists';
      }
      _errorMessage = errorMsg;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await SupabaseService.signOut();
      _currentUser = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}