import 'package:epmsa_mobile/features/inspections/shared/domain/general_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/observations_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/public_hall_data.dart';

abstract class InspectionDetails {
  int? get id;
  int get inspectionId;
  int get synced;

  GeneralData get general;
  PublicHallData get publicHall;
  ObservationsData get observations;

  Map<String, dynamic> toJson();
  InspectionDetails copyWithField(String field, dynamic value);
}
