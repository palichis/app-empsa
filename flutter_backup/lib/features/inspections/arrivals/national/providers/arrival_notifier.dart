import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_details.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ArrivalNotifier extends StateNotifier<InspectionDetails?> {
  ArrivalNotifier() : super(null);

  void setArrival(InspectionDetails arrival) {
    state = arrival;
  }

  void updateField(String field, dynamic value) {
    if (state != null) {
      state = state!.copyWithField(field, value);
    }
  }

  void resetArrival() {
    state = null;
  }
}
