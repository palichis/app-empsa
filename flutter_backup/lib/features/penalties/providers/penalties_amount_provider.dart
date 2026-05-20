import 'package:flutter_riverpod/flutter_riverpod.dart';

class PenaltiesAmountNotifier extends StateNotifier<int> {
  PenaltiesAmountNotifier() : super(0);

  void updateAmount(int? parentId) {
    int amount = 0;
    if (parentId == 2) {
      amount = 50;
    } else if (parentId == 3) {
      amount = 100;
    } else if (parentId == 4) {
      amount = 200;
    }
    state = amount; // Actualiza el estado global
  }
}

// Provider global para acceder al monto
final penaltyAmountProvider =
    StateNotifierProvider<PenaltiesAmountNotifier, int>(
  (ref) => PenaltiesAmountNotifier(),
);
