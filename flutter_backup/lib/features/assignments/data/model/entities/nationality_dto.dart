class NationalityDto {
  final int id;
  final String name;

  NationalityDto({required this.id, required this.name});

  @override
  String toString() {
    return 'NationalityDto{id: $id, name: $name}';
  }

  factory NationalityDto.fromJson(Map<String, dynamic> json) {
    return NationalityDto(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
