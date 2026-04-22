class PlantSessionSummary {
  final String plantNumber;
  final int writeupCount;
  final int pendingPdfCount;
  final int pendingDbCount;
  final int pendingCcCount;

  const PlantSessionSummary({
    required this.plantNumber,
    required this.writeupCount,
    this.pendingPdfCount = 0,
    this.pendingDbCount = 0,
    this.pendingCcCount = 0,
  });

  factory PlantSessionSummary.fromMap(Map<String, dynamic> map) {
    return PlantSessionSummary(
      plantNumber: map['plant_number'] as String,
      writeupCount: map['writeupCount'] as int,
      pendingPdfCount: (map['pendingPdfCount'] ?? 0) as int,
      pendingDbCount: (map['pendingDbCount'] ?? 0) as int,
      pendingCcCount: (map['pendingCcCount'] ?? 0) as int,
    );
  }
}
