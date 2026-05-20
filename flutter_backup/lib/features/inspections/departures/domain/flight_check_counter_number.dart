class FlightCheckCounterNumber {
  final int id;
  final String name;
  int selected;
  final int? nationalDepartureId;
  final int? internationalDepartureId;

  FlightCheckCounterNumber(
      {required this.id,
      required this.name,
      this.selected = 0,
      this.nationalDepartureId,
      this.internationalDepartureId});

  factory FlightCheckCounterNumber.fromJson(Map<String, dynamic> json) {
    return FlightCheckCounterNumber(
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
