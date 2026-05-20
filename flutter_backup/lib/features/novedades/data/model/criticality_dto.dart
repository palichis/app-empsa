class CriticalityDTO {
  final int id;
  final String name;

  CriticalityDTO({required this.id, required this.name});

  @override
  String toString() {
    return 'AreaDto{id: $id, name: $name}';
  }

  factory CriticalityDTO.fromJson(Map<String, dynamic> json) {
    return CriticalityDTO(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
