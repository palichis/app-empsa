import 'package:flutter/material.dart';

class MigrationAreaControllers {
  final TextEditingController countersController;
  final TextEditingController paxAreaController;
  final TextEditingController occupancyController;
  final TextEditingController offlineTimeController;

  final FocusNode countersFocus = FocusNode();
  final FocusNode paxAreaFocus = FocusNode();
  final FocusNode occupancyFocus = FocusNode();
  final FocusNode offlineTimeFocus = FocusNode();

  MigrationAreaControllers({
    required this.countersController,
    required this.paxAreaController,
    required this.occupancyController,
    required this.offlineTimeController,
  });

  void dispose() {
    countersController.dispose();
    paxAreaController.dispose();
    occupancyController.dispose();
    offlineTimeController.dispose();

    countersFocus.dispose();
    paxAreaFocus.dispose();
    occupancyFocus.dispose();
    offlineTimeFocus.dispose();
  }
}
