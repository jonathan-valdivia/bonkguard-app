import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/plan.dart';
import '../models/fuel_item.dart';

class PlanPdfService {
  PlanPdfService._();
  static final PlanPdfService instance = PlanPdfService._();

  Future<Uint8List> buildFuelingTimelinePdf({
    required Plan plan,
    required Map<String, FuelItem> fuelById,
  }) {
    final doc = pw.Document();

    final events = plan.events ?? [];

    // Build rows with cumulative carbs
    int cumulativeCarbs = 0;

    final tableRows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _cellHeader('Time'),
          _cellHeader('Fuel'),
          _cellHeader('Carbs (g)'),
          _cellHeader('Total (g)'),
        ],
      ),
    ];

    for (final e in events) {
      final fuel = fuelById[e.fuelItemId];
      final carbs = (fuel?.carbsPerServing ?? 0) * e.servings;
      cumulativeCarbs += carbs;

      final minutes = e.minuteFromStart;
      final h = minutes ~/ 60;
      final m = minutes % 60;
      final timeLabel =
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

      tableRows.add(
        pw.TableRow(
          children: [
            _cell(timeLabel),
            _cell(fuel?.name ?? e.fuelItemId),
            _cell('$carbs'),
            _cell('$cumulativeCarbs'),
          ],
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            pw.Text(
              'BonkGuard - Fueling Timeline',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              plan.name.isEmpty ? 'Untitled plan' : plan.name,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text('Duration: ${plan.durationMinutes} min'),
            if (plan.carbsPerHour != null)
              pw.Text('Target: ${plan.carbsPerHour} g/hr'),
            if (plan.intervalMinutes != null)
              pw.Text('Interval: every ${plan.intervalMinutes} min'),
            if (plan.startOffsetMinutes != null)
              pw.Text('Start offset: +${plan.startOffsetMinutes} min'),
            pw.Text('Pattern type: ${plan.patternType}'),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
              columnWidths: const {
                0: pw.FixedColumnWidth(60),
                1: pw.FlexColumnWidth(),
                2: pw.FixedColumnWidth(70),
                3: pw.FixedColumnWidth(70),
              },
              children: tableRows,
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _cellHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _cell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }
}
