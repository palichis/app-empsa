import 'dart:io';

import 'package:epmsa_mobile/core/helpers/photo_helpers.dart';
import 'package:epmsa_mobile/core/presentation/cronometro_field.dart';
import 'package:epmsa_mobile/core/presentation/fields.dart';
import 'package:epmsa_mobile/core/providers/auto_save_provider.dart';
import 'package:epmsa_mobile/features/inspections/header/domain/Inspection.dart';
import 'package:epmsa_mobile/features/inspections/header/providers/inspections_providers.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/security_filters_area_data.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/security_filters_time_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecurityFiltersScreen extends ConsumerStatefulWidget {
  final Inspection inspection;
  const SecurityFiltersScreen({Key? key, required this.inspection})
      : super(key: key);

  @override
  ConsumerState<SecurityFiltersScreen> createState() =>
      SecurityFiltersScreenState();
}

class SecurityFiltersScreenState extends ConsumerState<SecurityFiltersScreen> {
  final _formKey = GlobalKey<FormState>();

  final _chronoKeys = <String, GlobalKey<CronometroFieldState>>{
    'offline_time': GlobalKey<CronometroFieldState>(),
    'pax1': GlobalKey<CronometroFieldState>(),
    'pax2': GlobalKey<CronometroFieldState>(),
    'pax3': GlobalKey<CronometroFieldState>(),
    'pax4': GlobalKey<CronometroFieldState>(),
    'pax5': GlobalKey<CronometroFieldState>(),
  };

  // Controllers – Área
  final _timeController = TextEditingController();
  final _domesticOpsController = TextEditingController();
  final _internationalOpsController = TextEditingController();
  final _docReviewAgentsController = TextEditingController();
  final _paxWaitingAreaController = TextEditingController();
  final _offlineTimeController = TextEditingController();

  // Controllers – Tiempo por PAX
  final _pax1Controller = TextEditingController();
  final _pax2Controller = TextEditingController();
  final _pax3Controller = TextEditingController();
  final _pax4Controller = TextEditingController();
  final _pax5Controller = TextEditingController();

  // FocusNodes
  final _timeFocus = FocusNode();
  final _domesticOpsFocus = FocusNode();
  final _internationalOpsFocus = FocusNode();
  final _docReviewAgentsFocus = FocusNode();
  final _paxWaitingAreaFocus = FocusNode();
  final _offlineTimeFocus = FocusNode();
  final _pax1Focus = FocusNode();
  final _pax2Focus = FocusNode();
  final _pax3Focus = FocusNode();
  final _pax4Focus = FocusNode();
  final _pax5Focus = FocusNode();

  // Foto
  List<File> _images = [];
  bool _photoLoaded = false;

  @override
  void initState() {
    super.initState();

    // Área
    _setupAutoSaveField(
      'security_filters_time',
      _timeController,
      _timeFocus,
    );
    _setupAutoSaveField(
      'security_filters_observed_domestic_operators',
      _domesticOpsController,
      _domesticOpsFocus,
    );
    _setupAutoSaveField(
      'security_filters_observed_international_operators',
      _internationalOpsController,
      _internationalOpsFocus,
    );
    _setupAutoSaveField(
      'security_filters_observed_document_review_agents',
      _docReviewAgentsController,
      _docReviewAgentsFocus,
    );
    _setupAutoSaveField(
      'security_filters_pax_waiting_area',
      _paxWaitingAreaController,
      _paxWaitingAreaFocus,
    );
  }

  // Autosave
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

  // Data helpers
  void setData(SecurityFiltersAreaData area, SecurityFiltersTimeData time) {
    _timeController.text = area.securityFiltersTime ?? '';
    _domesticOpsController.text =
        area.securityFiltersObservedDomesticOperators?.toString() ?? '';
    _internationalOpsController.text =
        area.securityFiltersObservedInternationalOperators?.toString() ?? '';
    _docReviewAgentsController.text =
        area.securityFiltersObservedDocumentReviewAgents?.toString() ?? '';
    _paxWaitingAreaController.text =
        area.securityFiltersPaxWaitingArea?.toString() ?? '';
    _offlineTimeController.text = area.securityFiltersOfflineTime ?? '';

    _pax1Controller.text = time.securityFiltersAttentionTimePerPax1 ?? '';
    _pax2Controller.text = time.securityFiltersAttentionTimePerPax2 ?? '';
    _pax3Controller.text = time.securityFiltersAttentionTimePerPax3 ?? '';
    _pax4Controller.text = time.securityFiltersAttentionTimePerPax4 ?? '';
    _pax5Controller.text = time.securityFiltersAttentionTimePerPax5 ?? '';
  }

  Future<void> _commitChronosSecurityFilters({bool autosave = false}) async {
    // genera persistKey igual que en build(): '$id:security_filters_$part'
    String _persistKey(String part) {
      final inspection = ref.read(inspectionDetailsProvider);
      final id = inspection?.id;
      return id != null
          ? '$id:security_filters_$part'
          : 'security_filters_$part';
    }

    // mapea alias -> controller (ya existentes en tu State)
    TextEditingController? _ctrlFor(String alias) {
      switch (alias) {
        case 'offline_time':
          return _offlineTimeController;
        case 'pax1':
          return _pax1Controller;
        case 'pax2':
          return _pax2Controller;
        case 'pax3':
          return _pax3Controller;
        case 'pax4':
          return _pax4Controller;
        case 'pax5':
          return _pax5Controller;
        default:
          return null;
      }
    }

    // mapea alias -> parte usada en persistKey / campo
    String? _partFor(String alias) {
      if (alias == 'offline_time') return 'offline_time';
      if (alias.startsWith('pax')) {
        final n = alias.substring(3); // '1'..'5'
        return 'attention_time_per_pax_$n';
      }
      return null;
    }

    for (final entry in _chronoKeys.entries) {
      final alias = entry.key;
      final gkey = entry.value;

      if (gkey.currentState != null) {
        gkey.currentState!.stopAndCommit();
      } else {
        final part = _partFor(alias);
        final ctrl = _ctrlFor(alias);
        if (part != null && ctrl != null) {
          CronometroFieldState.stopAndCommitGlobal(
            persistKey: _persistKey(part),
            controller: ctrl,
          );
        }
      }

      final ctrl = gkey.currentState?.widget.controller ?? _ctrlFor(alias);
      if (ctrl != null && ctrl.text.trim().isEmpty) {
        ctrl.text = '00:00';
      }

      if (autosave) {
        final part = _partFor(alias);
        final field = (part == null)
            ? null
            : (part == 'offline_time'
                ? 'security_filters_offline_time'
                : 'security_filters_$part');
        if (field != null) {
          await ref.read(autoSaveServiceProvider).saveField(
              field: field, value: ctrl?.text ?? '', onSave: _saveField);
        }
      }
    }
  }

  Map<String, dynamic> getData() {
    _commitChronosSecurityFilters();
    return {
      'security_filters_time': _timeController.text,
      'security_filters_observed_domestic_operators':
          int.tryParse(_domesticOpsController.text) ?? 0,
      'security_filters_observed_international_operators':
          int.tryParse(_internationalOpsController.text) ?? 0,
      'security_filters_observed_document_review_agents':
          int.tryParse(_docReviewAgentsController.text) ?? 0,
      'security_filters_pax_waiting_area':
          int.tryParse(_paxWaitingAreaController.text) ?? 0,
      'security_filters_offline_time': _offlineTimeController.text,
      'security_filters_attention_time_per_pax_1': _pax1Controller.text,
      'security_filters_attention_time_per_pax_2': _pax2Controller.text,
      'security_filters_attention_time_per_pax_3': _pax3Controller.text,
      'security_filters_attention_time_per_pax_4': _pax4Controller.text,
      'security_filters_attention_time_per_pax_5': _pax5Controller.text,
    };
  }

  bool validate() => _formKey.currentState?.validate() ?? false;

  // Foto helpers
  Icon _iconFor(File? image) => image != null
      ? const Icon(Icons.check_circle, color: Colors.green)
      : const Icon(Icons.camera_alt);

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
      section: 'security',
    );
    await ref.read(photoServiceProvider).savePhoto(photo);
  }

  Future<void> _loadExistingPhoto(int id) async {
    final photos =
        await ref.read(photoServiceProvider).getPhotosBySection(id, 'security');
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
            label: const Text('Foto – Filtros de seguridad'),
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

  @override
  Widget build(BuildContext context) {
    final inspection = ref.watch(inspectionDetailsProvider);
    if (inspection != null && inspection.id != null && !_photoLoaded) {
      _photoLoaded = true;
      Future.microtask(() => _loadExistingPhoto(widget.inspection.id!));
    }
    final id = inspection?.id;

    String k(String name) =>
        id != null ? '$id:security_filters_$name' : 'security_filters_$name';

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
                  const Text('Filtros de Seguridad',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Área -------------------------------------------------------------------------
                  buildEditableField(
                    label: 'Hora',
                    field: 'security_filters_time',
                    controller: _timeController,
                    focusNode: _timeFocus,
                    onTap: () =>
                        _selectTime(_timeController, 'security_filters_time'),
                    suffixIcon: const Icon(Icons.access_time),
                    //setupAutoSaveField: _setupAutoSaveField
                  ),
                  Row(children: [
                    Expanded(
                      child: buildEditableField(
                        label: 'MAQ. RX NAC OPER',
                        field: 'security_filters_observed_domestic_operators',
                        controller: _domesticOpsController,
                        focusNode: _domesticOpsFocus,
                        keyboardType: TextInputType.number,
                        //setupAutoSaveField: _setupAutoSaveField
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: buildEditableField(
                        label: 'MAQ. RX INT OPER.',
                        field:
                            'security_filters_observed_international_operators',
                        controller: _internationalOpsController,
                        focusNode: _internationalOpsFocus,
                        keyboardType: TextInputType.number,
                        //setupAutoSaveField: _setupAutoSaveField
                      ),
                    )
                  ]),
                  Row(children: [
                    Expanded(
                      child: buildEditableField(
                        label: 'Agentes rev. Documentos',
                        field:
                            'security_filters_observed_document_review_agents',
                        controller: _docReviewAgentsController,
                        focusNode: _docReviewAgentsFocus,
                        keyboardType: TextInputType.number,
                        //setupAutoSaveField: _setupAutoSaveField
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: buildEditableField(
                        label: 'PAX en Área de Espera',
                        field: 'security_filters_pax_waiting_area',
                        controller: _paxWaitingAreaController,
                        focusNode: _paxWaitingAreaFocus,
                        keyboardType: TextInputType.number,
                        //setupAutoSaveField: _setupAutoSaveField
                      ),
                    )
                  ]),
                  Row(children: [
                    Expanded(
                      child: CronometroField(
                          key: _chronoKeys['offline_time'],
                          persistKey: k('offline_time'),
                          label: 'Tiempo Fuera de Línea',
                          controller: _offlineTimeController),
                    ),
                  ]),
                  const Divider(height: 32),
                  const Text('Tiempos de atención por PAX',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: CronometroField(
                        key: _chronoKeys['pax1'],
                        persistKey: k('attention_time_per_pax_1'),
                        label: 'PAX 1',
                        controller: _pax1Controller,
                        helperText: 'Tiempo de atención por pasajero',
                      ),
                    ),
                  ]),

                  Row(children: [
                    //const SizedBox(width: 16),
                    Expanded(
                      child: CronometroField(
                        key: _chronoKeys['pax2'],
                        persistKey: k('attention_time_per_pax_2'),
                        label: 'PAX 2',
                        controller: _pax2Controller,
                        helperText: 'Tiempo de atención por pasajero',
                      ),
                      /*
                      child: buildEditableField(
                          label: 'PAX 2',
                          field: 'security_filters_attention_time_per_pax_2',
                          controller: _pax2Controller,
                          focusNode: _pax2Focus,
                          onTap: () => _selectTime(_pax2Controller,
                              'security_filters_attention_time_per_pax_2'),
                          suffixIcon: const Icon(Icons.access_time),
                          setupAutoSaveField: _setupAutoSaveField),*/
                    )
                  ]),
                  Row(children: [
                    Expanded(
                      child: CronometroField(
                        key: _chronoKeys['pax3'],
                        persistKey: k('attention_time_per_pax_3'),
                        label: 'Pax 3',
                        controller: _pax3Controller,
                        helperText: 'Tiempo de atención por pasajero',
                      ),
                      /*child: buildEditableField(
                          label: 'PAX 3',
                          field: 'security_filters_attention_time_per_pax_3',
                          controller: _pax3Controller,
                          focusNode: _pax3Focus,
                          onTap: () => _selectTime(_pax3Controller,
                              'security_filters_attention_time_per_pax_3'),
                          suffixIcon: const Icon(Icons.access_time),
                          setupAutoSaveField: _setupAutoSaveField),*/
                    ),
                  ]),
                  //const SizedBox(width: 16),

                  Row(children: [
                    Expanded(
                      child: CronometroField(
                        key: _chronoKeys['pax4'],
                        persistKey: k('attention_time_per_pax_4'),
                        label: 'Pax 4',
                        controller: _pax4Controller,
                        helperText: 'Tiempo de atención por pasajero',
                      ),
                      /*
                      child: buildEditableField(
                          label: 'PAX 4',
                          field: 'security_filters_attention_time_per_pax_4',
                          controller: _pax4Controller,
                          focusNode: _pax4Focus,
                          onTap: () => _selectTime(_pax4Controller,
                              'security_filters_attention_time_per_pax_4'),
                          suffixIcon: const Icon(Icons.access_time),
                          setupAutoSaveField: _setupAutoSaveField),*/
                    )
                  ]),
                  Row(
                    children: [
                      Expanded(
                        child: CronometroField(
                          key: _chronoKeys['pax5'],
                          persistKey: k('attention_time_per_pax_5'),
                          label: 'Pax 5',
                          controller: _pax5Controller,
                          helperText: 'Tiempo de atención por pasajero',
                        ),
                        //flex: 1,
                        /*child: buildEditableField(
                            label: 'PAX 5',
                            field: 'security_filters_attention_time_per_pax_5',
                            controller: _pax5Controller,
                            focusNode: _pax5Focus,
                            onTap: () => _selectTime(_pax5Controller,
                                'security_filters_attention_time_per_pax_5'),
                            suffixIcon: const Icon(Icons.access_time),
                            setupAutoSaveField: _setupAutoSaveField),*/
                      ),
                      /*const SizedBox(width: 16),
                      const Spacer(flex: 1),*/
                    ],
                  ),

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
    _domesticOpsController.dispose();
    _internationalOpsController.dispose();
    _docReviewAgentsController.dispose();
    _paxWaitingAreaController.dispose();
    _offlineTimeController.dispose();
    _pax1Controller.dispose();
    _pax2Controller.dispose();
    _pax3Controller.dispose();
    _pax4Controller.dispose();
    _pax5Controller.dispose();

    _timeFocus.dispose();
    _domesticOpsFocus.dispose();
    _internationalOpsFocus.dispose();
    _docReviewAgentsFocus.dispose();
    _paxWaitingAreaFocus.dispose();
    _offlineTimeFocus.dispose();
    _pax1Focus.dispose();
    _pax2Focus.dispose();
    _pax3Focus.dispose();
    _pax4Focus.dispose();
    _pax5Focus.dispose();
    super.dispose();
  }
}
