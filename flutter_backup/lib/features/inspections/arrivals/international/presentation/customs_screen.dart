import 'dart:io';

import 'package:epmsa_mobile/core/helpers/photo_helpers.dart';
import 'package:epmsa_mobile/core/presentation/cronometro_field.dart';
import 'package:epmsa_mobile/core/presentation/fields.dart';
import 'package:epmsa_mobile/core/providers/auto_save_provider.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/international/domain/customs.dart';
import 'package:epmsa_mobile/features/inspections/header/domain/Inspection.dart';
import 'package:epmsa_mobile/features/inspections/header/providers/inspections_providers.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomsScreen extends ConsumerStatefulWidget {
  final Inspection inspection;
  const CustomsScreen({Key? key, required this.inspection}) : super(key: key);

  @override
  ConsumerState<CustomsScreen> createState() => CustomsScreenState();
}

class CustomsScreenState extends ConsumerState<CustomsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customsTimeController = TextEditingController();
  final TextEditingController _customsRxController = TextEditingController();
  final TextEditingController _customsScannerController =
      TextEditingController();
  final TextEditingController _customsPaxAreaController =
      TextEditingController();
  final TextEditingController _customsOccupancyController =
      TextEditingController();
  final TextEditingController _customsOfflineTimeController =
      TextEditingController();
  final TextEditingController _customsMaxWaitTimeController =
      TextEditingController();
  final TextEditingController _customsNdsAreaController =
      TextEditingController();
  final TextEditingController _customsNdsTimeController =
      TextEditingController();

  final hourFocus = FocusNode();
  final rxFocus = FocusNode();
  final scannerFocus = FocusNode();
  final paxFocus = FocusNode();
  final occupancyFocus = FocusNode();
  final offlineFocus = FocusNode();
  final maxWaitFocus = FocusNode();

  final _photoController = TextEditingController();

  // Multi-foto
  List<File> _images = [];
  bool _photoLoaded = false;

  @override
  void initState() {
    super.initState();

    // Registrar autosave en pérdida de foco (mismo nombre de field que usas en build)
    _setupAutoSaveField(
      'customs_time',
      _customsTimeController,
      hourFocus,
    );
    _setupAutoSaveField(
      'customs_rx_machine_operating',
      _customsRxController,
      rxFocus,
    );
    _setupAutoSaveField(
      'customs_passport_scanner_kiosks',
      _customsScannerController,
      scannerFocus,
    );
    _setupAutoSaveField(
      'customs_pax_waiting_area',
      _customsPaxAreaController,
      paxFocus,
    );

    _setupAutoSaveField(
      'customs_max_waiting_time',
      _customsMaxWaitTimeController,
      maxWaitFocus,
    );
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

  void setData(CustomsData customs) {
    _customsTimeController.text = customs.time ?? '';
    _customsRxController.text = customs.rxMachineOperating.toString() ?? '0';
    _customsScannerController.text =
        customs.passportScannerKiosks.toString() ?? '0';
    _customsPaxAreaController.text = customs.paxWaitingArea.toString() ?? '0';
    _customsOccupancyController.text =
        customs.occupancyArea.toString() ?? '0.0';
    _customsOfflineTimeController.text = customs.offlineTime ?? '';
    _customsMaxWaitTimeController.text = customs.maxWaitingTime ?? '';
    _customsNdsAreaController.text = customs.ndsArea ?? '';
    _customsNdsTimeController.text = customs.ndsTime ?? '';
  }

  Future<void> _commitChronosCustoms({bool autosave = false}) async {
    String _persistKeyOffline() {
      final inspection = ref.read(inspectionDetailsProvider);
      final id = inspection?.id;
      return id != null
          ? '$id:customs_customs_offline_time'
          : 'customs_customs_offline_time';
    }

    CronometroFieldState.stopAndCommitGlobal(
      persistKey: _persistKeyOffline(),
      controller: _customsOfflineTimeController,
    );

    if (_customsOfflineTimeController.text.trim().isEmpty) {
      _customsOfflineTimeController.text = '00:00';
    }

    if (autosave) {
      await ref.read(autoSaveServiceProvider).saveField(
            field: 'customs_offline_time',
            value: _customsOfflineTimeController.text,
            onSave: _saveField,
          );
    }
  }

  Map<String, dynamic> getData() {
    _commitChronosCustoms();
    return {
      'customs_time': _customsTimeController.text,
      'customs_maq_rx_oper': _customsRxController.text,
      'customs_kiosko_pass': _customsScannerController.text,
      'customs_pax_waiting_area': _customsPaxAreaController.text,
      'customs_area_occupancy': _customsOccupancyController.text,
      'customs_offline_time': _customsOfflineTimeController.text,
      'customs_waiting_time_max': _customsMaxWaitTimeController.text,
      'customs_nds_area': _customsNdsAreaController.text,
      'customs_nds_time': _customsNdsTimeController.text,
    };
  }

  Future<void> _loadExistingPhoto(int id) async {
    final photos =
        await ref.read(photoServiceProvider).getPhotosBySection(id, 'customs');
    if (photos.isNotEmpty)
      setState(() => _images = photos.map((p) => File(p.path)).toList());
  }

  Icon _photoIcon() => _images.isNotEmpty
      ? const Icon(Icons.check_circle, color: Colors.green)
      : const Icon(Icons.camera_alt);

  Future<void> _handlePhoto() async {
    final path = await PhotoHelper.takeAndSavePhoto(context: context);
    if (path == null) return;

    setState(() {
      _images.add(File(path));
      _photoController.text = path;
    });

    final photo = InspectionPhoto(
      inspectionId: widget.inspection.id!,
      path: path,
      timestamp: DateTime.now(),
      // Mantiene particularidad: sección por id del detalle
      section: 'customs',
    );
    await ref.read(photoServiceProvider).savePhoto(photo);
  }

  Widget _photoWidget() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: _handlePhoto,
            icon: _photoIcon(),
            label: const Text('Foto - Customs'),
          ),
          if (_images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
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
            ),
        ],
      );

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
    final arrival = ref.read(inspectionDetailsProvider);

    if (arrival == null) return;

    final updated = arrival.copyWithField(field, value);
    final service = ref.read(inspectionServiceSelectorProvider(updated));

    await service.save(updated);
    ref.read(inspectionDetailsProvider.notifier).setInspectionDetails(updated);

    debugPrint('💾 Guardando $field = $value');
  }

  @override
  Widget build(BuildContext context) {
    final inspection = ref.read(inspectionDetailsProvider);
    final id = inspection?.id;

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
      Future.microtask(() => {
            _loadExistingPhoto(widget.inspection.id!),
          });
    }

    String k(String name) => id != null ? '$id:customs_$name' : 'customs_$name';
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
                  const Text('Aduana',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text('Area', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: buildEditableField(
                        label: 'Hora',
                        field: 'customs_time',
                        controller: _customsTimeController,
                        focusNode: hourFocus,
                        onTap: () => _selectTime(_customsTimeController),
                        suffixIcon: const Icon(Icons.access_time),
                        //setupAutoSaveField: _setupAutoSaveField
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: buildEditableField(
                        label: 'MAQ. RX Aduana Oper.',
                        field: 'customs_rx_machine_operating',
                        controller: _customsRxController,
                        focusNode: rxFocus,
                        keyboardType: TextInputType.number,
                        //setupAutoSaveField: _setupAutoSaveField
                      ),
                    )
                  ]),
                  Row(children: [
                    Expanded(
                      child: buildEditableField(
                        label: 'Quioscos Scanner Pasaporte',
                        field: 'customs_passport_scanner_kiosks',
                        controller: _customsScannerController,
                        focusNode: scannerFocus,
                        keyboardType: TextInputType.number,
                        //setupAutoSaveField: _setupAutoSaveField
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: buildEditableField(
                        label: 'PAX Área de Espera',
                        field: 'customs_pax_waiting_area',
                        controller: _customsPaxAreaController,
                        focusNode: paxFocus,
                        keyboardType: TextInputType.number,
                        //setupAutoSaveField: _setupAutoSaveField
                      ),
                    )
                  ]),
                  /*Row(children: [
                    Expanded(
                      child: buildLabelField('Ocupación Área Espera (%)',
                          _customsOccupancyController),
                      /*child: buildEditableField(
                          label: 'Ocupación Área Espera (%)',
                          field: 'customs_occupancy_area',
                          controller: _customsOccupancyController,
                          focusNode: occupancyFocus,
                          keyboardType: TextInputType.number,
                          //setupAutoSaveField: _setupAutoSaveField
),*/
                    ),
                  ]),*/
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: CronometroField(
                          key: const ValueKey('customs_offline_time'),
                          persistKey: k('customs_offline_time'),
                          label: 'Tiempo Fuera de Línea',
                          controller: _customsOfflineTimeController),
                    ),
                  ]),
                  /*buildLabelField(
                      'NdS (función del área)', _customsNdsAreaController),*/
                  const SizedBox(width: 16),
                  Text('Tiempo', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: CronometroField(
                        key: const ValueKey('customs_waiting_time_max'),
                        persistKey: k('customs_waiting_time_max'),
                        label: 'Tiempo máximo de espera',
                        controller: _customsMaxWaitTimeController,
                        //helperText: 'Tiempo de atención por pasajero',
                      ),
                    ),
                  ]),
                  /*buildLabelField(
                      'NdS (función del tiempo)', _customsNdsTimeController),*/
                  const SizedBox(height: 12),
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
