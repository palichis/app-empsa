import 'package:epmsa_mobile/core/presentation/cronometro_field.dart';
import 'package:flutter/material.dart';

class MigrationTimeControllers {
  final TextEditingController med1Controller;
  final TextEditingController med2Controller;
  final TextEditingController med3Controller;
  final TextEditingController avgController;
  final TextEditingController maxController;

  final FocusNode med1Focus = FocusNode();
  final FocusNode med2Focus = FocusNode();
  final FocusNode med3Focus = FocusNode();
  final FocusNode avgFocus = FocusNode();
  final FocusNode maxFocus = FocusNode();

  final GlobalKey<CronometroFieldState> maxTimeKey;
  final GlobalKey<CronometroFieldState> med1Key;
  final GlobalKey<CronometroFieldState> med2Key;
  final GlobalKey<CronometroFieldState> med3Key;

  MigrationTimeControllers({
    required this.med1Controller,
    required this.med2Controller,
    required this.med3Controller,
    required this.avgController,
    required this.maxController,
    GlobalKey<CronometroFieldState>? maxTimeKey,
    GlobalKey<CronometroFieldState>? med1Key,
    GlobalKey<CronometroFieldState>? med2Key,
    GlobalKey<CronometroFieldState>? med3Key,
  })  : maxTimeKey = med1Key ?? GlobalKey<CronometroFieldState>(),
        med1Key = med1Key ?? GlobalKey<CronometroFieldState>(),
        med2Key = med2Key ?? GlobalKey<CronometroFieldState>(),
        med3Key = med3Key ?? GlobalKey<CronometroFieldState>();

  List<GlobalKey<CronometroFieldState>> get allKeys =>
      [maxTimeKey, med1Key, med2Key, med3Key];

  void dispose() {
    med1Controller.dispose();
    med2Controller.dispose();
    med3Controller.dispose();
    avgController.dispose();
    maxController.dispose();

    med1Focus.dispose();
    med2Focus.dispose();
    med3Focus.dispose();
    avgFocus.dispose();
    maxFocus.dispose();
  }
}
