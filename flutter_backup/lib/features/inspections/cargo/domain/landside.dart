import 'dart:convert';

import 'package:epmsa_mobile/features/inspections/cargo/domain/landside_entry.dart';
import 'package:flutter/material.dart';

class Landside {
  List<LandsideEntry> earthsideNationalQuality;
  List<LandsideEntry> earthsideNationalSecurity;
  List<LandsideEntry> earthsideNationalEnvironment;

  List<LandsideEntry> earthsideInternationalQuality;
  List<LandsideEntry> earthsideInternationalSecurity;
  List<LandsideEntry> earthsideInternationalEnvironment;

  List<LandsideEntry> earthsideInternationalBuildingQuality;
  List<LandsideEntry> earthsideInternationalBuildingSecurity;
  List<LandsideEntry> earthsideInternationalBuildingEnvironment;

  Landside({
    this.earthsideNationalQuality = const [],
    this.earthsideNationalSecurity = const [],
    this.earthsideNationalEnvironment = const [],
    this.earthsideInternationalQuality = const [],
    this.earthsideInternationalSecurity = const [],
    this.earthsideInternationalEnvironment = const [],
    this.earthsideInternationalBuildingQuality = const [],
    this.earthsideInternationalBuildingSecurity = const [],
    this.earthsideInternationalBuildingEnvironment = const [],
  });

  factory Landside.fromJson(Map<String, dynamic> json) => Landside(
        earthsideNationalQuality:
            LandsideEntry.fromJsonList(json['earthside_national_quality']),
        earthsideNationalSecurity:
            LandsideEntry.fromJsonList(json['earthside_national_security']),
        earthsideNationalEnvironment:
            LandsideEntry.fromJsonList(json['earthside_national_environment']),
        earthsideInternationalQuality:
            LandsideEntry.fromJsonList(json['earthside_international_quality']),
        earthsideInternationalSecurity: LandsideEntry.fromJsonList(
            json['earthside_international_security']),
        earthsideInternationalEnvironment: LandsideEntry.fromJsonList(
            json['earthside_international_environment']),
        earthsideInternationalBuildingQuality: LandsideEntry.fromJsonList(
            json['earthside_international_building_quality']),
        earthsideInternationalBuildingSecurity: LandsideEntry.fromJsonList(
            json['earthside_international_building_security']),
        earthsideInternationalBuildingEnvironment: LandsideEntry.fromJsonList(
            json['earthside_international_building_environment']),
      );

  Map<String, dynamic> toJson() => {
        'earthside_national_quality': jsonEncode(earthsideNationalQuality),
        'earthside_national_security': jsonEncode(earthsideNationalSecurity),
        'earthside_national_environment':
            jsonEncode(earthsideNationalEnvironment),
        'earthside_international_quality':
            jsonEncode(earthsideInternationalQuality),
        'earthside_international_security':
            jsonEncode(earthsideInternationalSecurity),
        'earthside_international_environment':
            jsonEncode(earthsideInternationalEnvironment),
        'earthside_international_building_quality':
            jsonEncode(earthsideInternationalBuildingQuality),
        'earthside_international_building_security':
            jsonEncode(earthsideInternationalBuildingSecurity),
        'earthside_international_building_environment':
            jsonEncode(earthsideInternationalBuildingEnvironment),
      };

  static List<LandsideEntry> apiJsonToEntries(Map<String, dynamic> block) {
    final out = <LandsideEntry>[];
    block.forEach((parent, list) {
      for (final item in list as List<dynamic>) {
        out.add(
          LandsideEntry.fromJson(item as Map<String, dynamic>)
              .copyWithField('parent', parent), // inyecta la clave
        );
      }
    });
    return out;
  }

  // landside.dart  (añade o sustituye el bloque actual)

  /// Todas las claves que el backend puede enviar
  static const _kGroups = [
    'earthside_national_quality',
    'earthside_national_security',
    'earthside_national_environment',
    'earthside_international_quality',
    'earthside_international_security',
    'earthside_international_environment',
    'earthside_international_building_quality',
    'earthside_international_building_security',
    'earthside_international_building_environment',
  ];

  /// Convierte la lista plana almacenada en SQLite al objeto agrupado
  factory Landside.fromEntries(List<LandsideEntry> rows) {
    final Map<String, List<Map<String, dynamic>>> block = {
      for (final k in _kGroups) k: [],
    };

    for (final e in rows) {
      block[e.parent]?.add(e.toJson());
    }
    return Landside.fromJson(block);
  }
}
