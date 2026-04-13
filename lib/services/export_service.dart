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
        'id',
        'plant_number',
        'code_reference',
        'discipline',
        'description',
        'created_at',
        'rvia_id',
        'rvia_type',
        'rvia_description',
      ],
    ];

    for (final writeup in writeups) {
      rows.add([
        writeup.id,
        writeup.plantNumber,
        writeup.codeReference,
        writeup.discipline,
        writeup.description,
        writeup.createdAt.toIso8601String(),
        writeup.rviaId,
        writeup.rviaType,
        writeup.rviaDescription,
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
}
