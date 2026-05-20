import 'dart:async';
import 'dart:io';

import 'package:epmsa_mobile/core/presentation/cronometro_field.dart';
import 'package:epmsa_mobile/core/presentation/fields.dart';
import 'package:epmsa_mobile/core/providers/auto_save_provider.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/international/domain/international_arrivals.dart';
import 'package:epmsa_mobile/features/inspections/header/domain/Inspection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:epmsa_mobile/core/helpers/photo_helpers.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_photo.dart';
import 'package:epmsa_mobile/features/inspections/header/providers/inspections_providers.dart';

import 'package:epmsa_mobile/features/inspections/arrivals/international/presentation/controllers/migration_area_controllers.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/international/presentation/controllers/migration_time_controllers.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/migration.dart';

import 'migration_area_screen.dart';
import 'migration_time_screen.dart';

class MigrationScreen extends ConsumerStatefulWidget {
  final Inspection inspection;
  const MigrationScreen({super.key, required this.inspection});

  @override
  ConsumerState<MigrationScreen> createState() => MigrationScreenState();
}

class MigrationScreenState extends ConsumerState<MigrationScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> migrationOptions = [
    {"id": 60, "name": "Migración (Con apoyo salas Bravo)", "selected": false},
    {"id": 33, "name": "Migración (Sin apoyo salas Bravo)", "selected": false},
  ];
  int? _selectedMigrationId;

  final TextEditingController hourController = TextEditingController();

  final hourFocus = FocusNode();

  // -------------------- Controllers de Área y Tiempo ------------------------
  late MigrationAreaControllers areaControllersNational;
  late MigrationAreaControllers areaControllersInternational;
  late MigrationTimeControllers timeControllersNational;
  late MigrationTimeControllers timeControllersInternational;

  // -------------------- Keys para sub‑pantallas ----------------------------
  final GlobalKey<MigrationAreaScreenState> migrationInternationalAreaKey =
      GlobalKey();
  final GlobalKey<MigrationAreaScreenState> migrationNationalAreaKey =
      GlobalKey();
  final GlobalKey<MigrationTimeScreenState> migrationInternationalTimeKey =
      GlobalKey();
  final GlobalKey<MigrationTimeScreenState> migrationNationalTimeKey =
      GlobalKey();

  // -------------------- Estado de Fotos ------------------------------------
  List<File> _images = [];
  bool _photosLoaded = false;

  // -------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();

    areaControllersNational = MigrationAreaControllers(
      countersController: TextEditingController(),
      paxAreaController: TextEditingController(),
      occupancyController: TextEditingController(),
      offlineTimeController: TextEditingController(),
    );

    areaControllersInternational = MigrationAreaControllers(
      countersController: TextEditingController(),
      paxAreaController: TextEditingController(),
      occupancyController: TextEditingController(),
      offlineTimeController: TextEditingController(),
    );

    timeControllersNational = MigrationTimeControllers(
      med1Controller: TextEditingController(),
      med2Controller: TextEditingController(),
      med3Controller: TextEditingController(),
      avgController: TextEditingController(),
      maxController: TextEditingController(),
    );

    timeControllersInternational = MigrationTimeControllers(
      med1Controller: TextEditingController(),
      med2Controller: TextEditingController(),
      med3Controller: TextEditingController(),
      avgController: TextEditingController(),
      maxController: TextEditingController(),
    );

    _setupAutoSaveField(
      'migration_area_time',
      hourController,
      hourFocus,
    );
  }

  Future<void> _selectTimeNested(
      BuildContext context, TextEditingController controller) async {
    TimeOfDay initialTime;
    if (controller.text.isNotEmpty) {
      try {
        final parts = controller.text.split(':');
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        initialTime = TimeOfDay(hour: hour, minute: minute);
      } catch (_) {
        initialTime = TimeOfDay.now();
      }
    } else {
      initialTime = TimeOfDay.now();
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      controller.text = picked.format(context);
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    TimeOfDay initialTime;
    if (controller.text.isNotEmpty) {
      try {
        final parts = controller.text.split(':');
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        initialTime = TimeOfDay(hour: hour, minute: minute);
      } catch (_) {
        initialTime = TimeOfDay.now();
      }
    } else {
      initialTime = TimeOfDay.now();
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      controller.text = picked.format(context);
    }
  }

  void setData(MigrationData migration) {
    migrationNationalAreaKey.currentState?.setData(migration.areaNational);
    migrationInternationalAreaKey.currentState
        ?.setData(migration.areaInternational);
    migrationNationalTimeKey.currentState?.setData(migration.timeNational);
    migrationInternationalTimeKey.currentState
        ?.setData(migration.timeInternational);
    hourController.text = migration.hour ?? '';
    if (migration.migrationId != null) {
      print("migartion_id value: ${migration.migrationId}");
      setState(() {
        _selectedMigrationId = migration.migrationId; // <<-- aquí
      });
    }
  }

  String mtKey(String type, String scope, String part) {
    final inspection = ref.read(inspectionDetailsProvider);
    final id = inspection?.id;
    return id != null
        ? '$id:migration_${type}_${scope}_$part'
        : 'migration_${type}_${scope}_$part';
  }

  void _commitChronos() {
    void commitTimeBundle(String scope, MigrationTimeControllers c) {
      final pairs = <String, TextEditingController>{
        'attention_time_per_pax_1': c.med1Controller,
        'attention_time_per_pax_2': c.med2Controller,
        'attention_time_per_pax_3': c.med3Controller,
      };
      for (final e in pairs.entries) {
        CronometroFieldState.stopAndCommitGlobal(
          persistKey: mtKey('time', scope, e.key),
          controller: e.value,
        );
      }
    }

    void commitAreaBundle(String scope, MigrationAreaControllers c) {
      final pairs = <String, TextEditingController>{
        'offline_time': c.offlineTimeController,
      };
      for (final e in pairs.entries) {
        CronometroFieldState.stopAndCommitGlobal(
          persistKey: mtKey('area', scope, e.key),
          controller: e.value,
        );
      }
    }

    commitTimeBundle('national', timeControllersNational);
    commitTimeBundle('international', timeControllersInternational);
    commitAreaBundle('national', areaControllersNational);
    commitAreaBundle('international', areaControllersInternational);
  }

  Map<String, dynamic> getData() {
    _commitChronos();
    //migrationInternationalAreaKey.currentState?.commitChronosMigrationArea();
    //migrationNationalAreaKey.currentState?.commitChronosMigrationArea();
    return {
      "migration_id": _selectedMigrationId,
      'migration_area_time': hourController.text,
      // ---------------------- ÁREA – Nacional ------------------------------
      'migration_area_national_working_counters':
          areaControllersNational.countersController.text,
      'migration_area_national_pax_waiting_area':
          areaControllersNational.paxAreaController.text,
      'migration_area_national_occupancy':
          areaControllersNational.occupancyController.text,
      'migration_area_national_offline_time':
          areaControllersNational.offlineTimeController.text,

      // ---------------------- ÁREA – Internacional -------------------------
      'migration_area_international_working_counters':
          areaControllersInternational.countersController.text,
      'migration_area_international_pax_waiting_area':
          areaControllersInternational.paxAreaController.text,
      'migration_area_international_occupancy':
          areaControllersInternational.occupancyController.text,
      'migration_area_international_offline_time':
          areaControllersInternational.offlineTimeController.text,

      // ---------------------- TIEMPO – Nacional ----------------------------
      //'migration_time_national_attention_time_per_pax_1':
      'migration_time_national_attention_time_per_pax_1':
          timeControllersNational.med1Controller.text,
      'migration_time_national_attention_time_per_pax_2':
          timeControllersNational.med2Controller.text,
      'migration_time_national_attention_time_per_pax_3':
          timeControllersNational.med3Controller.text,
      'migration_time_national_avg': timeControllersNational.avgController.text,
      'migration_time_national_attention_time_per_pax_max':
          timeControllersNational.maxController.text,

      // ---------------------- TIEMPO – Internacional -----------------------
      'migration_time_international_pax_waiting_time_1':
          timeControllersInternational.med1Controller.text,
      'migration_time_international_pax_waiting_time_2':
          timeControllersInternational.med2Controller.text,
      'migration_time_international_pax_waiting_time_3':
          timeControllersInternational.med3Controller.text,
      'migration_time_international_avg':
          timeControllersInternational.avgController.text,
      'migration_time_international_attention_time_per_pax_max':
          timeControllersInternational.maxController.text,
    };
  }

  Future<void> _handlePhoto({required String section}) async {
    final path = await PhotoHelper.takeAndSavePhoto(context: context);
    if (path == null) return;

    final inspection = ref.read(inspectionProvider);
    if (inspection == null || inspection.id == null) return;

    setState(() {
      _images.add(File(path));
    });

    final photo = InspectionPhoto(
      inspectionId: inspection.id!,
      path: path,
      timestamp: DateTime.now(),
      section: section,
    );
    await ref.read(photoServiceProvider).savePhoto(photo);
  }

  Future<void> _loadExistingPhotos(int inspectionId, String section) async {
    final photosList = await ref
        .read(photoServiceProvider)
        .getPhotosBySection(inspectionId, section);

    if (mounted)
      setState(() {
        _images = photosList.map((p) => File(p.path)).toList();
      });
  }

  Widget _photoWidget({
    required String label,
    required List<File> images,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.camera_alt),
          label: Text(label),
        ),
        if (images.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: images.map((img) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  img,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _setupAutoSaveField(
    String field,
    TextEditingController controller,
    FocusNode focusNode,
  ) {
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        ref.read(autoSaveServiceProvider).saveField(
              field: field,
              value: controller.text,
              onSave: _saveField,
            );
      }
    });
  }

  Future<void> _saveField(String field, dynamic value) async {
    final inspectionDetail = ref.read(inspectionDetailsProvider);

    if (inspectionDetail == null) return;

    print("AUTOSAVE MIGRATIION INSPECTION DETAIL ID : ${inspectionDetail.id}");

    final updated = inspectionDetail.copyWithField(field, value);
    final service = ref.read(inspectionServiceSelectorProvider(updated));

    print("UPDATED -------------------------------- ");
    debugPrint("${updated.toJson()}");
    await service.save(updated);
    ref.read(inspectionDetailsProvider.notifier).setInspectionDetails(updated);

    debugPrint('💾 Guardando $field = $value');
  }

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(inspectionDetailsProvider);
    if (details == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final belongs = details.inspectionId == widget.inspection.id;

    if (!belongs) {
      return const Center(child: CircularProgressIndicator());
    }

    /*en arribo internacional immigration
    para salida internacional emigration */

    String section = 'emigration';

    if (details is InternationalArrival) {
      section = 'immigration';
    }

    // Carga diferida de fotos
    if (details.id != null && !_photosLoaded) {
      _photosLoaded = true;
      Future.microtask(
          () => _loadExistingPhotos(widget.inspection.id!, section));
    }
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Migración',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  if (details is InternationalArrival) ...[
                    const SizedBox(height: 16),
                    Column(
                      children: migrationOptions.map((opt) {
                        final id = opt['id'] as int;
                        final isChecked = _selectedMigrationId == id;
                        return CheckboxListTile(
                          key: ValueKey(id),
                          title: Text(opt['name'].toString()),
                          value: isChecked,
                          onChanged: (bool? value) {
                            setState(() {
                              _selectedMigrationId =
                                  (value ?? false) ? id : null;
                            });
                            ref.read(autoSaveServiceProvider).saveField(
                                  field: 'migration_id',
                                  value: _selectedMigrationId,
                                  onSave: _saveField,
                                );
                          },
                        );
                      }).toList(),
                    )
                  ],

                  const SizedBox(height: 16),

                  // ---------------------- ÁREA -----------------------------
                  buildEditableField(
                    label: 'Hora',
                    field: 'migration_area_time',
                    controller: hourController,
                    focusNode: hourFocus,
                    readOnly: true,
                    onTap: () => _selectTime(hourController),
                    suffixIcon: const Icon(Icons.access_time),
                    //setupAutoSaveField: _setupAutoSaveField
                  ),
                  const Text('Área',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  MigrationAreaScreen(
                    key: migrationNationalAreaKey,
                    title: 'NACIONAL & COMUNIDAD ANDINA',
                    controllers: areaControllersNational,
                    onTimeTap: _selectTimeNested,
                    ref: ref,
                    scope: 'national',
                  ),
                  const SizedBox(height: 16),
                  MigrationAreaScreen(
                    key: migrationInternationalAreaKey,
                    title: 'INTERNACIONAL',
                    controllers: areaControllersInternational,
                    onTimeTap: _selectTimeNested,
                    ref: ref,
                    scope: 'international',
                  ),
                  // ---------------------- TIEMPO ---------------------------
                  const SizedBox(height: 16),
                  const Text('Tiempo',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  MigrationTimeScreen(
                    key: migrationNationalTimeKey,
                    title: 'NACIONAL & COMUNIDAD ANDINA',
                    controllers: timeControllersNational,
                    onTimeTap: _selectTimeNested,
                    ref: ref,
                    scope: 'national',
                  ),
                  const SizedBox(height: 16),
                  MigrationTimeScreen(
                    key: migrationInternationalTimeKey,
                    title: 'INTERNACIONAL',
                    controllers: timeControllersInternational,
                    onTimeTap: _selectTimeNested,
                    ref: ref,
                    scope: 'international',
                  ),

                  const SizedBox(height: 8),
                  _photoWidget(
                    label: 'Foto migración',
                    images: _images,
                    onTap: () => _handlePhoto(section: section),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
