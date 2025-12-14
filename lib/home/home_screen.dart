// lib/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/user_profile.dart';
import '../plans/my_plans_screen.dart';
import '../settings/settings_page.dart';
import '../state/user_profile_notifier.dart';
import '../fuels/fuels_library_screen.dart'; 
import '../services/plan_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasMigratedPlans = false; // 👈 NEW

  Future<void> _ensurePlansMigrated(String userId) async {
    if (_hasMigratedPlans) return;
    _hasMigratedPlans = true;

    // Fire and forget; no need to block UI
    try {
      await PlanService.instance.migrateExistingPlansForUser(userId);
    } catch (_) {
      // For MVP we silently ignore migration errors; plans still load
    }
  }

  Future<void> _openSettings() async {
    final updatedProfile = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );

    if (updatedProfile != null && mounted) {
      context.read<UserProfileNotifier>().updateProfile(updatedProfile);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings saved.')));
    }
  }

  void _openCreatePlan() {
    Navigator.of(context).pushNamed('/create-plan');
  }

  void _openMyPlans() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MyPlansScreen()));
  }

  void _openFuelsLibrary() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FuelsLibraryScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileNotifier>().profile;

    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 👇 Kick off migration once for this user
    _ensurePlansMigrated(profile.uid);

    return Scaffold(
      appBar: AppBar(
        title: const BonkGuardLogo(),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_drink_outlined),
            tooltip: 'Fuels library',
            onPressed: _openFuelsLibrary,
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'My Plans',
            onPressed: _openMyPlans,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Container(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🧱 Plan Builder card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Plan Builder',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create a fueling plan using the new Plan Builder.',
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _openCreatePlan,
                            icon: const Icon(Icons.add),
                            label: const Text('Create plan'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 📋 My Plans card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'My Plans',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'View, edit, or delete your saved plans.',
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _openMyPlans,
                            icon: const Icon(Icons.list_alt),
                            label: const Text('View my plans'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 🧃 Fuels Library card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Fuels library',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Browse default fuels and your custom gels, drinks, and snacks.',
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _openFuelsLibrary,
                            icon: const Icon(Icons.local_drink_outlined),
                            label: const Text('View fuels'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
