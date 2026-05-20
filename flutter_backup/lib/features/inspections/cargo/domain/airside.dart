import 'package:epmsa_mobile/features/inspections/cargo/domain/airside_entry.dart';

class Airside {
  final List<AirsideEntry> quality;
  final List<AirsideEntry> security;
  final List<AirsideEntry> environment;

  Airside({
    required this.quality,
    required this.security,
    required this.environment,
  });

  factory Airside.fromJson(Map<String, dynamic> json) {
    return Airside(
      quality: AirsideEntry.fromJsonList(
        (json['airside_national_international_quality'] ?? []) as List,
      ),
      security: AirsideEntry.fromJsonList(
        (json['airside_national_international_security'] ?? []) as List,
      ),
      environment: AirsideEntry.fromJsonList(
        (json['airside_national_international_environment'] ?? []) as List,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'airside_national_international_quality':
          quality.map((e) => e.toJson()).toList(),
      'airside_national_international_security':
          security.map((e) => e.toJson()).toList(),
      'airside_national_international_environment':
          environment.map((e) => e.toJson()).toList(),
    };
  }

  factory Airside.fromEntries(List<AirsideEntry> rows) {
    final Map<String, List<Map<String, dynamic>>> block = {
      for (final k in AirsideEntry.airSideDetailKeys) k: [],
    };
    for (final e in rows) {
      if (AirsideEntry.airSideDetailKeys.contains(e.parent)) {
        block[e.parent]!.add(e.toJson());
      }
    }
    return Airside.fromJson(block);
  }
}
