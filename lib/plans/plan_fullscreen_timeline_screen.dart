import 'package:flutter/material.dart';

import '../models/plan.dart';
import '../models/fuel_item.dart';
import '../services/fuel_service.dart';

class PlanFullscreenTimelineScreen extends StatelessWidget {
  final Plan plan;

  const PlanFullscreenTimelineScreen({
    super.key,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    final events = plan.events ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('On-bike Timeline'),
      ),
      body: events.isEmpty
          ? const Center(
              child: Text(
                'No events in this plan.',
                style: TextStyle(color: Colors.white),
              ),
            )
          : StreamBuilder<List<FuelItem>>(
              stream: FuelService.instance.streamUserFuels(plan.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Failed to load fuels.',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final fuels = snapshot.data ?? [];
                final fuelById = {for (final f in fuels) f.id: f};

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final e = events[index];
                    final fuel = fuelById[e.fuelItemId];

                    final minutes = e.minuteFromStart;
                    final h = minutes ~/ 60;
                    final m = minutes % 60;
                    final timeLabel =
                        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

                    final carbs =
                        (fuel?.carbsPerServing ?? 0) * e.servings;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 92,
                            child: Text(
                              timeLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fuel?.name ?? e.fuelItemId,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$carbs g carbs',
                                  style: const TextStyle(
                                    color: Color(0xFFBDBDBD),
                                    fontSize: 18,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
