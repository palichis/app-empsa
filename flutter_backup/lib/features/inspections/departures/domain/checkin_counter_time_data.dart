class CheckinCounterTimeData {
  final String? checkinCounterAttentionTimePerPax1;
  final String? checkinCounterAttentionTimePerPax2;
  final String? checkinCounterAttentionTimePerPax3;
  final String? checkinCounterAttentionTimePerPax4;
  final String? checkinCounterAttentionTimePerPax5;
  final String? checkinCounterAttentionTimePerPaxMax;

  CheckinCounterTimeData({
    this.checkinCounterAttentionTimePerPax1,
    this.checkinCounterAttentionTimePerPax2,
    this.checkinCounterAttentionTimePerPax3,
    this.checkinCounterAttentionTimePerPax4,
    this.checkinCounterAttentionTimePerPax5,
    this.checkinCounterAttentionTimePerPaxMax,
  });

  factory CheckinCounterTimeData.fromJson(Map<String, dynamic> json) {
    return CheckinCounterTimeData(
      checkinCounterAttentionTimePerPax1:
          json['checkin_counter_attention_time_per_pax_1'],
      checkinCounterAttentionTimePerPax2:
          json['checkin_counter_attention_time_per_pax_2'],
      checkinCounterAttentionTimePerPax3:
          json['checkin_counter_attention_time_per_pax_3'],
      checkinCounterAttentionTimePerPax4:
          json['checkin_counter_attention_time_per_pax_4'],
      checkinCounterAttentionTimePerPax5:
          json['checkin_counter_attention_time_per_pax_5'],
      checkinCounterAttentionTimePerPaxMax:
          json['checkin_counter_attention_time_per_pax_max'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'checkin_counter_attention_time_per_pax_1':
          checkinCounterAttentionTimePerPax1,
      'checkin_counter_attention_time_per_pax_2':
          checkinCounterAttentionTimePerPax2,
      'checkin_counter_attention_time_per_pax_3':
          checkinCounterAttentionTimePerPax3,
      'checkin_counter_attention_time_per_pax_4':
          checkinCounterAttentionTimePerPax4,
      'checkin_counter_attention_time_per_pax_5':
          checkinCounterAttentionTimePerPax5,
      'checkin_counter_attention_time_per_pax_max':
          checkinCounterAttentionTimePerPaxMax,
    };
  }

  CheckinCounterTimeData copyWithField(String field, dynamic value) {
    final data = toJson();
    data[field] = value;
    return CheckinCounterTimeData.fromJson(data);
  }
}
