class GeneralData {
  final DateTime? measurementDate;
  final String? hour;
  final String? peakHour;
  final int? flightCount;
  final int? preparedById;
  final String? preparedBy;
  final String? reviewedBy;
  final int? reviewedById;

  GeneralData({
    this.measurementDate,
    this.hour,
    this.peakHour,
    this.flightCount,
    this.preparedById,
    this.preparedBy,
    this.reviewedById,
    this.reviewedBy,
  });

  factory GeneralData.fromJson(Map<String, dynamic> json) => GeneralData(
        measurementDate: DateTime.parse(json['general_data_measurement_date']),
        hour: json['general_data_hour'] ?? '',
        peakHour: json['general_data_peak_hour'] ?? '',
        flightCount: json['general_data_flight_count'] ?? 0,
        preparedById:
            int.tryParse('${json['general_data_prepared_by_id']}') ?? 0,
        preparedBy: json['general_data_prepared_by'] ?? '',
        reviewedById:
            int.tryParse('${json['general_data_reviewed_by_id']}') ?? 0,
        reviewedBy: json['general_data_reviewed_by'] ?? '',
      );

  Map<String, dynamic> toJson() {
    return {
      'general_data_measurement_date':
          measurementDate != null ? measurementDate!.toIso8601String() : '',
      'general_data_hour': hour,
      'general_data_peak_hour': peakHour,
      'general_data_flight_count': flightCount ?? 0,
      'general_data_prepared_by_id': preparedById ?? 0,
      'general_data_prepared_by': preparedBy,
      'general_data_reviewed_by_id': reviewedById ?? 0,
      'general_data_reviewed_by': reviewedBy ?? '',
    };
  }
}
