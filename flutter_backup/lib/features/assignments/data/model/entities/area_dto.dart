class AreaDto {
  final int id;
  final String name;

  AreaDto({required this.id, required this.name});

  @override
  String toString() {
    return 'AreaDto{id: $id, name: $name}';
  }

  factory AreaDto.fromJson(Map<String, dynamic> json) {
    return AreaDto(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
