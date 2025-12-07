// lib/services/pdf_plan_service.dart
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/fuel_plan.dart';
import '../data/fuel_library.dart';

class PdfPlanService {
  PdfPlanService._();

  static final instance = PdfPlanService._();

  /// Build a stem-tape style PDF for a fueling plan.
  ///
  /// Default size: 1.5" x 5" (roughly) (138 x 360 points at 72 dpi).
  Future<Uint8List> buildPlanPdf(FuelingPlan plan) async {
    final doc = pw.Document();

    // Load embedded Unicode-safe fonts
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
    );

    // 1.5" x 5" in PDF points (1" = 72 points)
    const pageFormat = PdfPageFormat(138, 360);

    final rows = <pw.TableRow>[];

    // Header row
    rows.add(
      pw.TableRow(
        children: [
          _cellHeader('Time', boldFont),
          _cellHeader('Fuel', boldFont),
          _cellHeader('g', boldFont),
        ],
      ),
    );

    for (final event in plan.events) {
      final item = FuelLibrary.getById(event.fuelItemId);
      final itemCarbs = (item?.carbsPerServing ?? 0) * event.servings;

      final timeMinutes = event.minuteFromStart;
      final h = timeMinutes ~/ 60;
      final m = timeMinutes % 60;
      final timeLabel =
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

      rows.add(
        pw.TableRow(
          children: [
            _cellBody(timeLabel, regularFont),
            _cellBody(item?.name ?? event.fuelItemId, regularFont),
            _cellBody('$itemCarbs', regularFont),
          ],
        ),
      );
    }

    final totalCarbs = plan.totalCarbs(FuelLibrary.items);
    final durationMinutes = plan.rideDuration.inMinutes;

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(30), // margin to avoid clipping
        build: (context) {
          return pw.DefaultTextStyle(
            style: pw.TextStyle(font: regularFont, fontSize: 7),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  plan.name ?? 'Fueling plan',
                  style: pw.TextStyle(font: boldFont, fontSize: 10),
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Duration: ${durationMinutes} min\n'
                  'Target: ${plan.targetCarbsPerHour} g/h\n'
                  'Total: ${totalCarbs} g',
                  maxLines: 4,
                  overflow: pw.TextOverflow.clip,
                ),
                pw.SizedBox(height: 4),
                pw.Table(
                  border: pw.TableBorder.all(width: 0.3),
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.middle,
                  columnWidths: {
                    0: const pw.FixedColumnWidth(24), // Time
                    1: const pw.FlexColumnWidth(), // Fuel
                    2: const pw.FixedColumnWidth(18), // g
                  },
                  children: rows,
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  // --- helpers ---

  static pw.Widget _cellHeader(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(2),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _cellBody(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(2),
      child: pw.Text(
        text,
        maxLines: 1,
        overflow: pw.TextOverflow.clip,
        style: pw.TextStyle(font: font, fontSize: 7),
      ),
    );
  }
}
