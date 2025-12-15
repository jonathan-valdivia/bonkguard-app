import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/plan.dart';
import '../models/fuel_item.dart';
import '../services/fuel_service.dart';
import '../services/plan_pdf_service.dart';
import 'plan_fullscreen_timeline_screen.dart';


class PlanTimelineScreen extends StatefulWidget {
  final Plan plan;

  const PlanTimelineScreen({
    super.key,
    required this.plan,
  });

  @override
  State<PlanTimelineScreen> createState() => _PlanTimelineScreenState();
}

class _PlanTimelineScreenState extends State<PlanTimelineScreen> {
  bool _isBusy = false;

  String _safeFileBaseName() {
    final raw = widget.plan.name.isEmpty ? 'bonkguard_plan' : widget.plan.name;
    // avoid weird characters for filenames
    return raw.replaceAll('/', '-').replaceAll('\\', '-').trim();
  }

  Future<Map<String, FuelItem>> _loadFuelMap(String userId) async {
    final fuels = await FuelService.instance.streamUserFuels(userId).first;
    return {for (final f in fuels) f.id: f};
  }

  Future<void> _exportTimelinePdf() async {
    if (_isBusy) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isBusy = true);

    try {
      final fuelById = await _loadFuelMap(widget.plan.userId);

      final bytes = await PlanPdfService.instance.buildFuelingTimelinePdf(
        plan: widget.plan,
        fuelById: fuelById,
      );

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: _safeFileBaseName(),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to export PDF. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _exportStemCardPdf() async {
    if (_isBusy) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isBusy = true);

    try {
      final fuelById = await _loadFuelMap(widget.plan.userId);

      final bytes = await PlanPdfService.instance.buildStemCardPdf(
        plan: widget.plan,
        fuelById: fuelById,
      );

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: '${_safeFileBaseName()}_stem',
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to export stem card. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _shareTimelinePdf() async {
    if (_isBusy) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isBusy = true);

    try {
      final fuelById = await _loadFuelMap(widget.plan.userId);

      final bytes = await PlanPdfService.instance.buildFuelingTimelinePdf(
        plan: widget.plan,
        fuelById: fuelById,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename: '${_safeFileBaseName()}.pdf',
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to share PDF. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _shareStemCardPdf() async {
    if (_isBusy) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isBusy = true);

    try {
      final fuelById = await _loadFuelMap(widget.plan.userId);

      final bytes = await PlanPdfService.instance.buildStemCardPdf(
        plan: widget.plan,
        fuelById: fuelById,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename: '${_safeFileBaseName()}_stem.pdf',
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to share stem card. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final events = plan.events ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fueling Timeline'),
      ),
      body: events.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'This plan has no fueling events.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : StreamBuilder<List<FuelItem>>(
              stream: FuelService.instance.streamUserFuels(plan.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load fuels.'));
                }

                final fuels = snapshot.data ?? [];
                final fuelById = {for (final f in fuels) f.id: f};

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSummaryCard(context, fuelById),
                    const SizedBox(height: 12),

                    // Export buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: FilledButton.icon(
                              onPressed: _isBusy ? null : _exportTimelinePdf,
                              icon: _isBusy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.picture_as_pdf),
                              label: const Text('Export PDF'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: _isBusy ? null : _exportStemCardPdf,
                              icon: const Icon(Icons.receipt_long),
                              label: const Text('Stem Card'),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Share buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: FilledButton.tonalIcon(
                              onPressed: _isBusy ? null : _shareTimelinePdf,
                              icon: const Icon(Icons.share),
                              label: const Text('Share PDF'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: _isBusy ? null : _shareStemCardPdf,
                              icon: const Icon(Icons.share_outlined),
                              label: const Text('Share Stem'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PlanFullscreenTimelineScreen(plan: widget.plan),
                            ),
                          );
                        },
                        icon: const Icon(Icons.fullscreen),
                        label: const Text('Full-screen timeline'),
                      ),
                    ),
                    

                    const SizedBox(height: 16),
                    _buildTimelineTable(context, events, fuelById),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, Map<String, FuelItem> fuelById) {
final plan = widget.plan;
final events = plan.events ?? [];

final totalCarbs = _totalCarbsFromEvents(events, fuelById);
final totalCalories = _totalCaloriesFromEvents(events, fuelById);
final avgCarbsHr = _avgCarbsPerHour(totalCarbs, plan.durationMinutes);

final target = plan.carbsPerHour;
final warning = (target == null)
    ? null
    : _deviationWarning(targetCarbsPerHour: target, avgCarbsPerHour: avgCarbsHr);

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

        // Core settings
        Text('Duration: ${plan.durationMinutes} min'),
        if (plan.carbsPerHour != null) Text('Target: ${plan.carbsPerHour} g/hr'),
        if (plan.intervalMinutes != null)
          Text('Interval: every ${plan.intervalMinutes} min'),
        if (plan.startOffsetMinutes != null)
          Text('Start offset: +${plan.startOffsetMinutes} min'),
        Text('Events: ${events.length}'),
        const SizedBox(height: 4),
        Text('Pattern: ${plan.patternType}'),

        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 8),

        // ✅ BG-210 summary stats
        Text('Total carbs: $totalCarbs g'),
        if (totalCalories != null) Text('Total calories: $totalCalories kcal'),
        Text('Avg carbs/hr: ${avgCarbsHr.toStringAsFixed(1)} g/hr'),

        // ✅ BG-211 warning
        if (warning != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE69C)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    warning,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  ),
);

  }

  Widget _buildTimelineTable(
    BuildContext context,
    List<PlanEvent> events,
    Map<String, FuelItem> fuelById,
  ) {
    int cumulativeCarbs = 0;
    final rows = <DataRow>[];

    for (final event in events) {
      final fuel = fuelById[event.fuelItemId];
      final carbs = (fuel?.carbsPerServing ?? 0) * event.servings;
      cumulativeCarbs += carbs;

      final minutes = event.minuteFromStart;
      final h = minutes ~/ 60;
      final m = minutes % 60;
      final timeLabel =
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

      rows.add(
        DataRow(
          cells: [
            DataCell(Text(timeLabel)),
            DataCell(Text(fuel?.name ?? event.fuelItemId)),
            DataCell(Text('$carbs')),
            DataCell(Text('$cumulativeCarbs')),
          ],
        ),
      );
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
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
                rows: rows,
              ),
            ),
          ],
        ),
      ),
    );
  }
  int _totalCarbsFromEvents(List<PlanEvent> events, Map<String, FuelItem> fuelById) {
  int total = 0;
  for (final e in events) {
    final fuel = fuelById[e.fuelItemId];
    total += (fuel?.carbsPerServing ?? 0) * e.servings;
  }
  return total;
}

int? _totalCaloriesFromEvents(List<PlanEvent> events, Map<String, FuelItem> fuelById) {
  int total = 0;
  bool hasAny = false;

  for (final e in events) {
    final fuel = fuelById[e.fuelItemId];
    final cals = fuel?.caloriesPerServing;
    if (cals == null) continue;
    hasAny = true;
    total += cals * e.servings;
  }

  return hasAny ? total : null;
}

double _avgCarbsPerHour(int totalCarbs, int durationMinutes) {
  if (durationMinutes <= 0) return 0;
  final hours = durationMinutes / 60.0;
  return totalCarbs / hours;
}

String? _deviationWarning({
  required int targetCarbsPerHour,
  required double avgCarbsPerHour,
}) {
  final diff = (avgCarbsPerHour - targetCarbsPerHour).abs();

  // Threshold: max(10g/hr, 10% of target)
  final percentThreshold = targetCarbsPerHour * 0.10;
  final threshold = percentThreshold > 10 ? percentThreshold : 10;

  if (diff <= threshold) return null;

  final direction = avgCarbsPerHour > targetCarbsPerHour ? 'above' : 'below';
  return 'This plan averages ${avgCarbsPerHour.toStringAsFixed(1)} g/hr, '
      'which is ${diff.toStringAsFixed(1)} g/hr $direction your target.';
}

}
