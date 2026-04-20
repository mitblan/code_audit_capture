class Department {
  final int? id;
  final String name;

  Department({this.id, required this.name});

  /// Convert Department -> Map (for SQLite)
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  /// Convert Map -> Department (from SQLite)
  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(id: map['id'] as int?, name: map['name'] as String);
  }

  /// Create a modified copy (useful for edits)
  Department copyWith({int? id, String? name}) {
    return Department(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  String toString() => name;
}
