import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_details.dart';

abstract class ArrivalsRepository {
  Future<InspectionDetails?> getArrivalByInspection(int inspectionId);
  Future<void> saveArrival(InspectionDetails arrival);
}
