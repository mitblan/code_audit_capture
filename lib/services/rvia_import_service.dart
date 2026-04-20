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

    final headerIndex = <String, int>{};
    for (int i = 0; i < normalizedHeaders.length; i++) {
      headerIndex[normalizedHeaders[i]] = i;
    }

    final idIndex = _findHeaderIndex(headerIndex, ['id', 'rvia id']);
    final standardIndex = _findHeaderIndex(headerIndex, ['standard']);
    final typeIndex = _findHeaderIndex(headerIndex, ['type']);
    final disciplineIndex = _findHeaderIndex(headerIndex, ['discipline']);
    final descriptionIndex = _findHeaderIndex(headerIndex, ['description']);
    final subCatIndex = _findHeaderIndex(headerIndex, ['sub cat', 'subcat']);

    final missingHeaders = <String>[
      if (idIndex == null) 'ID',
      if (standardIndex == null) 'Standard',
      if (typeIndex == null) 'Type',
      if (disciplineIndex == null) 'Discipline',
      if (descriptionIndex == null) 'Description',
      if (subCatIndex == null) 'Sub Cat',
    ];

    if (missingHeaders.isNotEmpty) {
      throw Exception(
        'Unable to read headers. Missing: ${missingHeaders.join(', ')}. '
        'Found: ${headerRow.join(', ')}',
      );
    }

    final List<RviaCode> codes = [];

    for (int i = 1; i < table.length; i++) {
      final row = table[i];

      if (row.every((cell) => cell.toString().trim().isEmpty)) {
        continue;
      }

      final importRow = [
        _cellAt(row, idIndex!),
        _cellAt(row, standardIndex!),
        _cellAt(row, subCatIndex!),
        _cellAt(row, typeIndex!),
        _cellAt(row, disciplineIndex!),
        _cellAt(row, descriptionIndex!),
      ];

      try {
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

  int? _findHeaderIndex(Map<String, int> headerIndex, List<String> aliases) {
    for (final alias in aliases) {
      final normalized = _normalizeHeader(alias);
      if (headerIndex.containsKey(normalized)) {
        return headerIndex[normalized];
      }
    }
    return null;
  }

  dynamic _cellAt(List<dynamic> row, int index) {
    if (index < 0 || index >= row.length) return '';
    return row[index];
  }
}
