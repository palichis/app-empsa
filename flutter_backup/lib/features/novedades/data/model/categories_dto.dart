class CategoriesDTO {
  final int id;
  final String name;

  CategoriesDTO({required this.id, required this.name});

  @override
  String toString() {
    return 'AreaDto{id: $id, name: $name}';
  }

  factory CategoriesDTO.fromJson(Map<String, dynamic> json) {
    return CategoriesDTO(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
