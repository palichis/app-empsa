class EmployeeDto {
  final int id;
  final String name;

  EmployeeDto({required this.id, required this.name});

  @override
  String toString() {
    return 'NationalityDto{id: $id, name: $name}';
  }

  factory EmployeeDto.fromJson(Map<String, dynamic> json) {
    return EmployeeDto(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
