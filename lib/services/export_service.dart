import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/audit_writeup.dart';
import 'database_service.dart';

class ExportService {
  Future<String?> exportAllWriteupsToCsv() async {
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

    final String csvData = const ListToCsvConverter().convert(rows);
    final String fileName =
        'code_audit_export_${_buildTimestampForFileName(DateTime.now())}.csv';

    if (kIsWeb) {
      throw UnsupportedError('CSV export is not configured for web.');
    }

    // Mobile platforms need bytes passed directly into saveFile.
    if (Platform.isAndroid || Platform.isIOS) {
      final bytes = Uint8List.fromList(utf8.encode(csvData));

      final String? savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Code Audit Export',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes,
      );

      return savedPath;
    }

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

    return outputPath;
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

    return '${year}${month}${day}_${hour}${minute}${second}';
  }
}
