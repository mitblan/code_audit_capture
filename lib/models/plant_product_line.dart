class PlantProductLine {
  final int? id;
  final String plantNumber;
  final int productLineId;
  final bool isDefault;

  PlantProductLine({
    this.id,
    required this.plantNumber,
    required this.productLineId,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plant_number': plantNumber,
      'product_line_id': productLineId,
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory PlantProductLine.fromMap(Map<String, dynamic> map) {
    return PlantProductLine(
      id: map['id'] as int?,
      plantNumber: map['plant_number'] as String,
      productLineId: map['product_line_id'] as int,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
    );
  }

  PlantProductLine copyWith({
    int? id,
    String? plantNumber,
    int? productLineId,
    bool? isDefault,
  }) {
    return PlantProductLine(
      id: id ?? this.id,
      plantNumber: plantNumber ?? this.plantNumber,
      productLineId: productLineId ?? this.productLineId,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
