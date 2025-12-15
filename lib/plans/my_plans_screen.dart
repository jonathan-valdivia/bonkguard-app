import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/plan.dart';
import '../services/plan_service.dart';
import '../state/user_profile_notifier.dart';
import '../screens/create_plan_screen.dart';
import 'plan_timeline_screen.dart';

class MyPlansScreen extends StatelessWidget {
  const MyPlansScreen({super.key});

  String _buildSubtitle(Plan plan) {
    final parts = <String>[];

    parts.add('${plan.durationMinutes} min');

    if (plan.carbsPerHour != null) parts.add('${plan.carbsPerHour} g/hr');
    if (plan.intervalMinutes != null) parts.add('every ${plan.intervalMinutes}m');
    if (plan.startOffsetMinutes != null) parts.add('start +${plan.startOffsetMinutes}m');

    parts.add(plan.patternType);

    return parts.join(' • ');
  }

  Future<void> _confirmDeletePlan({
    required BuildContext context,
    required Plan plan,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete plan'),
          content: Text('Are you sure you want to delete "${plan.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await PlanService.instance.deletePlan(plan.id);
      messenger.showSnackBar(const SnackBar(content: Text('Plan deleted.')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to delete plan. Please try again.')),
      );
    }
  }

  void _openEdit(BuildContext context, Plan plan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreatePlanScreen(initialPlan: plan),
      ),
    );
  }

  void _openTimeline(BuildContext context, Plan plan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlanTimelineScreen(plan: plan),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileNotifier>().profile;

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.list_alt_outlined, size: 48),
                    SizedBox(height: 12),
                    Text('No plans yet', style: TextStyle(fontSize: 18)),
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
                  // ✅ Tap row = Edit (restored)
                  onTap: () => _openEdit(context, plan),

                  // ✅ Overflow menu for View/Edit/Delete
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Plan actions',
                    onSelected: (value) {
                      switch (value) {
                        case 'timeline':
                          _openTimeline(context, plan);
                          break;
                        case 'edit':
                          _openEdit(context, plan);
                          break;
                        case 'delete':
                          _confirmDeletePlan(context: context, plan: plan);
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'timeline',
                        child: ListTile(
                          leading: Icon(Icons.timeline),
                          title: Text('View timeline'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreatePlanScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New plan'),
      ),
    );
  }
}
