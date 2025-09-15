import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snaptic/providers/events_provider.dart';
import 'package:snaptic/screens/attendee/home_feed_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'providers/auth_provider.dart';
import 'services/supabase_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/organizer/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase - You need to replace these with your actual Supabase credentials
  await Supabase.initialize(
    url: 'https://eagslqcdnmimrkqxpfwn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVhZ3NscWNkbm1pbXJrcXhwZnduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY4MTU4MzgsImV4cCI6MjA3MjM5MTgzOH0.DFHSbUVEP1lKdE3RmJTnetQuW9FECV-2BT4mq6koaPQ',
  );
  
  runApp(const SnapticApp());
}

class SnapticApp extends StatelessWidget {
  const SnapticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventsProvider()),
      ],
      child: MaterialApp(
        title: 'Snaptic - NFC Ticketing',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading screen while checking authentication
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }

        // Show login screen if not authenticated
        if (!authProvider.isLoggedIn) {
          return const LoginScreen();
        }

                // Navigate based on user role - both organizers and attendees see the feed
        return const HomeFeedScreen();
      },
    );
  }
}

// Splash Screen Component
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: 100,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(height: 20),
            Text(
              'Snaptic',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'NFC Ticketing System',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}