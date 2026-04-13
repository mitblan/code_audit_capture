class AuditWriteup {
  final int? id;
  final String plantNumber;
  final String codeReference;
  final String discipline;
  final String description;
  final DateTime createdAt;

  final int? rviaId;
  final String? rviaType;
  final String? rviaDescription;

  AuditWriteup({
    this.id,
    required this.plantNumber,
    required this.codeReference,
    required this.discipline,
    required this.description,
    required this.createdAt,
    this.rviaId,
    this.rviaType,
    this.rviaDescription,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plant_number': plantNumber,
      'code_reference': codeReference,
      'discipline': discipline,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'rvia_id': rviaId,
      'rvia_type': rviaType,
      'rvia_description': rviaDescription,
    };
  }

  factory AuditWriteup.fromMap(Map<String, dynamic> map) {
    return AuditWriteup(
      id: map['id'] as int?,
      plantNumber: map['plant_number'] as String,
      codeReference: map['code_reference'] as String,
      discipline: map['discipline'] as String,
      description: map['description'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      rviaId: map['rvia_id'] as int?,
      rviaType: map['rvia_type'] as String?,
      rviaDescription: map['rvia_description'] as String?,
    );
  }
}
