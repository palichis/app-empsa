class FlightPreboardingRoom {
  final int id;
  final String name;
  int selected;
  final int? nationalDepartureId;
  final int? internationalDepartureId;

  FlightPreboardingRoom({
    required this.id,
    required this.name,
    this.selected = 0,
    this.nationalDepartureId,
    this.internationalDepartureId,
  });

  factory FlightPreboardingRoom.fromJson(Map<String, dynamic> json) {
    return FlightPreboardingRoom(
      id: json['id'] as int,
      name: json['name'] as String,
      selected: (json['selected'] == false || json['selected'] == 0) ? 0 : 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'selected': selected == 1 ? true : false,
      };
}
