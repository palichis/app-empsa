class CustomsData {
  final String? time;
  final int? rxMachineOperating;
  final int? passportScannerKiosks;
  final int? paxWaitingArea;
  final double? occupancyArea;
  final String? offlineTime;
  final String? maxWaitingTime;
  final String? ndsArea;
  final String? ndsTime;

  CustomsData({
    this.time,
    this.rxMachineOperating,
    this.passportScannerKiosks,
    this.paxWaitingArea,
    this.occupancyArea,
    this.offlineTime,
    this.maxWaitingTime,
    this.ndsArea,
    this.ndsTime,
  });

  factory CustomsData.fromJson(Map<String, dynamic> json) {
    return CustomsData(
      time: json['customs_time'] ?? '',
      rxMachineOperating: int.tryParse('${json['customs_maq_rx_oper']}') ?? 0,
      passportScannerKiosks:
          int.tryParse('${json['customs_kiosko_pass']}') ?? 0,
      paxWaitingArea: int.tryParse('${json['customs_pax_waiting_area']}') ?? 0,
      occupancyArea: double.tryParse(
              json['customs_area_occupancy']?.toString() ?? '0.0') ??
          0.0,
      offlineTime: json['customs_offline_time'] ?? '',
      maxWaitingTime: json['customs_waiting_time_max'] ?? '',
      ndsArea: json['customs_nds_area'] ?? '',
      ndsTime: json['customs_nds_time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customs_time': time,
      'customs_maq_rx_oper': rxMachineOperating,
      'customs_kiosko_pass': passportScannerKiosks,
      'customs_pax_waiting_area': paxWaitingArea,
      'customs_area_occupancy': occupancyArea,
      'customs_offline_time': offlineTime,
      'customs_waiting_time_max': maxWaitingTime,
      'customs_nds_area': ndsArea,
      'customs_nds_time': ndsTime,
    };
  }
}
