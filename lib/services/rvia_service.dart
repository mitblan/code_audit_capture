import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

import '../models/rvia_code.dart';
import 'database_service.dart';

class RviaService {
  static Future<List<RviaCode>> loadCodes() async {
    final db = DatabaseService();
    final count = await db.getRviaCodeCount();

    if (count > 0) {
      return await db.getAllRviaCodes();
    }

    return await _loadCodesFromSampleCsv();
  }

  static Future<List<RviaCode>> _loadCodesFromSampleCsv() async {
    final rawData = await rootBundle.loadString(
      'assets/sample_data/rvia_sample.csv',
    );

    final List<List<dynamic>> csvTable = const CsvToListConverter(
      eol: '\n',
    ).convert(rawData);

    if (csvTable.isEmpty) return [];

    final headers = csvTable.first.map((h) => h.toString()).toList();

    return csvTable.skip(1).where((row) => row.isNotEmpty).map((row) {
      final Map<String, String> map = {
        for (int i = 0; i < headers.length && i < row.length; i++)
          headers[i]: row[i].toString(),
      };

      return RviaCode.fromCsv(map);
    }).toList();
  }
}
