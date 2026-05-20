class SecurityFiltersTimeData {
  final String? securityFiltersAttentionTimePerPax1;
  final String? securityFiltersAttentionTimePerPax2;
  final String? securityFiltersAttentionTimePerPax3;
  final String? securityFiltersAttentionTimePerPax4;
  final String? securityFiltersAttentionTimePerPax5;

  SecurityFiltersTimeData({
    this.securityFiltersAttentionTimePerPax1,
    this.securityFiltersAttentionTimePerPax2,
    this.securityFiltersAttentionTimePerPax3,
    this.securityFiltersAttentionTimePerPax4,
    this.securityFiltersAttentionTimePerPax5,
  });

  factory SecurityFiltersTimeData.fromJson(Map<String, dynamic> json) {
    return SecurityFiltersTimeData(
      securityFiltersAttentionTimePerPax1:
          json['security_filters_attention_time_per_pax_1'],
      securityFiltersAttentionTimePerPax2:
          json['security_filters_attention_time_per_pax_2'],
      securityFiltersAttentionTimePerPax3:
          json['security_filters_attention_time_per_pax_3'],
      securityFiltersAttentionTimePerPax4:
          json['security_filters_attention_time_per_pax_4'],
      securityFiltersAttentionTimePerPax5:
          json['security_filters_attention_time_per_pax_5'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'security_filters_attention_time_per_pax_1':
          securityFiltersAttentionTimePerPax1,
      'security_filters_attention_time_per_pax_2':
          securityFiltersAttentionTimePerPax2,
      'security_filters_attention_time_per_pax_3':
          securityFiltersAttentionTimePerPax3,
      'security_filters_attention_time_per_pax_4':
          securityFiltersAttentionTimePerPax4,
      'security_filters_attention_time_per_pax_5':
          securityFiltersAttentionTimePerPax5,
    };
  }

  SecurityFiltersTimeData copyWithField(String field, dynamic value) {
    final data = toJson();
    data[field] = value;
    return SecurityFiltersTimeData.fromJson(data);
  }
}
