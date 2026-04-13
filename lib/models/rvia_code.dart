class RviaCode {
  final int rviaId;
  final String standard;
  final String subCat;
  final String codeReference;
  final String type;
  final String discipline;
  final String description;

  RviaCode({
    required this.rviaId,
    required this.standard,
    required this.subCat,
    required this.codeReference,
    required this.type,
    required this.discipline,
    required this.description,
  });

  factory RviaCode.fromCsv(Map<String, String> row) {
    return RviaCode(
      rviaId: int.parse(row['rvia_id']!),
      standard: row['standard']!,
      subCat: row['sub_cat']!,
      codeReference: row['code_reference']!,
      type: row['type']!,
      discipline: row['discipline']!,
      description: row['description']!,
    );
  }
}
