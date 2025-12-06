// lib/auth/auth_gate.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../onboarding/onboarding_page.dart';
import 'sign_in_page.dart';
import '../app_theme.dart';

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

        // Logged in, now load profile
        return FutureBuilder<UserProfile?>(
          future: UserProfileService.instance.getUserProfile(user.uid),
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

            final profile = profileSnapshot.data;

            // If somehow no profile, create a basic one and show onboarding
            if (profile == null) {
              return const Scaffold(
                body: Center(
                  child: Text(
                    'No profile found. Please sign out and sign in again.',
                  ),
                ),
              );
            }

            if (!profile.onboardingComplete) {
              return OnboardingPage(profile: profile);
            }

            // Onboarding done → go to home
            return const _HomePlaceholder();
          },
        );
      },
    );
  }
}

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const BonkGuardLogo(),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Text('Signed in as: ${user?.email ?? 'Unknown user'}'),
      ),
    );
  }
}
