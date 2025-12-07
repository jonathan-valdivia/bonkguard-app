// lib/plans/my_plans_screen.dart
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../models/fuel_plan.dart';
import '../data/fuel_library.dart';
import '../services/fueling_plan_service.dart';

class MyPlansScreen extends StatelessWidget {
  final UserProfile profile;

  const MyPlansScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Plans')),
      body: FutureBuilder<List<FuelingPlan>>(
        future: FuelingPlanService.instance.loadPlansForUser(profile.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading plans: ${snapshot.error}'),
            );
          }

          final plans = snapshot.data ?? [];

          if (plans.isEmpty) {
            return const Center(
              child: Text(
                'No saved plans yet.\nGenerate one from the home screen.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            itemCount: plans.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final plan = plans[index];

              final totalCarbs = plan.totalCarbs(FuelLibrary.items);
              final durationMinutes = plan.rideDuration.inMinutes;

              DateTime createdAt;
              try {
                createdAt = plan.createdAt.toLocal();
              } catch (_) {
                createdAt = DateTime.now();
              }

              final createdDate =
                  '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';

              return ListTile(
                title: Text(plan.name ?? 'Plan on $createdDate'),
                subtitle: Text(
                  '$durationMinutes min • ${plan.targetCarbsPerHour} g/h target • $totalCarbs g total',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlanDetailScreen(plan: plan),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class PlanDetailScreen extends StatelessWidget {
  final FuelingPlan plan;

  const PlanDetailScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final totalCarbs = plan.totalCarbs(FuelLibrary.items);
    final totalCalories = plan.totalCalories(FuelLibrary.items);
    final hours = plan.rideDuration.inMinutes / 60.0;
    final carbsPerHour = totalCarbs / hours;

    // Build table rows with cumulative carbs
    int cumulativeCarbs = 0;
    final rows = <DataRow>[];

    for (final event in plan.events) {
      final item = FuelLibrary.getById(event.fuelItemId);
      final itemCarbs = (item?.carbsPerServing ?? 0) * event.servings;

      cumulativeCarbs += itemCarbs;

      final timeMinutes = event.minuteFromStart;
      final h = timeMinutes ~/ 60;
      final m = timeMinutes % 60;

      final timeLabel =
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

      rows.add(
        DataRow(
          cells: [
            DataCell(Text(timeLabel)),
            DataCell(Text(item?.name ?? event.fuelItemId)),
            DataCell(Text('$itemCarbs')),
            DataCell(Text('$cumulativeCarbs')),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(plan.name ?? 'Plan details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  plan.name ?? 'Plan details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('Ride duration: ${plan.rideDuration.inMinutes} min'),
                Text('Target: ${plan.targetCarbsPerHour} g/h'),
                Text('Total carbs: $totalCarbs g'),
                if (totalCalories != null)
                  Text('Total calories: $totalCalories kcal'),
                Text(
                  'Approx carbs/hour: ${carbsPerHour.toStringAsFixed(1)} g/h',
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Fueling timeline',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16,
                    headingRowHeight: 32,
                    dataRowMinHeight: 30,
                    dataRowMaxHeight: 36,
                    columns: const [
                      DataColumn(label: Text('Time')),
                      DataColumn(label: Text('Fuel')),
                      DataColumn(label: Text('Carbs (g)')),
                      DataColumn(label: Text('Total (g)')),
                    ],
                    rows: rows,
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
