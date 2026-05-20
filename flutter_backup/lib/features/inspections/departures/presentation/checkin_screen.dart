import 'dart:io';

import 'package:epmsa_mobile/core/presentation/cronometro_field.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/checkin_assigned_counters.dart';
import 'package:epmsa_mobile/features/inspections/departures/national/domain/national_departures.dart';
import 'package:epmsa_mobile/features/inspections/departures/providers/depatures_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:epmsa_mobile/core/presentation/fields.dart';
import 'package:epmsa_mobile/core/providers/auto_save_provider.dart';
import 'package:epmsa_mobile/core/helpers/photo_helpers.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_photo.dart';
import 'package:epmsa_mobile/features/inspections/header/domain/Inspection.dart';
import 'package:epmsa_mobile/features/inspections/header/providers/inspections_providers.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/checkin_counter_area_data.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/checkin_counter_time_data.dart';

class CheckinScreen extends ConsumerStatefulWidget {
  final Inspection inspection;
  const CheckinScreen({Key? key, required this.inspection}) : super(key: key);

  @override
  ConsumerState<CheckinScreen> createState() => CheckinScreenState();
}

class CheckinScreenState extends ConsumerState<CheckinScreen> {
  final _formKey = GlobalKey<FormState>();
  List<bool> _counterSelections = [];
  List<CheckinAssignedCounter> _counterNumbers = [];

  final _chronoKeys = <String, GlobalKey<CronometroFieldState>>{
    'offline_time': GlobalKey<CronometroFieldState>(),
    'maxTime': GlobalKey<CronometroFieldState>(),
    'med1': GlobalKey<CronometroFieldState>(),
    'med2': GlobalKey<CronometroFieldState>(),
    'med3': GlobalKey<CronometroFieldState>(),
    'med4': GlobalKey<CronometroFieldState>(),
    'med5': GlobalKey<CronometroFieldState>(),
  };

  final Map<String, String> _chronoFieldNames = const {
    'offline_time': 'checkin_counter_offline_time',
    'maxTime': 'checkin_counter_attention_time_per_pax_max',
    'med1': 'checkin_counter_attention_time_per_pax_1',
    'med2': 'checkin_counter_attention_time_per_pax_2',
    'med3': 'checkin_counter_attention_time_per_pax_3',
    'med4': 'checkin_counter_attention_time_per_pax_4',
    'med5': 'checkin_counter_attention_time_per_pax_5',
  };

  // ---------------------------------------------------------------------------
  // Controllers
  final _timeController = TextEditingController();
  final _zoneController = TextEditingController();
  final _assignedCountersController = TextEditingController();
  final _operatingCountersController = TextEditingController();
  final _paxWaitingAreaController = TextEditingController();
  final _offlineTimeController = TextEditingController();
  final _pax1Controller = TextEditingController();
  final _pax2Controller = TextEditingController();
  final _pax3Controller = TextEditingController();
  final _pax4Controller = TextEditingController();
  final _pax5Controller = TextEditingController();
  final _paxMaxController = TextEditingController();

  final _timeFocus = FocusNode();
  final _zoneFocus = FocusNode();
  final _assignedCountersFocus = FocusNode();
  final _operatingCountersFocus = FocusNode();
  final _paxWaitingAreaFocus = FocusNode();
  final _offlineTimeFocus = FocusNode();
  final _pax1Focus = FocusNode();
  final _pax2Focus = FocusNode();
  final _pax3Focus = FocusNode();
  final _pax4Focus = FocusNode();
  final _pax5Focus = FocusNode();
  final _paxMaxFocus = FocusNode();

  List<File> _images = [];
  bool _photoLoaded = false;

  @override
  void initState() {
    super.initState();

    // Área
    _setupAutoSaveField(
      'checkin_counter_time',
      _timeController,
      _timeFocus,
    );
    _setupAutoSaveField(
      'checkin_counter_assigned_counters_zone',
      _zoneController,
      _zoneFocus,
    );
    _setupAutoSaveField(
      'checkin_counter_assigned_counters',
      _assignedCountersController,
      _assignedCountersFocus,
    );
    _setupAutoSaveField(
      'checkin_counter_operating_counters',
      _operatingCountersController,
      _operatingCountersFocus,
    );
    _setupAutoSaveField(
      'checkin_counter_pax_waiting_area',
      _paxWaitingAreaController,
      _paxWaitingAreaFocus,
    );
    // Cronómetros: offline_time y med1..med5 -> se guardan con _commitChronosCheckin(autosave: true)
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

    // 2) Mostrar el selector
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    // 3) Asignar el valor al controller
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
      section: 'check-in',
    );
    await ref.read(photoServiceProvider).savePhoto(photo);
  }

  Future<void> _loadExistingPhoto(int id) async {
    final photos =
        await ref.read(photoServiceProvider).getPhotosBySection(id, 'check-in');
    if (photos.isNotEmpty)
      setState(() => _images = photos.map((p) => File(p.path)).toList());
  }

  void _loadListsFromSQLite(int departureId, bool isNational) async {
    final svr = ref.read(checkinCounterRepositoryProvider);

    final cnts = await svr.getCounterNumberDetails(
      departureId: departureId,
      isNational: isNational,
    );

    if (!mounted) return;
    setState(() {
      _counterNumbers = cnts;
      _counterSelections = _counterNumbers.map((c) => c.selected == 1).toList();
    });
  }

  Widget _photoWidget() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: _handlePhoto,
            //icon: _iconFor(_imageCheckin),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Foto – Check-in'),
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

  void setData(CheckinCounterAreaData a, CheckinCounterTimeData t) {
    _timeController.text = a.checkinCounterTime ?? '';
    _zoneController.text = a.checkinCounterAssignedCountersZone ?? '';
    _assignedCountersController.text =
        a.checkinCounterAssignedCounters.toString(); // ?? '';
    _operatingCountersController.text =
        a.checkinCounterOperatingCounters.toString(); // ?? '';
    _paxWaitingAreaController.text =
        a.checkinCounterPaxWaitingArea.toString(); // ?? '';
    _offlineTimeController.text = a.checkinCounterOfflineTime ?? '';

    _pax1Controller.text = t.checkinCounterAttentionTimePerPax1 ?? '';
    _pax2Controller.text = t.checkinCounterAttentionTimePerPax2 ?? '';
    _pax3Controller.text = t.checkinCounterAttentionTimePerPax3 ?? '';
    _pax4Controller.text = t.checkinCounterAttentionTimePerPax4 ?? '';
    _pax5Controller.text = t.checkinCounterAttentionTimePerPax5 ?? '';
    _paxMaxController.text = t.checkinCounterAttentionTimePerPaxMax ?? '';
  }

  Future<void> _commitChronosCheckin({bool autosave = false}) async {
    // construye la persistKey igual que en build()
    String _pKeyFromField(String field) {
      final inspection = ref.read(inspectionDetailsProvider);
      final id = inspection?.id;
      final part = field.substring('checkin_counter_'.length);
      return id != null ? '$id:checkin_counter_$part' : 'checkin_counter_$part';
    }

    TextEditingController? _ctrlFor(String alias) {
      switch (alias) {
        case 'offline_time':
          return _offlineTimeController;
        case 'med1':
          return _pax1Controller;
        case 'med2':
          return _pax2Controller;
        case 'med3':
          return _pax3Controller;
        case 'med4':
          return _pax4Controller;
        case 'med5':
          return _pax5Controller;
        case 'maxTime':
          return _paxMaxController;
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
            persistKey: _pKeyFromField(field),
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
              field: field, value: ctrl?.text ?? '', onSave: _saveField);
        }
      }
    }
  }

  Map<String, dynamic> getData() {
    _commitChronosCheckin();
    return {
      'checkin_counter_time': _timeController.text,
      'checkin_counter_assigned_counters_zone': _zoneController.text,
      'checkin_counter_assigned_counters':
          int.tryParse(_assignedCountersController.text) ?? 0,
      'checkin_counter_operating_counters':
          int.tryParse(_operatingCountersController.text) ?? 0,
      'checkin_counter_pax_waiting_area':
          int.tryParse(_paxWaitingAreaController.text) ?? 0,
      'checkin_counter_offline_time': _offlineTimeController.text,
      'checkin_counter_attention_time_per_pax_1': _pax1Controller.text,
      'checkin_counter_attention_time_per_pax_2': _pax2Controller.text,
      'checkin_counter_attention_time_per_pax_3': _pax3Controller.text,
      'checkin_counter_attention_time_per_pax_4': _pax4Controller.text,
      'checkin_counter_attention_time_per_pax_5': _pax5Controller.text,
      'checkin_counter_attention_time_per_pax_max': _paxMaxController.text,
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

    bool isNational = details is NationalDepartures;

    if (details.id != null && !_photoLoaded) {
      _photoLoaded = true;
      Future.microtask(() {
        _loadListsFromSQLite(
          details.id!,
          isNational,
        );
        _loadExistingPhoto(widget.inspection.id!);
      });
    }

    final id = details.id;

    String k(String name) =>
        id != null ? '$id:checkin_counter_$name' : 'checkin_counter_$name';

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Check-in – Counters & Tiempos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // ----------------------------- Área ----------------------
                  buildEditableField(
                    label: 'Hora',
                    field: 'checkin_counter_time',
                    controller: _timeController,
                    focusNode: _timeFocus,
                    onTap: () =>
                        _selectTime(_timeController, 'checkin_counter_time'),
                    suffixIcon: const Icon(Icons.access_time),
                    //setupAutoSaveField: _setupAutoSaveField,
                  ),
                  /*buildEditableField(
                    label: 'Zona counters asignados',
                    field: 'checkin_counter_assigned_counters_zone',
                    controller: _zoneController,
                    focusNode: _zoneFocus,
                    //setupAutoSaveField: _setupAutoSaveField,
                  ),*/
                  Text("Zona counters asignados"),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_counterNumbers.length, (index) {
                      final c = _counterNumbers[index];
                      final selected = _counterSelections[index];

                      return ChoiceChip(
                        label: Text(c.name),
                        selected: selected,
                        selectedColor: Colors.blue,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black,
                        ),
                        onSelected: (bool value) async {
                          await ref
                              .read(checkinCounterRepositoryProvider)
                              .setSelected(
                                departureId: details.id!,
                                isNational: isNational,
                                counterId: c.id,
                                newValue: value,
                              );

                          setState(() {
                            _counterSelections[index] = value;
                            _counterNumbers[index].selected = value ? 1 : 0;
                          });
                        },
                      );
                    }),
                  ),

                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: buildEditableField(
                        label: 'Counters asignados',
                        field: 'checkin_counter_assigned_counters',
                        controller: _assignedCountersController,
                        focusNode: _assignedCountersFocus,
                        keyboardType: TextInputType.number,
                        //setupAutoSaveField: _setupAutoSaveField,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: buildEditableField(
                        label: 'Counters operativos',
                        field: 'checkin_counter_operating_counters',
                        controller: _operatingCountersController,
                        focusNode: _operatingCountersFocus,
                        keyboardType: TextInputType.number,
                        //setupAutoSaveField: _setupAutoSaveField,
                      ),
                    )
                  ]),
                  buildEditableField(
                    label: 'PAX en área de espera',
                    field: 'checkin_counter_pax_waiting_area',
                    controller: _paxWaitingAreaController,
                    focusNode: _paxWaitingAreaFocus,
                    keyboardType: TextInputType.number,
                    //setupAutoSaveField: _setupAutoSaveField,
                  ),

                  Row(children: [
                    Expanded(
                      child: CronometroField(
                        key: _chronoKeys['offline_time'],
                        persistKey: k('offline_time'),
                        label: 'Tiempo fuera de línea',
                        controller: _offlineTimeController,
                      ),
                    ),
                  ]),
                  // ----------------------------- PAX -----------------------
                  const Divider(height: 32),
                  const Text(
                    'Tiempos de atención por PAX',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: CronometroField(
                        key: _chronoKeys['med1'],
                        persistKey: k('attention_time_per_pax_1'),
                        label: 'Med 1',
                        controller: _pax1Controller,
                      ),
                      /*
                      child: buildEditableField(
                        label: 'Med 1',
                        field: 'checkin_counter_attention_time_per_pax_1',
                        controller: _pax1Controller,
                        focusNode: _pax1Focus,
                        onTap: () => _selectTime(_pax1Controller,
                            'checkin_counter_attention_time_per_pax_1'),
                        suffixIcon: const Icon(Icons.access_time),
                        //setupAutoSaveField: _setupAutoSaveField,
                      ),*/
                    ),
                  ]),
                  //const SizedBox(width: 16),

                  Row(children: [
                    Expanded(
                      child: CronometroField(
                        key: _chronoKeys['med2'],
                        persistKey: k('attention_time_per_pax_2'),
                        label: 'Med 2',
                        controller: _pax2Controller,
                      ),
                    )
                  ]),
                  Row(children: [
                    Expanded(
                      child: CronometroField(
                        key: _chronoKeys['med3'],
                        persistKey: k('attention_time_per_pax_3'),
                        label: 'Med 3',
                        controller: _pax3Controller,
                      ),
                    ),
                  ]),
                  //const SizedBox(width: 16),

                  Row(children: [
                    Expanded(
                      child: CronometroField(
                        key: _chronoKeys['med4'],
                        persistKey: k('attention_time_per_pax_4'),
                        label: 'Med 4',
                        controller: _pax4Controller,
                      ),
                      /*
                      child: buildEditableField(
                        label: 'Med 4',
                        field: 'checkin_counter_attention_time_per_pax_4',
                        controller: _pax4Controller,
                        focusNode: _pax4Focus,
                        onTap: () => _selectTime(_pax4Controller,
                            'checkin_counter_attention_time_per_pax_4'),
                        suffixIcon: const Icon(Icons.access_time),
                        //setupAutoSaveField: _setupAutoSaveField,
                      ),*/
                    )
                  ]),
                  Row(
                    children: [
                      Expanded(
                        //flex: 1,
                        child: CronometroField(
                          key: _chronoKeys['med5'],
                          persistKey: k('attention_time_per_pax_5'),
                          label: 'Med 5',
                          controller: _pax5Controller,
                        ),
                        /*
                        child: buildEditableField(
                          label: 'Med 5',
                          field: 'checkin_counter_attention_time_per_pax_5',
                          controller: _pax5Controller,
                          focusNode: _pax5Focus,
                          onTap: () => _selectTime(_pax5Controller,
                              'checkin_counter_attention_time_per_pax_5'),
                          suffixIcon: const Icon(Icons.access_time),
                          //setupAutoSaveField: _setupAutoSaveField,
                        ),*/
                      ),
                      /*const SizedBox(width: 16),
                      const Spacer(flex: 1),*/
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CronometroField(
                          /*key: const ValueKey(
                        'self_checkin_kiosks_service_time_per_pax_2'),*/
                          key: _chronoKeys['maxTime'],
                          persistKey: k('attention_time_per_pax_max'),
                          label: 'Tiempo máximo de espera',
                          controller: _paxMaxController,
                          //helperText: 'Tiempo de atención por pasajero',
                        ),
                      ),
                    ],
                  ),
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

  // ---------------------------------------------------------------------------
  @override
  void dispose() {
    // Controllers
    _timeController.dispose();
    _zoneController.dispose();
    _assignedCountersController.dispose();
    _operatingCountersController.dispose();
    _paxWaitingAreaController.dispose();
    _offlineTimeController.dispose();
    _pax1Controller.dispose();
    _pax2Controller.dispose();
    _pax3Controller.dispose();
    _pax4Controller.dispose();
    _pax5Controller.dispose();
    _paxMaxController.dispose();

    // FocusNodes
    _timeFocus.dispose();
    _zoneFocus.dispose();
    _assignedCountersFocus.dispose();
    _operatingCountersFocus.dispose();
    _paxWaitingAreaFocus.dispose();
    _offlineTimeFocus.dispose();
    _pax1Focus.dispose();
    _pax2Focus.dispose();
    _pax3Focus.dispose();
    _pax4Focus.dispose();
    _pax5Focus.dispose();
    _paxMaxFocus.dispose();
    super.dispose();
  }
}
