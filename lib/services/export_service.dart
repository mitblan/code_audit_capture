import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/audit_writeup.dart';
import 'database_service.dart';

class ExportService {
  Future<String> exportAllWriteupsToCsv() async {
    final List<AuditWriteup> writeups = await DatabaseService()
        .getAllWriteups();

    final List<List<dynamic>> rows = [
      [
        'Plant #',
        'Date Detected',
        'Unit #',
        'Model #',
        'Department',
        'Category',
        'New Code Referance',
        'Code Class',
        'Repeat Violation',
        'No of Times Repeat',
        'Detected By',
        'Non Conformance No',
        'Code Description',
        'Grounding',
        'Solar',
        'Panel Board',
        'Appliance Install',
      ],
    ];

    for (final writeup in writeups) {
      rows.add([
        writeup.plantNumber,
        _formatAccessDate(writeup.dateDetected),
        writeup.unitNumber,
        writeup.modelNumber,
        writeup.department,
        writeup.category,
        writeup.newCodeReference,
        writeup.codeClass,
        _formatYesNo(writeup.repeatViolation),
        writeup.timesRepeat,
        writeup.detectedBy,
        writeup.nonConformanceNo,
        writeup.codeDescription,
        _formatYesNo(writeup.grounding),
        _formatYesNo(writeup.solar),
        _formatYesNo(writeup.panelBoard),
        _formatYesNo(writeup.applianceInstall),
      ]);
    }

    final String csvData = const ListToCsvConverter().convert(rows);

    final dbPath = await getDatabasesPath();
    final exportDir = Directory(p.join(dbPath, 'exports'));

    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');

    final filePath = p.join(exportDir.path, 'code_audit_export_$timestamp.csv');

    final file = File(filePath);
    await file.writeAsString(csvData);

    return filePath;
  }

  String _formatAccessDate(DateTime? date) {
    if (date == null) return '';
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatYesNo(bool? value) {
    if (value == null) return '';
    return value ? 'Yes' : 'No';
  }
}
