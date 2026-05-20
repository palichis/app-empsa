import 'package:duration_picker/duration_picker.dart';
import 'package:epmsa_mobile/core/presentation/cronometro_field.dart';
import 'package:epmsa_mobile/core/presentation/fields.dart';
import 'package:epmsa_mobile/core/providers/auto_save_provider.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/international/presentation/controllers/migration_time_controllers.dart';
import 'package:epmsa_mobile/features/inspections/header/providers/inspections_providers.dart';
import 'package:epmsa_mobile/features/inspections/shared/providers/arrivals_provider.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/migration_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MigrationTimeScreen extends StatefulWidget {
  final String title;
  final WidgetRef ref;
  final MigrationTimeControllers controllers;
  final Future<void> Function(BuildContext, TextEditingController) onTimeTap;
  final String scope;

  const MigrationTimeScreen({
    super.key,
    required this.title,
    required this.ref,
    required this.controllers,
    required this.onTimeTap,
    required this.scope,
  });

  @override
  MigrationTimeScreenState createState() => MigrationTimeScreenState();
}

class MigrationTimeScreenState extends State<MigrationTimeScreen> {
  void setData(MigrationTimeData time) {
    widget.controllers.med1Controller.text = time.paxAttentionMed1 ?? '';
    widget.controllers.med2Controller.text = time.paxAttentionMed2 ?? '';
    widget.controllers.med3Controller.text = time.paxAttentionMed3 ?? '';
    widget.controllers.avgController.text = time.average ?? '';
    widget.controllers.maxController.text = time.maxWaitingTime ?? '';
  }

  Duration _duration = Duration(hours: 0, minutes: 0);

  @override
  void initState() {
    super.initState();

    /*_setupAutoSaveField(
      'migration_maxWaitingTime',
      widget.controllers.maxController,
      widget.controllers.maxFocus,
    );*/
  }

  /*void _setupAutoSaveField(
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
  }*/

  /*Future<void> _saveField(String field, dynamic value) async {
    final inspection = widget.ref.read(inspectionDetailsProvider);

    if (inspection == null) return;

    final updated = inspection.copyWithField(field, value);
    final service = widget.ref.read(inspectionServiceSelectorProvider(updated));

    await service.save(updated);
    widget.ref
        .read(inspectionDetailsProvider.notifier)
        .setInspectionDetails(updated);

    debugPrint('💾 Guardando $field = $value');
  }*/

  @override
  Widget build(BuildContext context) {
    final details = widget.ref.watch(inspectionDetailsProvider);
    if (details == null) {
      return const Center(child: CircularProgressIndicator());
    }
    /*final belongs = details.inspectionId == widget.inspection.id;

    if (!belongs) {
      return const Center(child: CircularProgressIndicator());
    }*/
    final id = details.id;

    String k(String name) => id != null
        ? '$id:migration_time_${widget.scope}_$name'
        : 'migration_time_${widget.scope}_$name';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
            const Text('Tiempo atención por PAX',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            /*DurationPicker(
              duration: _duration,
              onChange: (val) {
                setState(() => _duration = val);
              },
            ),*/

            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: CronometroField(
                    key: widget.controllers.med1Key,
                    persistKey: k('attention_time_per_pax_1'),
                    label: 'Medición 1',
                    controller: widget.controllers.med1Controller,
                    helperText:
                        'Primera medición de tiempo de atención (mm:ss)'),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: CronometroField(
                    key: widget.controllers.med2Key,
                    persistKey: k('attention_time_per_pax_2'),
                    label: 'Medición 2',
                    controller: widget.controllers.med2Controller,
                    helperText:
                        'Segunda medición de tiempo de atención (mm:ss)'),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: CronometroField(
                    key: widget.controllers.med3Key,
                    persistKey: k('attention_time_per_pax_3'),
                    label: 'Medición 3',
                    controller: widget.controllers.med3Controller,
                    helperText:
                        'Tercera medición de tiempo de atención (mm:ss)'),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: buildLabelField(
                //label:
                'Promedio',
                //field: 'migration_average',
                //controller:
                widget.controllers.avgController,
                //focusNode: widget.controllers.avgFocus,
                //keyboardType: TextInputType.number,
                //setupAutoSaveField: _setupAutoSaveField),
              )),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: CronometroField(
                    key: widget.controllers.maxTimeKey,
                    persistKey: k('attention_time_per_pax_max'),
                    label: 'Tiempo máximo espera',
                    controller: widget.controllers.maxController,
                    helperText:
                        'Segunda medición de tiempo de atención (mm:ss)'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
