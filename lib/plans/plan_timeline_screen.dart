import 'package:flutter/material.dart';

import '../models/plan.dart';
import '../models/fuel_item.dart';
import '../services/fuel_service.dart';

class PlanTimelineScreen extends StatelessWidget {
  final Plan plan;

  const PlanTimelineScreen({
    super.key,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fueling Timeline'),
      ),
      body: StreamBuilder<List<FuelItem>>(
        stream: FuelService.instance.streamUserFuels(plan.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to load fuels.'),
            );
          }

          final fuels = snapshot.data ?? [];
          final fuelById = {
            for (final f in fuels) f.id: f,
          };

          final events = plan.events ?? [];

          if (events.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'This plan has no fueling events.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          int cumulativeCarbs = 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(context),
              const SizedBox(height: 16),
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Timeline',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
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
                          rows: events.map((event) {
                            final fuel = fuelById[event.fuelItemId];
                            final carbs =
                                (fuel?.carbsPerServing ?? 0) * event.servings;
                            cumulativeCarbs += carbs;

                            final minutes = event.minuteFromStart;
                            final h = minutes ~/ 60;
                            final m = minutes % 60;
                            final timeLabel =
                                '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

                            return DataRow(
                              cells: [
                                DataCell(Text(timeLabel)),
                                DataCell(
                                  Text(fuel?.name ?? event.fuelItemId),
                                ),
                                DataCell(Text('$carbs')),
                                DataCell(Text('$cumulativeCarbs')),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final duration = plan.durationMinutes;
    final carbsPerHour = plan.carbsPerHour;

    final totalEvents = plan.events?.length ?? 0;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              plan.name.isEmpty ? 'Untitled plan' : plan.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Duration: $duration min'),
            if (carbsPerHour != null) Text('Target: $carbsPerHour g/hr'),
            Text('Events: $totalEvents'),
            const SizedBox(height: 4),
            Text('Pattern: ${plan.patternType}'),
          ],
        ),
      ),
    );
  }
}
