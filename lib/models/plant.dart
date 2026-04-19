class Plant {
  final int? id;
  final String plantNumber;

  const Plant({this.id, required this.plantNumber});

  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      id: map['id'] as int?,
      plantNumber: map['plant_number'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'plant_number': plantNumber};
  }
}
