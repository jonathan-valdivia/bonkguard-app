import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/plan.dart';
import '../services/plan_service.dart';
import '../state/user_profile_notifier.dart';
import '../screens/create_plan_screen.dart';

class MyPlansScreen extends StatelessWidget {
  const MyPlansScreen({super.key});

  String _buildSubtitle(Plan plan) {
    final parts = <String>[];

    // Duration
    parts.add('${plan.durationMinutes} min');

    // Optional pattern metadata
    if (plan.carbsPerHour != null) {
      parts.add('${plan.carbsPerHour} g/hr');
    }

    if (plan.intervalMinutes != null) {
      parts.add('every ${plan.intervalMinutes}m');
    }

    if (plan.startOffsetMinutes != null) {
      parts.add('start +${plan.startOffsetMinutes}m');
    }

    // Pattern type (fixed for now)
    parts.add(plan.patternType);

    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileNotifier>().profile;

    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Plans'),
      ),
      body: StreamBuilder<List<Plan>>(
        stream: PlanService.instance.userPlansStream(profile.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load plans.\nPlease try again later.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }

          final plans = snapshot.data ?? [];

          if (plans.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.list_alt_outlined, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'No plans yet',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create your first fueling plan to get started.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final plan = plans[index];

              return Card(
                elevation: 1,
                child: ListTile(
                  title: Text(
                    plan.name.isEmpty ? 'Untitled plan' : plan.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    _buildSubtitle(plan),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CreatePlanScreen(initialPlan: plan),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CreatePlanScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New plan'),
      ),
    );
  }
}
