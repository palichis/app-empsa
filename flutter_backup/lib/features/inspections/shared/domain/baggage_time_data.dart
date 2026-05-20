class BaggageTimeData {
  int? id;
  final String? flightNumber;
  final String? origin;
  final String? scheduledTimeA;
  final String? arrivalTimeB;
  final String? diffBA;
  final String? assignedBelt;
  final String? firstPaxTimeC;
  final String? firstBagTimeD;
  final String? lastBagTimeE;
  final String? diffDC;
  final String? diffED;
  final String? ndsTimeFunction;

  BaggageTimeData({
    this.id,
    this.flightNumber,
    this.origin,
    this.scheduledTimeA,
    this.arrivalTimeB,
    this.diffBA,
    this.assignedBelt,
    this.firstPaxTimeC,
    this.firstBagTimeD,
    this.lastBagTimeE,
    this.diffDC,
    this.diffED,
    this.ndsTimeFunction,
  });

  factory BaggageTimeData.fromJson(Map<String, dynamic> json) {
    final rawAssignedBelt = json['assigned_belt'];
    String? parsedAssignedBelt;
    if (rawAssignedBelt is List) {
      parsedAssignedBelt = rawAssignedBelt.join(',');
    }
    if (rawAssignedBelt is String) {
      parsedAssignedBelt = rawAssignedBelt;
    }
    return BaggageTimeData(
        //TODO cambiar logica de flight_numer para guardar como flight_option y tomar ese dato como el nombre de cada panels
        flightNumber: json['flight_number'],
        origin: json['origin'],
        scheduledTimeA: json['scheduled_time_a_hhmm'],
        arrivalTimeB: json['arrival_time_b_hhmm'],
        //diffBA: json['diff_ba'],
        assignedBelt: parsedAssignedBelt,
        firstPaxTimeC: json['first_pax_arrival_c_hhmm'],
        firstBagTimeD: json['first_bag_arrival_d_hhmm'],
        lastBagTimeE: json['last_bag_arrival_e_hhmm'],
        /*diffDC: json['diff_dc'],
        diffED: json['diff_ed'],
        ndsTimeFunction: json['nds_time_function'],*/
        id: json['id']);
  }
  Map<String, dynamic> toJson() => {
        'flight_number': flightNumber,
        'origin': origin,
        'scheduled_time_a_hhmm': scheduledTimeA,
        'arrival_time_b_hhmm': arrivalTimeB,
        //'diff_ba': diffBA,
        'assigned_belt': assignedBelt,
        'first_pax_arrival_c_hhmm': firstPaxTimeC,
        'first_bag_arrival_d_hhmm': firstBagTimeD,
        'last_bag_arrival_e_hhmm': lastBagTimeE,
        /*'diff_dc': diffDC,
        'diff_ed': diffED,
        'nds_time_function': ndsTimeFunction,*/
        'id': id
      };

  BaggageTimeData mergeWith(BaggageTimeData other) {
    return BaggageTimeData(
      id: id,
      flightNumber: other.flightNumber ?? flightNumber,
      origin: other.origin ?? origin,
      scheduledTimeA: other.scheduledTimeA ?? scheduledTimeA,
      arrivalTimeB: other.arrivalTimeB ?? arrivalTimeB,
      diffBA: other.diffBA ?? diffBA,
      assignedBelt: other.assignedBelt ?? assignedBelt,
      firstPaxTimeC: other.firstPaxTimeC ?? firstPaxTimeC,
      firstBagTimeD: other.firstBagTimeD ?? firstBagTimeD,
      lastBagTimeE: other.lastBagTimeE ?? lastBagTimeE,
      diffDC: other.diffDC ?? diffDC,
      diffED: other.diffED ?? diffED,
      ndsTimeFunction: other.ndsTimeFunction ?? ndsTimeFunction,
    );
  }
}

extension BaggageTimeDataCopyHelper on BaggageTimeData {
  BaggageTimeData copyWithField(String field, dynamic value) {
    final json = toJson();
    json[field] = value;
    return BaggageTimeData.fromJson(json);
  }
}
