class SelfCheckinKiosksData {
  final String? selfCheckinKiosksTime;
  final String? selfCheckinKiosksServiceTimePerPax1;
  final String? selfCheckinKiosksServiceTimePerPax2;
  final String? selfCheckinKiosksAverage;
  final String? selfCheckinKiosksMaximumWaitingTime;
  final String? selfCheckinKiosksNdsTimeFunction;
  //final String? selfCheckinKiosksPhoto;

  SelfCheckinKiosksData({
    this.selfCheckinKiosksTime,
    this.selfCheckinKiosksServiceTimePerPax1,
    this.selfCheckinKiosksServiceTimePerPax2,
    this.selfCheckinKiosksAverage,
    this.selfCheckinKiosksMaximumWaitingTime,
    this.selfCheckinKiosksNdsTimeFunction,
    //this.selfCheckinKiosksPhoto,
  });

  factory SelfCheckinKiosksData.fromJson(Map<String, dynamic> json) {
    return SelfCheckinKiosksData(
      selfCheckinKiosksTime: json['self_checkin_kiosks_time'],
      selfCheckinKiosksServiceTimePerPax1:
          json['self_checkin_kiosks_service_time_per_pax_1'],
      selfCheckinKiosksServiceTimePerPax2:
          json['self_checkin_kiosks_service_time_per_pax_2'],
      selfCheckinKiosksAverage: json['self_checkin_kiosks_average'],
      selfCheckinKiosksMaximumWaitingTime:
          json['self_checkin_kiosks_maximum_waiting_time'],
      selfCheckinKiosksNdsTimeFunction:
          json['self_checkin_kiosks_nds_time_function'],
      //selfCheckinKiosksPhoto: json['self_checkin_kiosks_photo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'self_checkin_kiosks_time': selfCheckinKiosksTime,
      'self_checkin_kiosks_service_time_per_pax_1':
          selfCheckinKiosksServiceTimePerPax1,
      'self_checkin_kiosks_service_time_per_pax_2':
          selfCheckinKiosksServiceTimePerPax2,
      'self_checkin_kiosks_average': selfCheckinKiosksAverage,
      'self_checkin_kiosks_maximum_waiting_time':
          selfCheckinKiosksMaximumWaitingTime,
      'self_checkin_kiosks_nds_time_function': selfCheckinKiosksNdsTimeFunction,
      //'self_checkin_kiosks_photo': selfCheckinKiosksPhoto,
    };
  }

  SelfCheckinKiosksData copyWithField(String field, dynamic value) {
    final data = toJson();
    data[field] = value;
    return SelfCheckinKiosksData.fromJson(data);
  }
}
