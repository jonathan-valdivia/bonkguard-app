import 'dart:async';

import 'package:flutter/material.dart';

import '../models/plan.dart';
import '../models/fuel_item.dart';
import '../services/fuel_service.dart';

class PlanFullscreenTimelineScreen extends StatefulWidget {
  final Plan plan;

  const PlanFullscreenTimelineScreen({
    super.key,
    required this.plan,
  });

  @override
  State<PlanFullscreenTimelineScreen> createState() =>
      _PlanFullscreenTimelineScreenState();
}

class _PlanFullscreenTimelineScreenState
    extends State<PlanFullscreenTimelineScreen> {
  Timer? _timer;
  DateTime? _startedAt;
  int _elapsedSeconds = 0;

  bool get _isRunning => _startedAt != null;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_isRunning) return;

    setState(() {
      _startedAt = DateTime.now();
      _elapsedSeconds = 0;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final started = _startedAt;
      if (started == null) return;

      final diff = DateTime.now().difference(started).inSeconds;
      setState(() {
        _elapsedSeconds = diff;
      });
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _startedAt = null;
      _elapsedSeconds = 0;
    });
  }

  String _formatElapsed(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  int? _nextEventIndex(List<PlanEvent> events) {
    if (!_isRunning) return null;

    final elapsedMinutes = _elapsedSeconds ~/ 60;
    for (int i = 0; i < events.length; i++) {
      if (events[i].minuteFromStart >= elapsedMinutes) {
        return i;
      }
    }
    return null; // past the last event
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
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
                  return const Center(child: CircularProgressIndicator());
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

                final nextIdx = _nextEventIndex(events);

                Widget topBar() {
                  if (!_isRunning) {
                    return Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _start,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Ride'),
                          ),
                        ),
                      ],
                    );
                  }

                  // Running: show elapsed + next event
                  String nextText = 'All done 🎉';
                  if (nextIdx != null) {
                    final e = events[nextIdx];
                    final fuel = fuelById[e.fuelItemId];
                    final minutes = e.minuteFromStart;
                    final h = minutes ~/ 60;
                    final m = minutes % 60;
                    final timeLabel =
                        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
                    nextText = 'Next: $timeLabel — ${fuel?.name ?? e.fuelItemId}';
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF2A2A2A)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Elapsed: ${_formatElapsed(_elapsedSeconds)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                nextText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFBDBDBD),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: 'Stop / reset',
                        onPressed: _stop,
                        icon: const Icon(Icons.stop_circle_outlined),
                        color: Colors.white,
                        iconSize: 34,
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: topBar(),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
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

                          final isNext = nextIdx != null && index == nextIdx;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isNext
                                  ? const Color(0xFF1E2A1E)
                                  : const Color(0xFF111111),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isNext
                                    ? const Color(0xFF66BB6A)
                                    : const Color(0xFF2A2A2A),
                                width: isNext ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 92,
                                  child: Text(
                                    timeLabel,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      height: 1.0,
                                      shadows: isNext
                                          ? const [
                                              Shadow(
                                                blurRadius: 6,
                                                color: Color(0xFF66BB6A),
                                              )
                                            ]
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      if (isNext) ...[
                                        const SizedBox(height: 8),
                                        const Text(
                                          'UP NEXT',
                                          style: TextStyle(
                                            color: Color(0xFF66BB6A),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
