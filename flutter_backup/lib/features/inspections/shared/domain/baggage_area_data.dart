class BaggageAreaData {
  final List<String> belts;
  final String? notes_belts;
  final String? time1;
  final int? pax1;
  final String? time2;
  final int? pax2;
  final String? time3;
  final int? pax3;
  final String? ndsAreaFunction;

  BaggageAreaData({
    //this.belts,
    this.belts = const [],
    this.notes_belts,
    this.time1,
    this.pax1,
    this.time2,
    this.pax2,
    this.time3,
    this.pax3,
    this.ndsAreaFunction,
  });

  factory BaggageAreaData.fromJson(Map<String, dynamic> json) {
    final beltsRaw = json['baggage_claim_belts'] as String? ?? '';
    final beltsList = beltsRaw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return BaggageAreaData(
      belts: beltsList,
      notes_belts: json['notes_belts'],
      time1: json['baggage_claim_time_1'] ?? '',
      pax1: int.tryParse('${json['baggage_claim_pax_waiting_area_1']}') ??
          0, //json['baggage_claim_pax_waiting_area_1'] ?? 0,
      time2: json['baggage_claim_time_2'] ?? '',
      pax2: int.tryParse(
          '${json['baggage_claim_pax_waiting_area_2']}'), //json['baggage_claim_pax_waiting_area_2'] ?? 0,
      time3: json['baggage_claim_time_3'] ?? '',
      pax3: int.tryParse(
          '${json['baggage_claim_pax_waiting_area_3']}'), //json['baggage_claim_pax_waiting_area_3'] ?? 0,
      ndsAreaFunction: json['baggage_claim_area_function'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'baggage_claim_belts': belts.join(','),
        'notes_belts': notes_belts,
        'baggage_claim_time_1': time1,
        'baggage_claim_pax_waiting_area_1': pax1 ?? 0,
        'baggage_claim_time_2': time2,
        'baggage_claim_pax_waiting_area_2': pax2 ?? 0,
        'baggage_claim_time_3': time3,
        'baggage_claim_pax_waiting_area_3': pax3 ?? 0,
        'baggage_claim_area_function': ndsAreaFunction,
      };
}
