import 'package:epmsa_mobile/core/presentation/criteria_line_card.dart';
import 'package:epmsa_mobile/core/presentation/fields.dart';
import 'package:epmsa_mobile/core/presentation/form_field_array.dart';
import 'package:epmsa_mobile/core/providers/auto_save_provider.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/cargo.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/landside.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/landside_entry.dart';
import 'package:epmsa_mobile/features/inspections/cargo/providers/cargo_provider.dart';
import 'package:epmsa_mobile/features/inspections/header/domain/Inspection.dart';
import 'package:epmsa_mobile/features/inspections/header/providers/inspections_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CargoLandsideScreen extends ConsumerStatefulWidget {
  final Inspection inspection;
  const CargoLandsideScreen({super.key, required this.inspection});

  @override
  CargoLandsideScreenState createState() => CargoLandsideScreenState();
}

class CargoLandsideScreenState extends ConsumerState<CargoLandsideScreen> {
  bool _dataLoaded = false;
  Landside? _landsideDetail;
  int? _cargoId; // para autosave puntual

  // Controllers para campos tipo hora (String?)
  final TextEditingController _nationalHourController = TextEditingController();
  final TextEditingController _internationalHourController =
      TextEditingController();
  final TextEditingController _buildingHourController = TextEditingController();

  // Keys para listas
  final _nationalQualityKey = GlobalKey<FormFieldArrayState<LandsideEntry>>();
  final _nationalSecurityKey = GlobalKey<FormFieldArrayState<LandsideEntry>>();
  final _nationalEnvironmentKey =
      GlobalKey<FormFieldArrayState<LandsideEntry>>();
  final _internationalQualityKey =
      GlobalKey<FormFieldArrayState<LandsideEntry>>();
  final _internationalSecurityKey =
      GlobalKey<FormFieldArrayState<LandsideEntry>>();
  final _internationalEnvironmentKey =
      GlobalKey<FormFieldArrayState<LandsideEntry>>();
  final _buildingQualityKey = GlobalKey<FormFieldArrayState<LandsideEntry>>();
  final _buildingSecurityKey = GlobalKey<FormFieldArrayState<LandsideEntry>>();
  final _buildingEnvironmentKey =
      GlobalKey<FormFieldArrayState<LandsideEntry>>();

  final FocusNode _nationalHourFocus = FocusNode();
  final FocusNode _internationalHourFocus = FocusNode();
  final FocusNode _buildingHourFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    _setupAutoSaveField(
      'earthside_national_hour',
      _nationalHourController,
      _nationalHourFocus,
    );

    _setupAutoSaveField(
      'earthside_international_hour',
      _internationalHourController,
      _internationalHourFocus,
    );

    _setupAutoSaveField(
      'earthside_international_building_hour',
      _buildingHourController,
      _buildingHourFocus,
    );
  }

  void _setupAutoSaveField(String field, TextEditingController c, FocusNode f) {
    f.addListener(() {
      debugPrint(
          '[FOCUS] $field hasFocus=${f.hasFocus} ctxAttached=${f.context != null}');
      if (!f.hasFocus) {
        ref
            .read(autoSaveServiceProvider)
            .saveField(field: field, value: c.text, onSave: _saveField);
      }
    });
  }

  @override
  void dispose() {
    _nationalHourController.dispose();
    _internationalHourController.dispose();
    _buildingHourController.dispose();
    _nationalHourFocus.dispose();
    _internationalHourFocus.dispose();
    _buildingHourFocus.dispose();
    super.dispose();
  }

  Map<String, dynamic> getData() {
    return {
      'earthside_national_hour': _nationalHourController.text,
      'earthside_international_hour': _internationalHourController.text,
      'earthside_international_building_hour': _buildingHourController.text
    };
  }

  void setData(Landside data) {
    _nationalQualityKey.currentState
        ?.setData(data.earthsideNationalQuality ?? []);
    _nationalSecurityKey.currentState
        ?.setData(data.earthsideNationalSecurity ?? []);
    _nationalEnvironmentKey.currentState
        ?.setData(data.earthsideNationalEnvironment ?? []);

    _internationalQualityKey.currentState
        ?.setData(data.earthsideInternationalQuality ?? []);
    _internationalSecurityKey.currentState
        ?.setData(data.earthsideInternationalSecurity ?? []);
    _internationalEnvironmentKey.currentState
        ?.setData(data.earthsideInternationalEnvironment ?? []);

    _buildingQualityKey.currentState
        ?.setData(data.earthsideInternationalBuildingQuality ?? []);
    _buildingSecurityKey.currentState
        ?.setData(data.earthsideInternationalBuildingSecurity ?? []);
    _buildingEnvironmentKey.currentState
        ?.setData(data.earthsideInternationalBuildingEnvironment ?? []);
  }

  /*Future<void> _saveField(String field, dynamic value) async {
    final inspection = ref.read(inspectionDetailsProvider);
    if (inspection == null) return;
    final updated = inspection.copyWithField(field, value);
    await ref.read(cargoServiceProvider).saveCargo(updated as Cargo);
    //ref.read(inspectionDetailsProvider.notifier).setInspectionDetails(updated);
  }*/

  Future<void> _saveField(String field, dynamic value) async {
    if (_cargoId == null) return;
    final service = ref.read(cargoServiceProvider);

    // Carga por ID (no por inspection_id)
    final cargo = await service.getCargoById(_cargoId!);
    if (cargo == null) return;

    final updated = cargo.copyWithField(field, value);
    await service.saveCargo(updated);
    debugPrint('[SAVED] id=${updated.id} $field=$value');
  }

  Widget _buildGroup(
    String title,
    GlobalKey<FormFieldArrayState<LandsideEntry>> key,
    List<LandsideEntry> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        FormFieldArray<LandsideEntry>(
          key: key,
          initialValue: items,
          itemBuilder: (ctx, entry, idx) => CriteriaLineCard(
            key: ValueKey('${entry.id ?? 'new'}-$idx'),
            criteria: entry,
            onChanged: (updated) async {
              if (_cargoId == null) return;
              final service = ref.read(cargoServiceProvider);
              await service.saveLandside([updated as LandsideEntry], _cargoId!);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _selectTime(
      String field, TextEditingController controller) async {
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
      await ref.read(autoSaveServiceProvider).saveField(
            field: field,
            value: controller.text,
            onSave: _saveField,
          );
    }
  }

  Future<void> _loadDataFromSQLite(int inspectionId) async {
    if (!mounted) return;
    final service = ref.read(cargoServiceProvider);
    Cargo? cargo = await service.loadCargoForInspection(inspectionId);
    if (cargo == null) return;
    _cargoId = cargo.id; // guardar cargoId para autosave puntual

    final List<LandsideEntry>? list =
        await service.loadLandsideForCargo(cargo.id!);
    setState(() {
      _nationalHourController.text = cargo.earthsideNationalHour ?? '';
      _internationalHourController.text =
          cargo.earthsideInternationalHour ?? '';
      _buildingHourController.text =
          cargo.earthsideInternationalBuildingHour ?? '';
      //if (list != null && list.isNotEmpty) {
      //final landside = Landside.fromEntries(list);
      final landside = Landside.fromEntries(list ?? []);
      _landsideDetail = landside;
      setData(landside);
      //}
    });

    debugPrint('[LOAD] id=${cargo.id} nat=${cargo.earthsideNationalHour} '
        'intl=${cargo.earthsideInternationalHour} '
        'bld=${cargo.earthsideInternationalBuildingHour}');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.inspection.id == null || widget.inspection.id == 0) {
      return const Scaffold(body: Center(child: Text("No existen datos")));
    }
    if (!_dataLoaded) {
      _dataLoaded = true;
      Future.microtask(() => _loadDataFromSQLite(widget.inspection.id!));
    }

    if (_landsideDetail == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else {
      return SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildEditableField(
                        label: 'Hora nacional',
                        field: 'earthside_national_hour',
                        readOnly: true,
                        controller: _nationalHourController,
                        focusNode: _nationalHourFocus,
                        onTap: () async {
                          _nationalHourFocus.requestFocus();
                          await _selectTime('earthside_national_hour',
                              _nationalHourController);
                          _nationalHourFocus.unfocus();
                        },
                        suffixIcon: const Icon(Icons.access_time),
                      ),
                      _buildGroup('Calidad (Nacional)', _nationalQualityKey,
                          _landsideDetail?.earthsideNationalQuality ?? []),
                      _buildGroup('Seguridad (Nacional)', _nationalSecurityKey,
                          _landsideDetail?.earthsideNationalSecurity ?? []),
                      _buildGroup(
                          'Medio-ambiente (Nacional)',
                          _nationalEnvironmentKey,
                          _landsideDetail?.earthsideNationalEnvironment ?? []),
                      buildEditableField(
                        label: 'Hora internacional',
                        field: 'earthside_international_hour',
                        controller: _internationalHourController,
                        readOnly: true,
                        focusNode: _internationalHourFocus,
                        onTap: () => _selectTime('earthside_international_hour',
                            _internationalHourController),
                        suffixIcon: const Icon(Icons.access_time),
                      ),
                      _buildGroup(
                          'Calidad (Internacional)',
                          _internationalQualityKey,
                          _landsideDetail?.earthsideInternationalQuality ?? []),
                      _buildGroup(
                          'Seguridad (Internacional)',
                          _internationalSecurityKey,
                          _landsideDetail?.earthsideInternationalSecurity ??
                              []),
                      _buildGroup(
                          'Medio-ambiente (Internacional)',
                          _internationalEnvironmentKey,
                          _landsideDetail?.earthsideInternationalEnvironment ??
                              []),
                      buildEditableField(
                        label: 'Hora edificio internacional',
                        field: 'earthside_international_building_hour',
                        controller: _buildingHourController,
                        readOnly: true,
                        focusNode: _buildingHourFocus,
                        onTap: () => _selectTime(
                            'earthside_international_building_hour',
                            _buildingHourController),
                        suffixIcon: const Icon(Icons.access_time),
                      ),
                      _buildGroup(
                          'Calidad (Edificio Int.)',
                          _buildingQualityKey,
                          _landsideDetail
                                  ?.earthsideInternationalBuildingQuality ??
                              []),
                      _buildGroup(
                          'Seguridad (Edificio Int.)',
                          _buildingSecurityKey,
                          _landsideDetail
                                  ?.earthsideInternationalBuildingSecurity ??
                              []),
                      _buildGroup(
                          'Medio-ambiente (Edificio Int.)',
                          _buildingEnvironmentKey,
                          _landsideDetail
                                  ?.earthsideInternationalBuildingEnvironment ??
                              []),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}
