import 'dart:io';

import 'package:intl/intl.dart';

import '../models/audit_writeup.dart';
import 'database_service.dart';

class CodeCompExportService {
  Future<String> exportAllWriteupsToFolder(String folderPath) async {
    final databaseService = DatabaseService();
    final writeups = await databaseService.getWriteupsPendingCcExport();

    if (writeups.isEmpty) {
      throw Exception('No unexported writeups found for CCImport export.');
    }

    final fileName = _buildFileName();
    final csvContent = _buildCsv(writeups);

    final file = File('$folderPath/$fileName');
    await file.writeAsString(csvContent);

    final ids = writeups
        .where((writeup) => writeup.id != null)
        .map((writeup) => writeup.id!)
        .toList();

    await databaseService.markWriteupsCcExported(ids);

    return file.path;
  }

  String _buildCsv(List<AuditWriteup> writeups) {
    final sortedWriteups = List<AuditWriteup>.from(writeups);

    final buffer = StringBuffer();

    // Sort by plant, then department, then code reference
    sortedWriteups.sort((a, b) {
      final plantCompare = a.plantNumber.toLowerCase().compareTo(
        b.plantNumber.toLowerCase(),
      );

      if (plantCompare != 0) {
        return plantCompare;
      }

      final deptCompare = a.department.toLowerCase().compareTo(
        b.department.toLowerCase(),
      );

      if (deptCompare != 0) {
        return deptCompare;
      }

      return a.newCodeReference.toLowerCase().compareTo(
        b.newCodeReference.toLowerCase(),
      );
    });

    String? currentPlant;
    String? currentDepartment;

    bool firstPlant = true;

    for (final writeup in sortedWriteups) {
      // New Plant Section
      if (currentPlant != writeup.plantNumber) {
        currentPlant = writeup.plantNumber;
        currentDepartment = null;

        if (!firstPlant) {
          buffer.writeln(',,,,');
        }

        firstPlant = false;

        buffer.writeln(
          [
            _escapeCsv('Plant ${writeup.plantNumber}'),
            _escapeCsv(''),
            _escapeCsv(''),
            _escapeCsv(''),
            _escapeCsv(''),
          ].join(','),
        );
      }

      // New Department Section inside Plant
      if (currentDepartment != writeup.department) {
        currentDepartment = writeup.department;

        buffer.writeln(',,,,');

        buffer.writeln(
          [
            _escapeCsv(currentDepartment),
            _escapeCsv(''),
            _escapeCsv(''),
            _escapeCsv(''),
            _escapeCsv(''),
          ].join(','),
        );
      }

      final firstColumn =
          '${writeup.newCodeReference} ${writeup.nonConformanceNo}'.trim();

      final row = [
        _escapeCsv(firstColumn),
        _escapeCsv(writeup.codeClass),
        _escapeCsv(writeup.detectedBy),
        _escapeCsv(''),
        _escapeCsv(_formatDate(writeup.dateDetected)),
      ];

      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    return DateFormat('M/d').format(date);
  }

  String _buildFileName() {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return 'CCImport($date).csv';
  }

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
