import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/audit_writeup.dart';
import 'database_service.dart';

class ExportService {
  Future<String?> exportAllWriteupsToCsv() async {
    final databaseService = DatabaseService();
    final List<AuditWriteup> writeups = await databaseService
        .getWriteupsPendingDbExport();

    if (writeups.isEmpty) {
      throw Exception('No unexported writeups found for DBImport export.');
    }

    final String csvData = _buildCsv(writeups);
    final String fileName = _buildLegacyFileName();
    String? savedPath;

    if (kIsWeb) {
      throw UnsupportedError('CSV export is not configured for web.');
    }

    // Mobile platforms need bytes passed directly into saveFile.
    if (Platform.isAndroid || Platform.isIOS) {
      final bytes = Uint8List.fromList(utf8.encode(csvData));

      savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Code Audit Export',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes,
      );
    } else {
      // Desktop platforms can return a path which we then write to.
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Code Audit Export',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        lockParentWindow: true,
      );

      if (outputPath == null) {
        return null;
      }

      final file = File(outputPath);
      await file.writeAsString(csvData);
      savedPath = outputPath;
    }

    if (savedPath != null) {
      final ids = writeups
          .where((writeup) => writeup.id != null)
          .map((writeup) => writeup.id!)
          .toList();

      await databaseService.markWriteupsDbExported(ids);
    }

    return savedPath;
  }

  Future<String> exportAllWriteupsToFolder(String folderPath) async {
    final databaseService = DatabaseService();
    final List<AuditWriteup> writeups = await databaseService
        .getWriteupsPendingDbExport();

    if (writeups.isEmpty) {
      throw Exception('No unexported writeups found for DBImport export.');
    }

    final String csvData = _buildCsv(writeups);
    final String fileName = _buildDbImportFileName();
    final String fullPath = '$folderPath/$fileName';

    final file = File(fullPath);
    await file.writeAsString(csvData);

    final ids = writeups
        .where((writeup) => writeup.id != null)
        .map((writeup) => writeup.id!)
        .toList();

    await databaseService.markWriteupsDbExported(ids);

    return file.path;
  }

  String _buildCsv(List<AuditWriteup> writeups) {
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
        writeup.timesRepeat.toString(),
        writeup.detectedBy,
        writeup.nonConformanceNo,
        writeup.codeDescription,
        _formatYesNo(writeup.grounding),
        _formatYesNo(writeup.solar),
        _formatYesNo(writeup.panelBoard),
        _formatYesNo(writeup.applianceInstall),
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  String _formatAccessDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final year = (date.year % 100).toString().padLeft(2, '0');
    return '$month/$day/$year';
  }

  String _formatYesNo(bool value) {
    return value ? 'Yes' : 'No';
  }

  String _buildTimestampForFileName(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');

    return '${year}${month}${day}_$hour$minute$second';
  }

  String _buildLegacyFileName() {
    return 'code_audit_export_${_buildTimestampForFileName(DateTime.now())}.csv';
  }

  String _buildDbImportFileName() {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return 'DBImport($date).csv';
  }
}
