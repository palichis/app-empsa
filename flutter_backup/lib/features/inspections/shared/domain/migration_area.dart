// Archivo: migration_area.dart

class MigrationAreaData {
  final int? counters;
  final int? paxArea;
  final double? occupancy;
  final String? offlineTime;
  final String? scope;

  MigrationAreaData({
    this.counters,
    this.paxArea,
    this.occupancy,
    this.offlineTime,
    this.scope,
  });

  factory MigrationAreaData.fromJson(Map<String, dynamic> json, String scope) {
    return MigrationAreaData(
        counters:
            int.tryParse(
                    '${json['migration_area_${scope}_working_counters']}') ??
                0,
        paxArea:
            int.tryParse(
                    '${json['migration_area_${scope}_pax_waiting_area']}') ??
                0,
        occupancy:
            double.tryParse('${json['migration_area_${scope}_occupancy']}') ??
                0.0,
        offlineTime: json['migration_area_${scope}_offline_time'] ?? '',
        scope: scope);
  }

  Map<String, dynamic> toJson() {
    return {
      'migration_area_${scope}_working_counters': counters,
      'migration_area_${scope}_pax_waiting_area': paxArea,
      'migration_area_${scope}_occupancy': occupancy,
      'migration_area_${scope}_offline_time': offlineTime,
    };
  }

  @override
  String toString() {
    return 'MigrationAreaData{counters: $counters, paxArea: $paxArea, occupancy: $occupancy, offlineTime: $offlineTime, scope: $scope}';
  }

  MigrationAreaData copyWithField(String field, dynamic value) {
    final json = toJson();
    json[field] = value;
    return MigrationAreaData.fromJson(json, scope!);
  }
}
