class AuditWriteup {
  final int? id;

  // Session-Based Fields
  final String plantNumber;
  final DateTime dateDetected;
  final String detectedBy;

  // Unit Information
  final String unitNumber;
  final String modelNumber;
  final String department;
  final String nonConformanceNo;

  // RVIA Fields
  final String category;
  final String newCodeReference;
  final String codeClass;
  final String codeDescription;

  // Repeat Violation
  final bool repeatViolation;
  final int timesRepeat;

  // Issue Flags
  final bool grounding;
  final bool solar;
  final bool panelBoard;
  final bool applianceInstall;

  // RVIA Link Metadata
  final int? rviaId;
  final String? rviaType;
  final String? rviaDescription;

  AuditWriteup({
    this.id,
    required this.plantNumber,
    required this.dateDetected,
    this.detectedBy = 'Audit',
    required this.unitNumber,
    required this.modelNumber,
    required this.department,
    required this.nonConformanceNo,
    required this.category,
    required this.newCodeReference,
    required this.codeClass,
    required this.codeDescription,
    this.repeatViolation = false,
    this.timesRepeat = 0,
    this.grounding = false,
    this.solar = false,
    this.panelBoard = false,
    this.applianceInstall = false,
    this.rviaId,
    this.rviaType,
    this.rviaDescription,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plant_number': plantNumber,
      'date_detected': dateDetected.toIso8601String(),
      'detected_by': detectedBy,
      'unit_number': unitNumber,
      'model_number': modelNumber,
      'department': department,
      'non_conformance_no': nonConformanceNo,
      'category': category,
      'new_code_reference': newCodeReference,
      'code_class': codeClass,
      'code_description': codeDescription,
      'repeat_violation': repeatViolation ? 1 : 0,
      'times_repeat': timesRepeat,
      'grounding': grounding ? 1 : 0,
      'solar': solar ? 1 : 0,
      'panel_board': panelBoard ? 1 : 0,
      'appliance_install': applianceInstall ? 1 : 0,
      'rvia_id': rviaId,
      'rvia_type': rviaType,
      'rvia_description': rviaDescription,
    };
  }

  factory AuditWriteup.fromMap(Map<String, dynamic> map) {
    return AuditWriteup(
      id: map['id'] as int?,
      plantNumber: map['plant_number'] as String,
      dateDetected: DateTime.parse(map['date_detected'] as String),
      detectedBy: map['detected_by'] as String? ?? 'Audit',
      unitNumber: map['unit_number'] as String,
      modelNumber: map['model_number'] as String,
      department: map['department'] as String,
      nonConformanceNo: map['non_conformance_no'] as String,
      category: map['category'] as String,
      newCodeReference: map['new_code_reference'] as String,
      codeClass: map['code_class'] as String,
      codeDescription: map['code_description'] as String,
      repeatViolation: (map['repeat_violation'] as int) == 1,
      timesRepeat: map['times_repeat'] as int,
      grounding: (map['grounding'] as int) == 1,
      solar: (map['solar'] as int) == 1,
      panelBoard: (map['panel_board'] as int) == 1,
      applianceInstall: (map['appliance_install'] as int) == 1,
      rviaId: map['rvia_id'] as int?,
      rviaType: map['rvia_type'] as String?,
      rviaDescription: map['rvia_description'] as String?,
    );
  }
}
