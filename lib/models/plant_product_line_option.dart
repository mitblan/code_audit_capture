class PlantProductLineOption {
  final int assignmentId;
  final int productLineId;
  final String plantNumber;
  final String code;
  final bool isDefault;

  PlantProductLineOption({
    required this.assignmentId,
    required this.productLineId,
    required this.plantNumber,
    required this.code,
    required this.isDefault,
  });

  factory PlantProductLineOption.fromMap(Map<String, dynamic> map) {
    return PlantProductLineOption(
      assignmentId: map['assignment_id'] as int,
      productLineId: map['product_line_id'] as int,
      plantNumber: map['plant_number'] as String,
      code: map['code'] as String,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
    );
  }
}
