class SecurityFiltersAreaData {
  final String? securityFiltersTime;
  final int securityFiltersObservedDomesticOperators;
  final int securityFiltersObservedInternationalOperators;
  final int securityFiltersObservedDocumentReviewAgents;
  final int securityFiltersPaxWaitingArea;
  final String? securityFiltersOfflineTime;

  SecurityFiltersAreaData({
    this.securityFiltersTime,
    required this.securityFiltersObservedDomesticOperators,
    required this.securityFiltersObservedInternationalOperators,
    required this.securityFiltersObservedDocumentReviewAgents,
    required this.securityFiltersPaxWaitingArea,
    this.securityFiltersOfflineTime,
  });

  factory SecurityFiltersAreaData.fromJson(Map<String, dynamic> json) {
    return SecurityFiltersAreaData(
      securityFiltersTime: json['security_filters_time'],
      securityFiltersObservedDomesticOperators: int.tryParse(
              '${json['security_filters_observed_domestic_operators']}') ??
          0,
      securityFiltersObservedInternationalOperators: int.tryParse(
              '${json['security_filters_observed_international_operators']}') ??
          0,
      securityFiltersObservedDocumentReviewAgents: int.tryParse(
              '${json['security_filters_observed_document_review_agents']}') ??
          0,
      securityFiltersPaxWaitingArea:
          int.tryParse('${json['security_filters_pax_waiting_area']}') ?? 0,
      securityFiltersOfflineTime: json['security_filters_offline_time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'security_filters_time': securityFiltersTime,
      'security_filters_observed_domestic_operators':
          securityFiltersObservedDomesticOperators,
      'security_filters_observed_international_operators':
          securityFiltersObservedInternationalOperators,
      'security_filters_observed_document_review_agents':
          securityFiltersObservedDocumentReviewAgents,
      'security_filters_pax_waiting_area': securityFiltersPaxWaitingArea,
      'security_filters_offline_time': securityFiltersOfflineTime,
    };
  }

  SecurityFiltersAreaData copyWithField(String field, dynamic value) {
    final data = toJson();
    data[field] = value;
    return SecurityFiltersAreaData.fromJson(data);
  }
}
