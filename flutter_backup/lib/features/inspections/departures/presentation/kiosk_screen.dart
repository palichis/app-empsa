import 'dart:io';

import 'package:epmsa_mobile/core/helpers/photo_helpers.dart';
import 'package:epmsa_mobile/core/presentation/cronometro_field.dart';
import 'package:epmsa_mobile/core/presentation/fields.dart';
import 'package:epmsa_mobile/core/providers/auto_save_provider.dart';
import 'package:epmsa_mobile/features/inspections/header/domain/Inspection.dart';
import 'package:epmsa_mobile/features/inspections/header/providers/inspections_providers.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/self_checkin_kiosks_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelfCheckinKiosksScreen extends ConsumerStatefulWidget {
  final Inspection inspection;
  const SelfCheckinKiosksScreen({super.key, required this.inspection});

  @override
  ConsumerState<SelfCheckinKiosksScreen> createState() =>
      SelfCheckinKiosksScreenState();
}

class SelfCheckinKiosksScreenState
    extends ConsumerState<SelfCheckinKiosksScreen> {
  final _formKey = GlobalKey<FormState>();

  final _chronoKeys = <String, GlobalKey<CronometroFieldState>>{
    'maxTime': GlobalKey<CronometroFieldState>(),
    'med1': GlobalKey<CronometroFieldState>(),
    'med2': GlobalKey<CronometroFieldState>(),
  };

  final Map<String, String> _chronoFieldNames = const {
    'maxTime': 'self_checkin_kiosks_maximum_waiting_time',
    'med1': 'self_checkin_kiosks_service_time_per_pax_1',
    'med2': 'self_checkin_kiosks_service_time_per_pax_2',
  };

  // Controllers
  final _timeController = TextEditingController();
  final _pax1Controller = TextEditingController();
  final _pax2Controller = TextEditingController();
  final _averageController = TextEditingController();
  final _maxWaitController = TextEditingController();
  final _ndsFunctionController = TextEditingController();

  // FocusNodes
  final _timeFocus = FocusNode();
  final _pax1Focus = FocusNode();
  final _pax2Focus = FocusNode();
  final _averageFocus = FocusNode();
  final _maxWaitFocus = FocusNode();
  final _ndsFunctionFocus = FocusNode();

  List<File> _images = [];
  bool _photoLoaded = false;

  @override
  void initState() {
    super.initState();

    // Guarda al perder foco (hora)
    _setupAutoSaveField(
      'self_checkin_kiosks_time',
      _timeController,
      _timeFocus,
    );

    // Guarda al perder foco (NdS función del tiempo)
    _setupAutoSaveField(
      'self_checkin_kiosks_nds_time_function',
      _ndsFunctionController,
      _ndsFunctionFocus,
    );
  }

  void _setupAutoSaveField(String field, TextEditingController c, FocusNode f) {
    f.addListener(() {
      if (!f.hasFocus) {
        ref
            .read(autoSaveServiceProvider)
            .saveField(field: field, value: c.text, onSave: _saveField);
      }
    });
  }

  Future<void> _saveField(String field, dynamic value) async {
    final inspection = ref.read(inspectionDetailsProvider);
    if (inspection == null) return;
    final updated = inspection.copyWithField(field, value);
    await ref.read(inspectionServiceSelectorProvider(updated)).save(updated);
    ref.read(inspectionDetailsProvider.notifier).setInspectionDetails(updated);
  }

  Future<void> _selectTime(
      TextEditingController controller, String field) async {
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
      ref
          .read(autoSaveServiceProvider)
          .saveField(field: field, value: controller.text, onSave: _saveField);
    }
  }

  Future<void> _handlePhoto() async {
    final path = await PhotoHelper.takeAndSavePhoto(context: context);
    if (path == null) return;

    /*final inspection = ref.read(inspectionProvider);
    if (inspection == null || inspection.id == null) return;*/

    setState(() => _images.add(File(path)));

    final photo = InspectionPhoto(
      inspectionId: widget.inspection.id!,
      path: path,
      timestamp: DateTime.now(),
      section: 'self-check-in',
    );
    await ref.read(photoServiceProvider).savePhoto(photo);
  }

  Future<void> _loadExistingPhoto(int id) async {
    final photos = await ref
        .read(photoServiceProvider)
        .getPhotosBySection(id, 'self-check-in');
    if (photos.isNotEmpty)
      setState(() => _images = photos.map((p) => File(p.path)).toList());
  }

  Widget _photoWidget() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: _handlePhoto,
            //icon: _iconFor(_imageCheckin),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Foto – Quioscos'),
          ),
          if (_images.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _images.map((img) {
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

  void setData(SelfCheckinKiosksData data) {
    print("getting self checkin data: ${data.toJson()}");
    _timeController.text = data.selfCheckinKiosksTime ?? '';
    _pax1Controller.text = data.selfCheckinKiosksServiceTimePerPax1 ?? '';
    _pax2Controller.text = data.selfCheckinKiosksServiceTimePerPax2 ?? '';
    _averageController.text = data.selfCheckinKiosksAverage ?? '';
    _maxWaitController.text = data.selfCheckinKiosksMaximumWaitingTime ?? '';
    _ndsFunctionController.text = data.selfCheckinKiosksNdsTimeFunction ?? '';
  }

  Future<void> _commitChronosKiosk({bool autosave = false}) async {
    // 1) Construye persistKey igual que en build()
    String _persistKeyFromField(String field) {
      final inspection = ref.read(inspectionDetailsProvider);
      final id = inspection?.id;
      // field viene como 'self_checkin_kiosks_service_time_per_pax_1'
      const prefix = 'self_checkin_kiosks_';
      final part =
          field.startsWith(prefix) ? field.substring(prefix.length) : field;
      return id != null
          ? '$id:self_checkin_kiosks_$part'
          : 'self_checkin_kiosks_$part';
    }

    TextEditingController? _ctrlFor(String alias) {
      switch (alias) {
        case 'maxTime':
          return _maxWaitController;
        case 'med1':
          return _pax1Controller;
        case 'med2':
          return _pax2Controller;
        default:
          return null;
      }
    }

    for (final entry in _chronoKeys.entries) {
      final alias = entry.key;
      final gkey = entry.value;

      if (gkey.currentState != null) {
        gkey.currentState!.stopAndCommit();
      } else {
        final field = _chronoFieldNames[alias];
        final ctrl = _ctrlFor(alias);
        if (field != null && ctrl != null) {
          CronometroFieldState.stopAndCommitGlobal(
            persistKey: _persistKeyFromField(field),
            controller: ctrl,
          );
        }
      }

      final ctrl = gkey.currentState?.widget.controller ?? _ctrlFor(alias);
      if (ctrl != null && ctrl.text.trim().isEmpty) {
        ctrl.text = '00:00';
      }

      if (autosave) {
        final field = _chronoFieldNames[alias];
        if (field != null) {
          await ref.read(autoSaveServiceProvider).saveField(
              field: field, value: ctrl?.text ?? '00:00', onSave: _saveField);
        }
      }
    }
  }

  Map<String, dynamic> getData() {
    _commitChronosKiosk();
    debugPrint(
        '[KIOSK getData] med1="${_pax1Controller.text}" med2="${_pax2Controller.text}"');

    return {
      'self_checkin_kiosks_time': _timeController.text,
      'self_checkin_kiosks_service_time_per_pax_1': _pax1Controller.text,
      'self_checkin_kiosks_service_time_per_pax_2': _pax2Controller.text,
      'self_checkin_kiosks_average': _averageController.text,
      'self_checkin_kiosks_maximum_waiting_time': _maxWaitController.text,
      'self_checkin_kiosks_nds_time_function': _ndsFunctionController.text,
    };
  }

  bool validate() => _formKey.currentState?.validate() ?? false;

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
    if (details.id != null && !_photoLoaded) {
      _photoLoaded = true;
      Future.microtask(() => _loadExistingPhoto(widget.inspection.id!));
    }
    final id = details.id;

    String k(String name) => id != null
        ? '$id:self_checkin_kiosks_$name'
        : 'self_checkin_kiosks_$name';
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
                  const Text('Quioscos de Auto‑Check‑in',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  buildEditableField(
                    label: 'Hora',
                    field: 'self_checkin_kiosks_time',
                    controller: _timeController,
                    focusNode: _timeFocus,
                    onTap: () => _selectTime(
                        _timeController, 'self_checkin_kiosks_time'),
                    suffixIcon: const Icon(Icons.access_time),
                    //setupAutoSaveField: _setupAutoSaveField
                  ),
                  Row(children: [
                    Expanded(
                      child: CronometroField(
                        key: _chronoKeys['med1'],
                        persistKey: k('service_time_per_pax_1'),
                        label: 'Med. 1',
                        controller: _pax1Controller,
                        helperText: 'Tiempo de atención por pasajero',
                      ),
                    ),
                  ]),
                  Row(children: [
                    Expanded(
                      child: CronometroField(
                        /*key: const ValueKey(
                        'self_checkin_kiosks_service_time_per_pax_2'),*/
                        key: _chronoKeys['med2'],
                        persistKey: k('service_time_per_pax_2'),
                        label: 'Med. 2',
                        controller: _pax2Controller,
                        helperText: 'Tiempo de atención por pasajero',
                      ),
                    ),
                  ]),
                  /*Row(children: [
                    Expanded(
                      child: buildLabelField(
                        //label:
                        'Promedio',
                        _averageController,
                      ),
                    ),
                  ]),*/
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: CronometroField(
                        key: _chronoKeys['maxTime'],
                        persistKey: k('maximum_waiting_time'),
                        label: 'Tiempo máximo de espera',
                        controller: _maxWaitController,
                        //helperText: 'Tiempo de atención por pasajero',
                      ),
                    ),
                  ]),
                  // ---------- Botón y miniatura de foto ----------
                  const SizedBox(height: 8),
                  _photoWidget(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timeController.dispose();
    _pax1Controller.dispose();
    _pax2Controller.dispose();
    _averageController.dispose();
    _maxWaitController.dispose();
    _ndsFunctionController.dispose();

    _timeFocus.dispose();
    _pax1Focus.dispose();
    _pax2Focus.dispose();
    _averageFocus.dispose();
    _maxWaitFocus.dispose();
    _ndsFunctionFocus.dispose();
    super.dispose();
  }
}
