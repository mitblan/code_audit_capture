class RviaCode {
  final int rviaId;
  final String standard;
  final String subCat;
  final String type;
  final String discipline;
  final String description;

  RviaCode({
    required this.rviaId,
    required this.standard,
    required this.subCat,
    required this.type,
    required this.discipline,
    required this.description,
  });

  String get codeReference => '$standard($subCat)';

  factory RviaCode.fromCsv(Map<String, String> row) {
    return RviaCode(
      rviaId:
          int.tryParse(
            (row['ID'] ?? row['rvia_id'] ?? '')
                .replaceAll('\ufeff', '')
                .replaceAll('"', '')
                .trim(),
          ) ??
          0,
      standard: (row['Standard'] ?? row['standard'] ?? '')
          .replaceAll('\ufeff', '')
          .trim(),
      subCat: (row['Sub Cat'] ?? row['sub_cat'] ?? '')
          .replaceAll('\ufeff', '')
          .trim(),
      type: (row['Type'] ?? row['type'] ?? '').replaceAll('\ufeff', '').trim(),
      discipline: (row['Discipline'] ?? row['discipline'] ?? '')
          .replaceAll('\ufeff', '')
          .trim(),
      description: (row['Description'] ?? row['description'] ?? '')
          .replaceAll('\ufeff', '')
          .trim(),
    );
  }

  factory RviaCode.fromImportRow(List<dynamic> row, {required int fallbackId}) {
    final rawId = row[0]
        .toString()
        .replaceAll('\ufeff', '')
        .replaceAll('"', '')
        .trim();

    final parsedId = int.tryParse(rawId);

    return RviaCode(
      rviaId: parsedId ?? fallbackId,
      standard: row[1].toString().replaceAll('\ufeff', '').trim(),
      type: row[2].toString().replaceAll('\ufeff', '').trim(),
      discipline: row[3].toString().replaceAll('\ufeff', '').trim(),
      description: row[4].toString().replaceAll('\ufeff', '').trim(),
      subCat: row[5].toString().replaceAll('\ufeff', '').trim(),
    );
  }

  factory RviaCode.fromMap(Map<String, dynamic> map) {
    return RviaCode(
      rviaId: map['rvia_id'] as int,
      standard: map['standard'] as String,
      subCat: map['sub_cat'] as String,
      type: map['type'] as String,
      discipline: map['discipline'] as String,
      description: map['description'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rvia_id': rviaId,
      'standard': standard,
      'sub_cat': subCat,
      'type': type,
      'discipline': discipline,
      'description': description,
    };
  }
}
