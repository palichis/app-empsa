class CheckinCounterAreaData {
  final String? checkinCounterTime;
  final String? checkinCounterAssignedCountersZone;
  final int checkinCounterAssignedCounters;
  final int checkinCounterOperatingCounters;
  final int checkinCounterPaxWaitingArea;
  final String? checkinCounterOfflineTime;

  CheckinCounterAreaData({
    this.checkinCounterTime,
    this.checkinCounterAssignedCountersZone,
    required this.checkinCounterAssignedCounters,
    required this.checkinCounterOperatingCounters,
    required this.checkinCounterPaxWaitingArea,
    this.checkinCounterOfflineTime,
  });

  factory CheckinCounterAreaData.fromJson(Map<String, dynamic> json) {
    return CheckinCounterAreaData(
      checkinCounterTime: json['checkin_counter_time'],
      /*checkinCounterAssignedCountersZone:
          json['checkin_counter_assigned_counters_zone'],*/
      checkinCounterAssignedCounters:
          int.tryParse('${json['checkin_counter_assigned_counters']}') ?? 0,
      checkinCounterOperatingCounters:
          int.tryParse('${json['checkin_counter_operating_counters']}') ?? 0,
      checkinCounterPaxWaitingArea:
          int.tryParse('${json['checkin_counter_pax_waiting_area']}') ?? 0,
      checkinCounterOfflineTime: json['checkin_counter_offline_time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'checkin_counter_time': checkinCounterTime,
      /*'checkin_counter_assigned_counters_zone':
          checkinCounterAssignedCountersZone,*/
      'checkin_counter_assigned_counters': checkinCounterAssignedCounters,
      'checkin_counter_operating_counters': checkinCounterOperatingCounters,
      'checkin_counter_pax_waiting_area': checkinCounterPaxWaitingArea,
      'checkin_counter_offline_time': checkinCounterOfflineTime,
    };
  }

  CheckinCounterAreaData copyWithField(String field, dynamic value) {
    final data = toJson();
    data[field] = value;
    return CheckinCounterAreaData.fromJson(data);
  }
}
