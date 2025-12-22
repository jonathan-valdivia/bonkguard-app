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

  Future<Uint8List> buildStemCardPdf({
  required Plan plan,
  required Map<String, FuelItem> fuelById,
}) async {
  final doc = pw.Document();

  // Approx stem card: 1.5 in wide x 5 in long
  // PDF units are points (72 points = 1 inch)
  final pageFormat = PdfPageFormat(1.5 * 72, 5 * 72);

  final events = plan.events ?? [];

  int cumulativeCarbs = 0;

  doc.addPage(
    pw.Page(
      pageFormat: pageFormat,
      margin: const pw.EdgeInsets.all(6),
      build: (context) {
        return pw.DefaultTextStyle(
          style: const pw.TextStyle(fontSize: 9),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                plan.name.isEmpty ? 'BonkGuard Plan' : plan.name,
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${plan.durationMinutes} min'
                '${plan.carbsPerHour != null ? ' • ${plan.carbsPerHour} g/hr' : ''}',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.6),
              pw.SizedBox(height: 4),

              // Timeline rows
              ...events.map((e) {
                final fuel = fuelById[e.fuelItemId];
                final carbs = (fuel?.carbsPerServing ?? 0) * e.servings;
                cumulativeCarbs += carbs;

                final minutes = e.minuteFromStart;
                final h = minutes ~/ 60;
                final m = minutes % 60;
                final timeLabel =
                    '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 34,
                        child: pw.Text(
                          timeLabel,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              fuel?.name ?? e.fuelItemId,
                              maxLines: 1,
                              overflow: pw.TextOverflow.clip,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.Text(
                              '$carbs g  (total $cumulativeCarbs)',
                              style: const pw.TextStyle(fontSize: 7),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.Spacer(),
              pw.Divider(thickness: 0.6),
              pw.Text(
                'Total: $cumulativeCarbs g',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ],
          ),
        );
      },
    ),
  );

  return await doc.save();
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
