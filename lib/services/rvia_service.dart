import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../models/rvia_code.dart';

class RviaService {
  static Future<List<RviaCode>> loadCodes() async {
    final rawData = await rootBundle.loadString(
      'assets/sample_data/rvia_sample.csv',
    );

    final List<List<dynamic>> csvTable = const CsvToListConverter(
      eol: '\n',
    ).convert(rawData);

    final headers = csvTable.first.cast<String>();

    return csvTable.skip(1).map((row) {
      final Map<String, String> map = {
        for (int i = 0; i < headers.length; i++) headers[i]: row[i].toString(),
      };
      return RviaCode.fromCsv(map);
    }).toList();
  }
}
