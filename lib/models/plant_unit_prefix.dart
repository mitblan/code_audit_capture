class PlantUnitPrefix {
  final int? id;
  final String plantNumber;
  final String prefix;
  final bool isDefault;

  PlantUnitPrefix({
    this.id,
    required this.plantNumber,
    required this.prefix,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plant_number': plantNumber,
      'prefix': prefix,
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory PlantUnitPrefix.fromMap(Map<String, dynamic> map) {
    return PlantUnitPrefix(
      id: map['id'] as int?,
      plantNumber: map['plant_number'] as String,
      prefix: map['prefix'] as String,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
    );
  }

  PlantUnitPrefix copyWith({
    int? id,
    String? plantNumber,
    String? prefix,
    bool? isDefault,
  }) {
    return PlantUnitPrefix(
      id: id ?? this.id,
      plantNumber: plantNumber ?? this.plantNumber,
      prefix: prefix ?? this.prefix,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  String toString() => prefix;
}
