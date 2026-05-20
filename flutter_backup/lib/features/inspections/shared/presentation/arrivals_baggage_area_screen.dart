import 'dart:io';

import 'package:epmsa_mobile/core/helpers/photo_helpers.dart';
import 'package:epmsa_mobile/core/presentation/fields.dart';
import 'package:epmsa_mobile/core/providers/auto_save_provider.dart';
import 'package:epmsa_mobile/features/inspections/header/providers/inspections_providers.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/baggage_area_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_photo.dart';
import 'package:epmsa_mobile/features/inspections/header/domain/Inspection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ArrivalsBaggageAreaScreen extends ConsumerStatefulWidget {
  final Inspection inspection;
  const ArrivalsBaggageAreaScreen({super.key, required this.inspection});

  @override
  ConsumerState<ArrivalsBaggageAreaScreen> createState() =>
      ArrivalsBaggageAreaScreenState();
}

class ArrivalsBaggageAreaScreenState
    extends ConsumerState<ArrivalsBaggageAreaScreen> {
  final _formKey = GlobalKey<FormState>();

  //String? _selectedBelts;

  final List<String> _beltOptions = ['1', '2', '3', '4', '5', '6'];
  final Set<String> _selectedBelts = {};
  late List<bool> _beltSelections;

  final TextEditingController _notesBeltsController = TextEditingController();
  final TextEditingController _time1Controller = TextEditingController();
  final TextEditingController _pax1Controller = TextEditingController();
  final TextEditingController _time2Controller = TextEditingController();
  final TextEditingController _pax2Controller = TextEditingController();
  final TextEditingController _time3Controller = TextEditingController();
  final TextEditingController _pax3Controller = TextEditingController();
  final TextEditingController _ndsAreaFunctionController =
      TextEditingController();
  final _photoController = TextEditingController();

  List<File> _images = [];
  bool _photoLoaded = false;

  final _notesBeltsFocusNode = FocusNode();
  final _time1FocusNode = FocusNode();
  final _pax1FocusNode = FocusNode();
  final _time2FocusNode = FocusNode();
  final _pax2FocusNode = FocusNode();
  final _time3FocusNode = FocusNode();
  final _pax3FocusNode = FocusNode();
  //final _ndsAreaFunctionFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _beltSelections = List.generate(_beltOptions.length, (_) => false);

    _setupAutoSaveField(
      'notes_belts',
      _notesBeltsController,
      _notesBeltsFocusNode,
    );

    // Autosave al perder foco (coincide con los field usados en buildEditableField)
    _setupAutoSaveField(
      'baggage_claim_time_1',
      _time1Controller,
      _time1FocusNode,
    );
    _setupAutoSaveField(
      'baggage_claim_pax_waiting_area_1',
      _pax1Controller,
      _pax1FocusNode,
    );

    _setupAutoSaveField(
      'baggage_claim_time_2',
      _time2Controller,
      _time2FocusNode,
    );
    _setupAutoSaveField(
      'baggage_claim_pax_waiting_area_2',
      _pax2Controller,
      _pax2FocusNode,
    );

    _setupAutoSaveField(
      'baggage_claim_time_3',
      _time3Controller,
      _time3FocusNode,
    );
    _setupAutoSaveField(
      'baggage_claim_pax_waiting_area_3',
      _pax3Controller,
      _pax3FocusNode,
    );
  }

  @override
  void dispose() {
    _time1Controller.dispose();
    _pax1Controller.dispose();
    _time2Controller.dispose();
    _pax2Controller.dispose();
    _time3Controller.dispose();
    _pax3Controller.dispose();
    _ndsAreaFunctionController.dispose();
    super.dispose();
  }

  void setData(BaggageAreaData data) {
    setState(() {
      _selectedBelts.clear();
      _selectedBelts.addAll(data.belts);
      _beltSelections =
          _beltOptions.map((b) => _selectedBelts.contains(b)).toList();
    });
    _notesBeltsController.text = data.notes_belts ?? '';
    _time1Controller.text = data.time1 ?? '';
    _pax1Controller.text = data.pax1.toString();
    _time2Controller.text = data.time2 ?? '';
    _pax2Controller.text = data.pax2.toString();
    _time3Controller.text = data.time3 ?? '';
    _pax3Controller.text = data.pax3.toString();
    _ndsAreaFunctionController.text = data.ndsAreaFunction ?? '';
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
    //final arrival = ref.read(arrivalProvider);
    final inspection = ref.read(inspectionDetailsProvider);

    if (inspection == null) return;

    final updated = inspection.copyWithField(field, value);
    final service = ref.read(inspectionServiceSelectorProvider(updated));

    await service.save(updated);
    //ref.read(arrivalProvider.notifier).setArrival(updated);
    ref.read(inspectionDetailsProvider.notifier).setInspectionDetails(updated);

    debugPrint(
        '💾 Guardando $field = $value, en arrival id = ${inspection.id}');
  }

  Map<String, dynamic> getData() {
    return {
      'baggage_claim_belts': _selectedBelts.join(','),
      'notes_belts': _notesBeltsController.text,
      'baggage_claim_time_1': _time1Controller.text,
      'baggage_claim_pax_waiting_area_1':
          int.tryParse(_pax1Controller.text) ?? 0,
      'baggage_claim_time_2': _time2Controller.text,
      'baggage_claim_pax_waiting_area_2':
          int.tryParse(_pax2Controller.text) ?? 0,
      'baggage_claim_time_3': _time3Controller.text,
      'baggage_claim_pax_waiting_area_3':
          int.tryParse(_pax3Controller.text) ?? 0,
      'baggage_claim_time_function': _ndsAreaFunctionController.text,
    };
  }

  bool validate() {
    final isValid = _formKey.currentState?.validate() ?? false;
    return isValid;
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
      section: 'baggage_claim',
    );
    await ref.read(photoServiceProvider).savePhoto(photo);
  }

  Future<void> _loadExistingPhoto(int id) async {
    final photos = await ref
        .read(photoServiceProvider)
        .getPhotosBySection(id, 'baggage_claim');
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
            label: const Text('Foto – Retiro equipaje'),
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

  @override
  Widget build(BuildContext context) {
    //List<String> beltsChoice = ["Bandas 1 a 3", "Bandas 4 a 6"];
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
                  const Text('Retiro de equipaje/ Nds ADRM 9nd ed. (ÁREA)',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Bandas utilizadas:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ToggleButtons(
                    isSelected: _beltOptions
                        .map((belt) => _selectedBelts.contains(belt))
                        .toList(),
                    onPressed: (int index) {
                      setState(() {
                        final belt = _beltOptions[index];
                        if (_selectedBelts.contains(belt)) {
                          _selectedBelts.remove(belt);
                        } else {
                          _selectedBelts.add(belt);
                        }
                      });
                      ref.read(autoSaveServiceProvider).saveField(
                            field: 'baggage_claim_belts',
                            value: _selectedBelts.join(','),
                            onSave: _saveField,
                          );
                    },
                    borderRadius: BorderRadius.circular(8),
                    selectedColor: Colors.white,
                    fillColor: Colors.blue,
                    color: Colors.black,
                    constraints:
                        const BoxConstraints(minHeight: 40, minWidth: 50),
                    children: _beltOptions.map((belt) {
                      final number = belt.replaceAll('Banda ', '');
                      return Text(number, style: const TextStyle(fontSize: 16));
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: buildEditableField(
                        label: 'Notas bandas asignadas',
                        field: 'notes_betls',
                        controller: _notesBeltsController,
                        focusNode: _notesBeltsFocusNode,
                        //setupAutoSaveField: _setupAutoSaveField
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: buildEditableField(
                        label: 'Hora 1',
                        field: 'baggage_claim_time_1',
                        controller: _time1Controller,
                        focusNode: _time1FocusNode,
                        onTap: () => _selectTime(_time1Controller),
                        suffixIcon: const Icon(Icons.access_time),
                        //setupAutoSaveField: _setupAutoSaveField
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: buildEditableField(
                        label: 'PAX 1',
                        field: 'baggage_claim_pax_waiting_area_1',
                        controller: _pax1Controller,
                        focusNode: _pax1FocusNode,
                        keyboardType: TextInputType.number,
                        //setupAutoSaveField: _setupAutoSaveField
                      ),
                    ),
                  ]),
                  Row(children: [
                    Expanded(
                      child: buildEditableField(
                        label: 'Hora 2',
                        field: 'baggage_claim_time_2',
                        controller: _time2Controller,
                        focusNode: _time2FocusNode,
                        onTap: () => _selectTime(_time2Controller),
                        suffixIcon: const Icon(Icons.access_time),
                        //setupAutoSaveField: _setupAutoSaveField
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: buildEditableField(
                        label: 'PAX 2',
                        field: 'baggage_claim_pax_waiting_area_2',
                        controller: _pax2Controller,
                        focusNode: _pax2FocusNode,
                        keyboardType: TextInputType.number,
                        //setupAutoSaveField: _setupAutoSaveField
                      ),
                    ),
                  ]),
                  Row(children: [
                    Expanded(
                      child: buildEditableField(
                        label: 'Hora 3',
                        field: 'baggage_claim_time_3',
                        controller: _time3Controller,
                        focusNode: _time3FocusNode,
                        onTap: () => _selectTime(_time3Controller),
                        suffixIcon: const Icon(Icons.access_time),
                        //setupAutoSaveField: _setupAutoSaveField
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: buildEditableField(
                        label: 'PAX 3',
                        field: 'baggage_claim_pax_waiting_area_3',
                        controller: _pax3Controller,
                        focusNode: _pax3FocusNode,
                        keyboardType: TextInputType.number,
                        //setupAutoSaveField: _setupAutoSaveField
                      ),
                    ),
                  ]),
                  /*buildEditableField(
                      label: 'NDS ADRM (Función del area)',
                      field: 'baggage_claim_nds_adrm_area_function',
                      controller: _ndsAreaFunctionController,
                      focusNode: _ndsAreaFunctionFocusNode),*/
                  /*buildLabelField('NDS ADRM (Función del area)',
                      _ndsAreaFunctionController),
                  const SizedBox(height: 8),*/
                  /*ElevatedButton.icon(
                    onPressed: _handlePhoto,
                    icon: _photoIcon(),
                    label: const Text('Cargar Foto'),
                  ),*/
                  _photoWidget(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
