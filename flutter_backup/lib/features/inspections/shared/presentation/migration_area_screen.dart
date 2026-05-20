import 'package:epmsa_mobile/core/presentation/cronometro_field.dart';
import 'package:epmsa_mobile/core/presentation/fields.dart';
import 'package:epmsa_mobile/core/providers/auto_save_provider.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/international/presentation/controllers/migration_area_controllers.dart';
import 'package:epmsa_mobile/features/inspections/header/providers/inspections_providers.dart';
import 'package:epmsa_mobile/features/inspections/shared/providers/arrivals_provider.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/migration_area.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:http/http.dart' as ref;

class MigrationAreaScreen extends StatefulWidget {
  final String title;
  final WidgetRef ref;
  final MigrationAreaControllers controllers;
  final Future<void> Function(BuildContext, TextEditingController) onTimeTap;
  final String scope;

  const MigrationAreaScreen({
    super.key,
    required this.title,
    required this.ref,
    required this.controllers,
    required this.onTimeTap,
    required this.scope,
  });

  @override
  MigrationAreaScreenState createState() => MigrationAreaScreenState();
}

class MigrationAreaScreenState extends State<MigrationAreaScreen> {
  final _chronoKeys = <String, GlobalKey<CronometroFieldState>>{
    'offline_time': GlobalKey<CronometroFieldState>(),
  };
  /*final Map<String, String> _chronoFieldNames = const {
    'offline_time': 'migration_${widget.scope}_offline_time',
  };*/
  late Map<String, String> _chronoFieldNames;

  void setData(MigrationAreaData area) {
    widget.controllers.countersController.text = area.counters.toString();
    widget.controllers.paxAreaController.text = area.paxArea.toString();
    widget.controllers.occupancyController.text = area.occupancy.toString();
    widget.controllers.offlineTimeController.text = area.offlineTime.toString();
  }

  @override
  void initState() {
    super.initState();
    _chronoFieldNames = {
      'offline_time': 'migration_area_${widget.scope}_offline_time',
    };
    // Counters atendiendo
    _setupAutoSaveField(
      'migration_area_${widget.scope}_working_counters',
      widget.controllers.countersController,
      widget.controllers.countersFocus,
    );

    // PAX en área de espera
    _setupAutoSaveField(
      'migration_area_${widget.scope}_pax_waiting_area',
      widget.controllers.paxAreaController,
      widget.controllers.paxAreaFocus,
    );

    // % de ocupación (tal como lo usas en build)
    _setupAutoSaveField(
      'migration_area_${widget.scope}_waiting_area_occupancy',
      widget.controllers.occupancyController,
      widget.controllers.occupancyFocus,
    );

    _setupAutoSaveField(
      'migration_area_${widget.scope}_offline_time',
      widget.controllers.offlineTimeController,
      widget.controllers.offlineTimeFocus,
    );
  }

  Future<void> commitChronosMigrationArea({bool autosave = false}) async {
    for (final entry in _chronoKeys.entries) {
      final name = entry.key;
      final key = entry.value;

      key.currentState?.stopAndCommit();

      final controller = key.currentState?.widget.controller;
      if (controller != null &&
          (controller.text.isEmpty || controller.text.trim().isEmpty)) {
        controller.text = '00:00:00';
      }

      if (autosave) {
        final field = _chronoFieldNames[name];
        if (field != null) {
          final value = key.currentState?.widget.controller.text ?? '';
          await widget.ref
              .read(autoSaveServiceProvider)
              .saveField(field: field, value: value, onSave: _saveField);
        }
      }
    }
  }

  void _setupAutoSaveField(
    String field,
    TextEditingController controller,
    FocusNode focusNode,
  ) {
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        widget.ref.read(autoSaveServiceProvider).saveField(
              field: field,
              value: controller.text,
              onSave: _saveField,
            );
      }
    });
  }

  Future<void> _saveField(String field, dynamic value) async {
    final inspection = widget.ref.read(inspectionDetailsProvider);

    if (inspection == null) return;

    final updated = inspection.copyWithField(field, value);
    final service = widget.ref.read(inspectionServiceSelectorProvider(updated));

    await service.save(updated);
    widget.ref
        .read(inspectionDetailsProvider.notifier)
        .setInspectionDetails(updated);

    debugPrint('💾 Guardando $field = $value');
  }

  @override
  Widget build(BuildContext context) {
    final inspection = widget.ref.read(inspectionDetailsProvider);
    final id = inspection?.id;

    String k(String name) => id != null
        ? '$id:migration_area_${widget.scope}_$name'
        : 'migration_area_${widget.scope}_$name';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: buildEditableField(
                  label: 'Counters Atendiendo',
                  field: 'migration_area_${widget.scope}_working_counters',
                  controller: widget.controllers.countersController,
                  focusNode: widget.controllers.countersFocus,
                  keyboardType: TextInputType.number,
                  //setupAutoSaveField: _setupAutoSaveField
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: buildEditableField(
                  label: 'PAX Area Espera',
                  field: 'migration_area_${widget.scope}_pax_waiting_area',
                  controller: widget.controllers.paxAreaController,
                  focusNode: widget.controllers.paxAreaFocus,
                  keyboardType: TextInputType.number,
                  //setupAutoSaveField: _setupAutoSaveField
                ),
              )
            ]),
            Row(
              children: [
                Expanded(
                  child: buildEditableField(
                    label: '% de ocupación',
                    field:
                        'migration_area_${widget.scope}_waiting_area_occupancy',
                    controller: widget.controllers.occupancyController,
                    focusNode: widget.controllers.occupancyFocus,
                    keyboardType: TextInputType.number,
                    //setupAutoSaveField: _setupAutoSaveField
                  ),
                ),
                const SizedBox(width: 16),

                /*Expanded(
                  child: buildEditableField(
                    label: 'Offline Time',
                    field: 'migration_area_${widget.scope}_offline_time',
                    controller: widget.controllers.offlineTimeController,
                    focusNode: widget.controllers.offlineTimeFocus,
                    readOnly: true,
                    onTap: () => widget.onTimeTap(
                        context, widget.controllers.offlineTimeController),
                    //setupAutoSaveField: _setupAutoSaveField
                  ),
                )*/
              ],
            ),
            Row(children: [
              Expanded(
                child: CronometroField(
                    key: _chronoKeys['offline_time'],
                    persistKey: k('offline_time'),
                    label: 'Tiempo fuera de línea',
                    controller: widget.controllers.offlineTimeController,
                    hintText: 'hh:mm:ss'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
