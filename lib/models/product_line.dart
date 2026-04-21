class ProductLine {
  final int? id;
  final String code;

  ProductLine({this.id, required this.code});

  Map<String, dynamic> toMap() {
    return {'id': id, 'code': code};
  }

  factory ProductLine.fromMap(Map<String, dynamic> map) {
    return ProductLine(id: map['id'] as int?, code: map['code'] as String);
  }

  ProductLine copyWith({int? id, String? code}) {
    return ProductLine(id: id ?? this.id, code: code ?? this.code);
  }

  @override
  String toString() => code;
}
