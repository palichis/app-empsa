// Archivo: migration_time.dart

class MigrationTimeData {
  final String? paxAttentionMed1;
  final String? paxAttentionMed2;
  final String? paxAttentionMed3;
  final String? average;
  final String? maxWaitingTime;
  final String? scope;

  MigrationTimeData({
    this.paxAttentionMed1,
    this.paxAttentionMed2,
    this.paxAttentionMed3,
    this.average,
    this.maxWaitingTime,
    this.scope,
  });

  static String _normalizeScope(scope) {
    final s = (scope ?? '').toString().toLowerCase();
    if (s == 'n') return 'national';
    if (s == 'i') return 'international';
    return s; // 'national' o 'international' esperado
  }

  factory MigrationTimeData.fromJson(Map<String, dynamic> json, scope) {
    final sc = _normalizeScope(scope);
    final isNational = sc == 'national';
    final base1 =
        isNational ? 'attention_time_per_pax_1' : 'pax_waiting_time_1';
    final base2 =
        isNational ? 'attention_time_per_pax_2' : 'pax_waiting_time_2';
    final base3 =
        isNational ? 'attention_time_per_pax_3' : 'pax_waiting_time_3';
    final baseMax =
        isNational ? 'attention_time_per_pax_max' : 'pax_waiting_time_max';

    String _read(String tail) =>
        (json['migration_time_${sc}_$tail'] ?? '').toString();

    return MigrationTimeData(
      paxAttentionMed1: _read(base1),
      paxAttentionMed2: _read(base2),
      paxAttentionMed3: _read(base3),
      average: _read('average'), // si no existe en tu JSON quedará como ''
      maxWaitingTime: _read(baseMax),
      scope: sc,
    );
  }

  Map<String, dynamic> toJson() {
    final sc = _normalizeScope(scope);
    final isNational = sc == 'national';

    if (isNational) {
      return {
        'migration_time_${sc}_attention_time_per_pax_1': paxAttentionMed1,
        'migration_time_${sc}_attention_time_per_pax_2': paxAttentionMed2,
        'migration_time_${sc}_attention_time_per_pax_3': paxAttentionMed3,
        'migration_time_${sc}_average': average,
        'migration_time_${sc}_attention_time_per_pax_max': maxWaitingTime,
      };
    } else {
      // international
      return {
        'migration_time_${sc}_pax_waiting_time_1': paxAttentionMed1,
        'migration_time_${sc}_pax_waiting_time_2': paxAttentionMed2,
        'migration_time_${sc}_pax_waiting_time_3': paxAttentionMed3,
        'migration_time_${sc}_average': average,
        'migration_time_${sc}_pax_waiting_time_max': maxWaitingTime,
      };
    }
  }

  MigrationTimeData copyWithField(String field, dynamic value) {
    final json = toJson();
    json[field] = value;
    return MigrationTimeData.fromJson(json, scope);
  }
}
