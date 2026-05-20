import 'dart:io';

import 'package:epmsa_mobile/core/helpers/photo_helpers.dart';
import 'package:epmsa_mobile/core/providers/auto_save_provider.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/observations_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/providers/arrivals_provider.dart';
import 'package:epmsa_mobile/features/inspections/header/domain/Inspection.dart';
import 'package:epmsa_mobile/features/inspections/header/providers/inspections_providers.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ObservationsScreen extends ConsumerStatefulWidget {
  final Inspection inspection;
  const ObservationsScreen({super.key, required this.inspection});

  @override
  ConsumerState<ObservationsScreen> createState() => ObservationsScreenState();
}

class ObservationsScreenState extends ConsumerState<ObservationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _eventTimeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _consequenceController = TextEditingController();
  final TextEditingController _photoController = TextEditingController();
  List<File> _images = [];
  bool _photoLoaded = false;

  final _eventTimeFocusNode = FocusNode();
  final _locationFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _consequenceFocusNode = FocusNode();
  //final _photoFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _setupAutoSaveField(
        'observations_event_time', _eventTimeController, _eventTimeFocusNode);
    _setupAutoSaveField(
        'observations_location', _locationController, _locationFocusNode);
    _setupAutoSaveField('observations_description', _descriptionController,
        _descriptionFocusNode);
    _setupAutoSaveField('observations_consequence', _consequenceController,
        _consequenceFocusNode);
    /*_setupAutoSaveField(
        'observations_photo', _photoController, _photoFocusNode);*/
  }

  @override
  void dispose() {
    _eventTimeController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _consequenceController.dispose();
    _photoController.dispose();
    super.dispose();
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

  //List<InspectionPhoto> _photos = [];

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
      section: 'observations',
    );
    await ref.read(photoServiceProvider).savePhoto(photo);
  }

  /*Icon _iconFor(File? image) => image != null
      ? const Icon(Icons.check_circle, color: Colors.green)
      : const Icon(Icons.camera_alt);*/

  Widget _photoWidget() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: _handlePhoto,
            //icon: _iconFor(_imageCheckin),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Foto – Observaciones'),
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

  Widget buildEditableField({
    required String label,
    required String field,
    required TextEditingController controller,
    required FocusNode focusNode,
    GestureTapCallback? onTap,
    Icon? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: suffixIcon,
        ),
        keyboardType: keyboardType,
      ),
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

  Widget buildLabelField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        enabled: false,
      ),
    );
  }

  Future<void> _loadExistingPhoto(int id) async {
    final photos = await ref
        .read(photoServiceProvider)
        .getPhotosBySection(id, 'observations');
    if (photos.isNotEmpty)
      setState(() => _images = photos.map((p) => File(p.path)).toList());
  }

  void setData(ObservationsData data) {
    _eventTimeController.text = data.eventTime ?? '';
    _locationController.text = data.location ?? '';
    _descriptionController.text = data.description ?? '';
    _consequenceController.text = data.consequence ?? '';
  }

  Map<String, dynamic> getData() {
    return {
      'observations_event_time': _eventTimeController.text,
      'observations_location': _locationController.text,
      'observations_description': _descriptionController.text,
      'observations_consequence': _consequenceController.text,
      /*'observations_observations_photo':
          _photoController.text.isNotEmpty ? _photoController.text : ' ',*/
    };
  }

  bool validate() {
    return _formKey.currentState?.validate() ?? false;
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
                  const Text('Observaciones y Novedades',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  buildEditableField(
                    label: 'Hora del evento',
                    field: 'event_time',
                    controller: _eventTimeController,
                    focusNode: _eventTimeFocusNode,
                    onTap: () => _selectTime(_eventTimeController),
                    suffixIcon: const Icon(Icons.access_time),
                  ),
                  buildEditableField(
                    label: 'Ubicación',
                    field: 'location',
                    controller: _locationController,
                    focusNode: _locationFocusNode,
                  ),
                  buildEditableField(
                    label: 'Descripción',
                    field: 'description',
                    controller: _descriptionController,
                    focusNode: _descriptionFocusNode,
                  ),
                  buildEditableField(
                    label: 'Consecuencia',
                    field: 'consequence',
                    controller: _consequenceController,
                    focusNode: _consequenceFocusNode,
                  ),
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
}
