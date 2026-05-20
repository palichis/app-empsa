class FlightOption {
  final int id;
  final String name;
  final String time;
  int selected;
  final String destiny;
  final int? nationalDepartureId;
  final int? internationalDepartureId;

  FlightOption(
      {required this.id,
      required this.name,
      required this.destiny,
        required this.time,
        this.selected = 0,
      this.nationalDepartureId,
      this.internationalDepartureId});

  factory FlightOption.fromJson(Map<String, dynamic> json) => FlightOption(
        time:json['time'],
        id: json['id'],
        name: json['name'],
        //selected: (json['selected'] == false) ? 0 : 1,
        selected: (json['selected'] == false || json['selected'] == 0) ? 0 : 1,
        destiny: json['destiny'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'selected': selected,
        'destiny': destiny,
      };
}
