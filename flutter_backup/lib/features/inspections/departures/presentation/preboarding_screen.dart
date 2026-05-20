import 'dart:io';

import 'package:epmsa_mobile/features/inspections/arrivals/national/domain/national_arrivals.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/preboarding_data.dart';
import 'package:epmsa_mobile/features/inspections/departures/international/domain/international_departures.dart';
import 'package:epmsa_mobile/features/inspections/departures/national/domain/national_departures.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epmsa_mobile/core/presentation/fields.dart';
import 'package:epmsa_mobile/core/helpers/photo_helpers.dart';
import 'package:epmsa_mobile/core/providers/auto_save_provider.dart';
import 'package:epmsa_mobile/features/inspections/departures/providers/depatures_provider.dart';
import 'package:epmsa_mobile/features/inspections/header/domain/Inspection.dart';
import 'package:epmsa_mobile/features/inspections/header/providers/inspections_providers.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_photo.dart';

class PreboardingScreen extends ConsumerStatefulWidget {
  final Inspection inspection;
  const PreboardingScreen({super.key, required this.inspection});

  @override
  ConsumerState<PreboardingScreen> createState() => PreboardingScreenState();
}

class PreboardingScreenState extends ConsumerState<PreboardingScreen> {
  /// Lista dinámica de controladores – uno por cada registro devuelto por la API.
  final List<Map<String, TextEditingController>> _controllersList = [];
  final List<int> _detailIds = [];

  int? _expandedIndex;
  bool _dataLoaded = false;
  bool _preboardingDetail = false;
  File? _selectedImage;

  @override
  void dispose() {
    // Liberamos memoria de los controladores creados dinámicamente.
    for (final map in _controllersList) {
      for (final ctrl in map.values) {
        ctrl.dispose();
      }
    }
    super.dispose();
  }

  /// Carga de datos desde el servicio y set-up inicial de controladores.
  Future<void> _loadDataFromDetails(InspectionDetails details) async {
    final depId = details.id;
    if (depId == null) return;

    final service = ref.read(preboardingServiceProvider);
    final isNational = details is NationalDepartures;

    final result = isNational
        ? await service.loadNationalPreboardingData(depId)
        : await service.loadInternationalPreboardingData(depId);

    // Anti-race
    final now = ref.read(inspectionDetailsProvider);
    if (!mounted || now == null || now.id != depId) return;

    // Limpia controllers antiguos
    for (final m in _controllersList) {
      for (final ctrl in m.values) ctrl.dispose();
    }
    _controllersList.clear();
    _detailIds.clear();

    // Construye controllers
    print("Getting preboarding lines");
    for (final record in result) {
      print("${record.toJson()}");
      _detailIds.add(record.id!);
      _controllersList.add({
        'area': TextEditingController(text: record.area ?? ''),
        'usedChairs':
            TextEditingController(text: (record.usedChairs ?? 0).toString()),
        'availableChairs': TextEditingController(
            text: (record.availableChairs ?? 0).toString()),
        'usedArea':
            TextEditingController(text: (record.usedArea ?? 0).toString()),
        'availableArea':
            TextEditingController(text: (record.availableArea ?? 0).toString()),
        'occupancyPercentage': TextEditingController(
            text: (record.occupancyPercentage ?? 0.0).toString()),
      });
    }

    if (!mounted) return;
    setState(() {
      _expandedIndex = _controllersList.isNotEmpty ? 0 : null;
      _preboardingDetail = _controllersList.isNotEmpty;
    });
  }

  /// Helper para registrar auto-guardado cuando un campo pierde foco.
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

  // Helper opcional: arma la línea Preboarding desde los controllers de la fila.
  Preboarding _lineFromIndex(int idx) {
    final m = _controllersList[idx];

    int? _toInt(String? s) => int.tryParse((s ?? '').trim());

    return Preboarding(
      id: _detailIds[idx],
      area: m['area']?.text,
      used: true,
      usedChairs: _toInt(m['usedChairs']?.text),
      availableChairs: _toInt(m['availableChairs']?.text),
      usedArea: _toInt(m['usedArea']?.text),
      availableArea: _toInt(m['availableArea']?.text),
      occupancyPercentage: _toInt(m['occupancyPercentage']?.text),
    );
  }

  Future<void> _saveField(String field, dynamic value) async {
    // 1) Obtener idx desde el nombre del field
    final idxStr = field.substring('occupancy_percentage_'.length);
    final idx = int.tryParse(idxStr);
    if (idx == null || idx < 0 || idx >= _controllersList.length) return;

    // 2) Con idx, tomar el detailId desde tu controllersList
    final detailId = _detailIds[idx];

    // (opcional) reflejar normalizado en el controller de la UI
    _controllersList[idx]['occupancyPercentage']?.text = value.toString();

    final line = _lineFromIndex(idx);

    final details = ref.read(inspectionDetailsProvider);
    if (details == null || details.id == null) return;

    final svc = ref.read(preboardingServiceProvider);

    if (details is NationalDepartures) {
      await svc.saveNationalLine(details.id!, detailId, line);
    } else if (details is InternationalDepartures) {
      await svc.saveInternationalLine(details.id!, detailId, line);
    } else {
      // No aplica para arrivals en esta screen
      return;
    }

    debugPrint(
      '💾 [DETAIL] occupancy_percentage=$value (detailId=$detailId, departureId=${details.id})',
    );
  }

  int? _loadedForId;

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(inspectionDetailsProvider);

    final id = details?.id;
    if (id == null || id == 0) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadedForId != id) {
      _loadedForId = id;
      Future.microtask(() {
        _loadDataFromDetails(details!);
      });
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: ExpansionPanelList.radio(
          expandedHeaderPadding: const EdgeInsets.symmetric(vertical: 8),
          initialOpenPanelValue: _expandedIndex,
          children: List.generate(_controllersList.length, (index) {
            final c = _controllersList[index];
            return ExpansionPanelRadio(
              value: index,
              headerBuilder: (_, __) => ListTile(
                title: Text("${c['area']!.text}"),
                textColor: Colors.blue,
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: PreboardingForm(
                  index: index,
                  id: _detailIds[index],
                  inspection: widget.inspection,
                  usedChairsController: c['usedChairs']!,
                  availableChairsController: c['availableChairs']!,
                  usedAreaController: c['usedArea']!,
                  availableAreaController: c['availableArea']!,
                  occupancyPercentageController: c['occupancyPercentage']!,
                  setupAutoSaveField: _setupAutoSaveField,
                ),
              ),
            );
          }),
        ),
      ),
    );
    //}
  }
}

// -----------------------------------------------------------------------------
//                           PREBOARDING FORM (por área)
// -----------------------------------------------------------------------------

class PreboardingForm extends ConsumerStatefulWidget {
  final int index;
  final int id;
  final Inspection inspection;
  final TextEditingController usedChairsController;
  final TextEditingController availableChairsController;
  final TextEditingController usedAreaController;
  final TextEditingController availableAreaController;
  final TextEditingController occupancyPercentageController;
  final void Function(String, TextEditingController, FocusNode)
      setupAutoSaveField;

  const PreboardingForm({
    super.key,
    required this.id,
    required this.index,
    required this.inspection,
    required this.usedChairsController,
    required this.availableChairsController,
    required this.usedAreaController,
    required this.availableAreaController,
    required this.occupancyPercentageController,
    required this.setupAutoSaveField,
  });

  @override
  ConsumerState<PreboardingForm> createState() => _PreboardingFormState();
}

class _PreboardingFormState extends ConsumerState<PreboardingForm> {
  final _photoController = TextEditingController();
  final _occupancyPercentageFocus = FocusNode();

  // Multi-foto
  List<File> _images = [];
  bool _photosLoaded = false;

  @override
  void initState() {
    super.initState();
    // Auto-save para % de ocupación
    widget.setupAutoSaveField(
      'occupancy_percentage_${widget.index}',
      widget.occupancyPercentageController,
      _occupancyPercentageFocus,
    );

    // Cargar todas las fotos existentes de esta línea (detalle) usando section por id
    Future.microtask(() => _loadExistingPhotos(widget.inspection.id!));
  }

  @override
  void dispose() {
    _photoController.dispose();
    _occupancyPercentageFocus.dispose();
    super.dispose();
  }

  // --------------------------- FOTOS (multi) ---------------------------------
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
      section: 'pre-boarding_${widget.id}',
    );
    await ref.read(photoServiceProvider).savePhoto(photo);
  }

  Future<void> _loadExistingPhotos(int inspectionId) async {
    if (_photosLoaded) return; // evita recargas innecesarias
    final photos = await ref
        .read(photoServiceProvider)
        .getPhotosBySection(inspectionId, 'pre-boarding_${widget.id}');
    if (!mounted) return;
    if (photos.isNotEmpty) {
      setState(() {
        _images = photos.map((p) => File(p.path)).toList();
        _photosLoaded = true;
      });
    } else {
      _photosLoaded = true;
    }
  }

  Widget _photoWidget() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: _handlePhoto,
            icon: _photoIcon(),
            label: const Text('Foto - Preboarding'),
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

  // --------------------------- UI -------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabelField('Sillas utilizadas', widget.usedChairsController),
        buildLabelField('Sillas disponibles', widget.availableChairsController),
        buildEditableField(
          label: 'Porcentaje de ocupación',
          field: 'occupancy_percentage_${widget.index}',
          controller: widget.occupancyPercentageController,
          focusNode: _occupancyPercentageFocus,
        ),
        buildLabelField('Área utilizada', widget.usedAreaController),
        buildLabelField('Área disponible', widget.availableAreaController),
        const SizedBox(height: 12),
        _photoWidget(),
      ],
    );
  }
}
