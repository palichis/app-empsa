class ProcessDto {
  final int id;
  final String name;

  ProcessDto({required this.id, required this.name});

  @override
  String toString() {
    return 'ProcessDto{id: $id, name: $name}';
  }

  factory ProcessDto.fromJson(Map<String, dynamic> json) {
    return ProcessDto(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
