import 'package:epmsa_mobile/features/inspections/shared/domain/migration_area.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/migration_time.dart';

class MigrationData {
  final MigrationAreaData areaNational;
  final MigrationAreaData areaInternational;
  //final int? totalCounters;
  //final int? totalPax;
  final int? migrationId;
  final String? ndsArea;
  final MigrationTimeData timeNational;
  final MigrationTimeData timeInternational;
  final String? maxWaitTime;
  final String? ndsTime;
  final String? hour;

  MigrationData(
      {required this.areaNational,
      required this.areaInternational,
      //this.totalCounters,
      //this.totalPax,
      this.migrationId,
      this.ndsArea,
      required this.timeNational,
      required this.timeInternational,
      this.maxWaitTime,
      this.ndsTime,
      this.hour});

  factory MigrationData.fromJson(Map<String, dynamic> json) {
    int? selectedId;
    if (json['migration_id'] is List) {
      final list = json['migration_id'] as List;
      final selectedItem = list.cast<Map<String, dynamic>?>().firstWhere(
            (item) => item?['selected'] == true,
            orElse: () => null,
          );
      selectedId = selectedItem != null ? selectedItem['id'] as int? : null;
    } else {
      selectedId = json['migration_id'] ?? 0;
    }
    return MigrationData(
      areaNational: MigrationAreaData.fromJson(json, 'national'),
      areaInternational: MigrationAreaData.fromJson(json, 'international'),
      //totalCounters: json['migration_total_counters_attending'] ?? 0,
      //totalPax: json['migration_total_pax_waiting_area'] ?? 0,
      migrationId: selectedId ?? 0,
      ndsArea: json['migration_nds_area'] ?? '',
      timeNational: MigrationTimeData.fromJson(json, 'national'),
      timeInternational: MigrationTimeData.fromJson(json, 'international'),
      maxWaitTime: json['migration_max_waiting_time'] ?? '',
      ndsTime: json['migration_nds_time'] ?? '',
      hour: json['migration_area_time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'migration_id': migrationId,
      //'migration_areaNational': areaNational.toJson(),
      //'migration_areaInternational': areaInternational.toJson(),
      ...areaNational.toJson(),
      ...areaInternational.toJson(),
      ...timeNational.toJson(),
      ...timeInternational.toJson(),
      //'migration_total_counters_attending': totalCounters,
      //'migration_total_pax_waiting_area': totalPax,
      'migration_nds_area': ndsArea,
      'migration_max_waiting_time': maxWaitTime,
      'migration_nds_time': ndsTime,
      'migration_area_time': hour,
    };
  }

  @override
  String toString() {
    return 'MigrationData{areaNational: $areaNational, areaInternational: $areaInternational, migrationId: $migrationId, ndsArea: $ndsArea, timeNational: $timeNational, timeInternational: $timeInternational, maxWaitTime: $maxWaitTime, ndsTime: $ndsTime, hour: $hour}';
  }

  MigrationData copyWithField(String field, dynamic value) {
    final json = toJson();
    json[field] = value;
    return MigrationData.fromJson(json);
  }
}
