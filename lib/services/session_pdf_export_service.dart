import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/audit_writeup.dart';
import 'database_service.dart';

class SessionPdfExportService {
  Future<void> exportPlantSessionPdf(String plantNumber) async {
    // Always pull fresh data
    final writeups = await DatabaseService().getWriteupsByPlant(plantNumber);

    if (writeups.isEmpty) {
      throw Exception('No writeups found for plant $plantNumber');
    }

    // Group by department
    final Map<String, List<AuditWriteup>> grouped = {};

    for (final w in writeups) {
      grouped.putIfAbsent(w.department, () => []).add(w);
    }

    // Sort departments
    final departments = grouped.keys.toList()..sort();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        build: (context) => [
          _buildHeader(plantNumber),
          pw.SizedBox(height: 16),

          // Department sections
          for (final dept in departments) ...[
            _buildDepartmentHeader(dept),
            pw.SizedBox(height: 6),

            ...grouped[dept]!.map(_buildWriteupLine),

            pw.SizedBox(height: 12),
          ],
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();

    // Preview / Share
    await Printing.layoutPdf(onLayout: (format) async => bytes);
  }

  // --------------------------
  // Widgets
  // --------------------------

  pw.Widget _buildHeader(String plantNumber) {
    final date = DateFormat('MM/dd/yy').format(DateTime.now());

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Code Audit for Plant $plantNumber, $date',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Divider(thickness: 1),
      ],
    );
  }

  pw.Widget _buildDepartmentHeader(String department) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Text(
        department,
        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _buildWriteupLine(AuditWriteup w) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${w.unitNumber} - '
            '${w.modelNumber} - '
            '${w.newCodeReference} - '
            '${w.codeClass} - '
            '${_formatRepeat(w)}',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 10),
            child: pw.Text(
              w.nonConformanceNo,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRepeat(AuditWriteup w) {
    if (!w.repeatViolation) return 'No';
    if (w.timesRepeat > 0) return 'Yes(${w.timesRepeat})';
    return 'Yes';
  }
}
