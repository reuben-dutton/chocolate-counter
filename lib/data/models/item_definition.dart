class ItemDefinition {
  final int? id;
  final String name;
  final String? barcode;
  final String? imageUrl;

  ItemDefinition({
    this.id,
    required this.name,
    this.barcode,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'imageUrl': imageUrl,
    };
  }

  factory ItemDefinition.fromMap(Map<String, dynamic> map) {
    return ItemDefinition(
      id: map['id'],
      name: map['name'],
      barcode: map['barcode'],
      imageUrl: map['imageUrl'],
    );
  }

  ItemDefinition copyWith({
    int? id,
    String? name,
    String? barcode,
    Object? imageUrl = const Object(),
  }) {
    return ItemDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl != const Object() ? (imageUrl as String?) : this.imageUrl,
    );
  }
}