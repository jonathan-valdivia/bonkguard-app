// lib/auth/auth_gate.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../onboarding/onboarding_page.dart';
import 'sign_in_page.dart';
import '../home/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Still checking auth state
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;

        // Not logged in
        if (user == null) {
          return const SignInPage();
        }

        // Logged in, now load or create profile
        return FutureBuilder<UserProfile>(
          future: UserProfileService.instance.getOrCreateUserProfile(
            uid: user.uid,
            email: user.email ?? '',
          ),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (profileSnapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: Text(
                    'Error loading your profile. Please try signing out and back in.',
                  ),
                ),
              );
            }

            if (!profileSnapshot.hasData) {
              // This should now be very rare because getOrCreate always returns
              return const Scaffold(
                body: Center(child: Text('Still preparing your profile...')),
              );
            }

            final profile = profileSnapshot.data!;

            if (!profile.onboardingComplete) {
              return OnboardingPage(profile: profile);
            }

            // Onboarding done → go to home
            return HomeScreen(profile: profile);
          },
        );
      },
    );
  }
}
