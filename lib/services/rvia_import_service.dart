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

    String rawData;

    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      rawData = utf16.decode(bytes);
    } else if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      rawData = utf16.decode(bytes);
    } else {
      try {
        rawData = utf8.decode(bytes);
      } catch (_) {
        try {
          rawData = utf16.decode(bytes);
        } catch (_) {
          rawData = latin1.decode(bytes);
        }
      }
    }

    final normalized = rawData.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final lines = normalized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      throw Exception('Selected CSV file is empty.');
    }

    final converter = const CsvToListConverter(
      fieldDelimiter: ',',
      textDelimiter: '"',
      eol: '\n',
      shouldParseNumbers: false,
    );

    final headerTable = converter.convert('${lines.first}\n');
    if (headerTable.isEmpty || headerTable.first.length < 6) {
      throw Exception('Unable to parse RVIA header row.');
    }

    final dataLines = lines.skip(1).toList();
    final List<RviaCode> codes = [];

    for (int i = 0; i < dataLines.length; i++) {
      final line = dataLines[i];

      List<List<dynamic>> parsedLine;
      try {
        parsedLine = converter.convert('$line\n');
      } catch (_) {
        continue;
      }

      if (parsedLine.isEmpty) continue;

      final row = parsedLine.first;
      if (row.length < 6) continue;

      codes.add(RviaCode.fromImportRow(row, fallbackId: i + 1));
    }

    if (codes.isEmpty) {
      throw Exception('No valid RVIA rows were found in the selected file.');
    }

    await DatabaseService().replaceAllRviaCodes(codes);

    return codes.length;
  }
}
