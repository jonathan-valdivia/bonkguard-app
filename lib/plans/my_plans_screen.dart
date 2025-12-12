// lib/plans/my_plans_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/plan.dart';
import '../screens/create_plan_screen.dart';
import '../services/plan_service.dart';
import '../state/user_profile_notifier.dart';

class MyPlansScreen extends StatelessWidget {
  const MyPlansScreen({super.key});

  void _openCreatePlan(BuildContext context) {
    Navigator.of(context).pushNamed('/create-plan');
  }

  void _openEditPlan(BuildContext context, Plan plan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreatePlanScreen(initialPlan: plan),
      ),
    );
  }

  Future<void> _confirmDeletePlan(BuildContext context, Plan plan) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete plan'),
          content: Text(
            'Are you sure you want to delete "${plan.name.isEmpty ? 'this plan' : plan.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan deleted.')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete plan. Please try again.'),
        ),
      );
    }
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
              child: Text(
                'Failed to load plans.\nPlease try again later.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final plans = snapshot.data ?? [];

          if (plans.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.note_alt_outlined,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No plans yet',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create your first fueling plan to get started.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _openCreatePlan(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Create plan'),
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
              final name = plan.name.isEmpty ? 'Untitled plan' : plan.name;
              final subtitle =
                  'Duration: ${plan.durationMinutes} min • Pattern: ${plan.patternType}';

              return Card(
                elevation: 1,
                child: ListTile(
                  title: Text(name),
                  subtitle: Text(subtitle),
                  onTap: () => _openEditPlan(context, plan),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete plan',
                    onPressed: () => _confirmDeletePlan(context, plan),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreatePlan(context),
        icon: const Icon(Icons.add),
        label: const Text('Create plan'),
      ),
    );
  }
}
