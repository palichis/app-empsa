class PublicHallOption {
  final int id; // id de la API
  final int? inspectionId; // FK genérica
  final String name;
  int selected;
  final int synced;

  PublicHallOption({
    required this.id,
    this.inspectionId,
    required this.name,
    this.selected = 0,
    this.synced = 0,
  });

  factory PublicHallOption.fromJson(Map<String, dynamic> json) =>
      PublicHallOption(
        id: json['id'],
        name: json['name'],
        //selected: (json['selected'] == false) ? 0 : 1,
        selected: (json['selected'] == false || json['selected'] == 0) ? 0 : 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'selected': selected,
      };
}
