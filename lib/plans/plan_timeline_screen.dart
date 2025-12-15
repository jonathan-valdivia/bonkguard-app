import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/plan.dart';
import '../models/fuel_item.dart';
import '../services/fuel_service.dart';
import '../services/plan_pdf_service.dart';

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
  bool _isExportingPdf = false;

  Future<void> _exportPdf({
    required Map<String, FuelItem> fuelById,
  }) async {
    if (_isExportingPdf) return;

    // Capture messenger before async work
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isExportingPdf = true);

    try {
      final bytes = await PlanPdfService.instance.buildFuelingTimelinePdf(
  plan: widget.plan,
  fuelById: fuelById,
);


      // This opens the platform print/share/save sheet
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: (widget.plan.name.isEmpty ? 'bonkguard_plan' : widget.plan.name)
            .replaceAll('/', '-'),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to export PDF. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  Future<void> _exportStemCard({
  required Map<String, FuelItem> fuelById,
}) async {
  if (_isExportingPdf) return;

  final messenger = ScaffoldMessenger.of(context);

  setState(() => _isExportingPdf = true);

  try {
    final bytes = await PlanPdfService.instance.buildStemCardPdf(
      plan: widget.plan,
      fuelById: fuelById,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: '${widget.plan.name.isEmpty ? 'bonkguard_stem_card' : widget.plan.name}_stem'
          .replaceAll('/', '-'),
    );
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Failed to export stem card. Please try again.')),
    );
  } finally {
    if (mounted) setState(() => _isExportingPdf = false);
  }
}


  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fueling Timeline'),
        actions: [
          IconButton(
            tooltip: 'Export PDF',
            onPressed: _isExportingPdf
                ? null
                : () {
                    // We need fuels loaded first (handled below in StreamBuilder)
                    // So we no-op here; the real button is enabled when fuels exist.
                  },
            icon: _isExportingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
          ),
        ],
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
          final fuelById = {for (final f in fuels) f.id: f};

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

          // Replace the AppBar action behavior now that fuels are loaded:
          // (We keep it simple: render the whole page and add a button below too.)
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(context),
              const SizedBox(height: 12),

              // Export button inside body (always works once fuels loaded)
              Row(
  children: [
    Expanded(
      child: SizedBox(
        height: 44,
        child: FilledButton.icon(
          onPressed: _isExportingPdf
              ? null
              : () => _exportPdf(fuelById: fuelById),
          icon: const Icon(Icons.picture_as_pdf),
          label: Text(_isExportingPdf ? 'Exporting...' : 'Export PDF'),
        ),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: SizedBox(
        height: 44,
        child: OutlinedButton.icon(
          onPressed: _isExportingPdf
              ? null
              : () => _exportStemCard(fuelById: fuelById),
          icon: const Icon(Icons.receipt_long),
          label: const Text('Stem Card'),
        ),
      ),
    ),
  ],
),

              const SizedBox(height: 16),
              _buildTimelineTable(context, events, fuelById),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final plan = widget.plan;
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
            Text('Duration: ${plan.durationMinutes} min'),
            if (plan.carbsPerHour != null)
              Text('Target: ${plan.carbsPerHour} g/hr'),
            if (plan.intervalMinutes != null)
              Text('Interval: every ${plan.intervalMinutes} min'),
            if (plan.startOffsetMinutes != null)
              Text('Start offset: +${plan.startOffsetMinutes} min'),
            Text('Events: $totalEvents'),
            const SizedBox(height: 4),
            Text('Pattern: ${plan.patternType}'),
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
                rows: rows,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
