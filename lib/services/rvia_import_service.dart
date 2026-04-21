import 'dart:convert';
import 'dart:io';

import 'package:charset/charset.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

import '../models/rvia_code.dart';
import 'database_service.dart';

class RviaImportService {
  Future<int?> importFromCsvFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select RVIA CSV File',
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final path = result.files.single.path;
    if (path == null) {
      throw Exception('Unable to access selected file.');
    }

    final file = File(path);
    final bytes = await file.readAsBytes();

    final rawData = _decodeFileBytes(bytes);
    final normalizedText = _normalizeFileText(rawData);

    if (normalizedText.trim().isEmpty) {
      throw Exception('Selected CSV file is empty.');
    }

    final converter = const CsvToListConverter(
      fieldDelimiter: ',',
      textDelimiter: '"',
      eol: '\n',
      shouldParseNumbers: false,
    );

    List<List<dynamic>> table;
    try {
      table = converter.convert(normalizedText);
    } catch (e) {
      throw Exception('Unable to parse CSV file: $e');
    }

    if (table.isEmpty) {
      throw Exception('Selected CSV file is empty.');
    }

    final headerRow = table.first;
    if (headerRow.isEmpty) {
      throw Exception('Unable to read header row.');
    }

    final normalizedHeaders = headerRow
        .map((cell) => _normalizeHeader(cell.toString()))
        .toList();

    final expectedHeaders = [
      'id',
      'standard',
      'type',
      'discipline',
      'description',
      'sub cat',
    ];

    if (normalizedHeaders.length < expectedHeaders.length) {
      throw Exception(
        'Unable to read headers. Expected ${expectedHeaders.length} columns, found ${normalizedHeaders.length}.',
      );
    }

    for (int i = 0; i < expectedHeaders.length; i++) {
      if (normalizedHeaders[i] != expectedHeaders[i]) {
        throw Exception(
          'Unexpected CSV header order. Expected: ${expectedHeaders.join(', ')}. '
          'Found: ${normalizedHeaders.take(expectedHeaders.length).join(', ')}',
        );
      }
    }

    final List<RviaCode> codes = [];

    for (int i = 1; i < table.length; i++) {
      final row = table[i];

      if (row.every((cell) => cell.toString().trim().isEmpty)) {
        continue;
      }

      if (row.length < 6) {
        continue;
      }

      try {
        // Pass through in the SAME ORDER as the CSV:
        // ID, Standard, Type, Discipline, Description, Sub Cat
        final importRow = [row[0], row[1], row[2], row[3], row[4], row[5]];

        codes.add(RviaCode.fromImportRow(importRow, fallbackId: i));
      } catch (_) {
        continue;
      }
    }

    if (codes.isEmpty) {
      throw Exception('No valid RVIA rows were found in the selected file.');
    }

    await DatabaseService().replaceAllRviaCodes(codes);

    return codes.length;
  }

  String _decodeFileBytes(List<int> bytes) {
    if (bytes.isEmpty) return '';

    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      return utf16.decode(bytes);
    }

    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      return utf16.decode(bytes);
    }

    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return utf8.decode(bytes.sublist(3), allowMalformed: true);
    }

    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      try {
        return utf16.decode(bytes);
      } catch (_) {
        return latin1.decode(bytes);
      }
    }
  }

  String _normalizeFileText(String input) {
    return input
        .replaceAll('\uFEFF', '')
        .replaceAll('\ufeff', '')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
  }

  String _normalizeHeader(String value) {
    return value
        .replaceAll('\uFEFF', '')
        .replaceAll('\ufeff', '')
        .replaceAll('"', '')
        .replaceAll('\r', '')
        .trim()
        .toLowerCase();
  }
}
