import 'package:epmsa_mobile/core/presentation/criteria_line_card.dart';
import 'package:epmsa_mobile/core/presentation/fields.dart';
import 'package:epmsa_mobile/core/presentation/form_field_array.dart';
import 'package:epmsa_mobile/core/providers/auto_save_provider.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/cargo.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/airside.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/airside_entry.dart';
import 'package:epmsa_mobile/features/inspections/cargo/providers/cargo_provider.dart';
import 'package:epmsa_mobile/features/inspections/header/domain/Inspection.dart';
import 'package:epmsa_mobile/features/inspections/header/providers/inspections_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CargoAirsideScreen extends ConsumerStatefulWidget {
  final Inspection inspection;
  const CargoAirsideScreen({super.key, required this.inspection});

  @override
  CargoAirsideScreenState createState() => CargoAirsideScreenState();
}

class CargoAirsideScreenState extends ConsumerState<CargoAirsideScreen> {
  bool _dataLoaded = false;
  Airside? _airsideDetail;
  int? _cargoId; // para autosave puntual por ítem

  // Hora lado aire
  final TextEditingController _airsideHourController = TextEditingController();
  final FocusNode _airsideHourFocus = FocusNode();

  // Keys para listas
  final _qualityKey = GlobalKey<FormFieldArrayState<AirsideEntry>>();
  final _securityKey = GlobalKey<FormFieldArrayState<AirsideEntry>>();
  final _environmentKey = GlobalKey<FormFieldArrayState<AirsideEntry>>();

  @override
  void initState() {
    super.initState();

    _setupAutoSaveField(
      'airside_national_international_hour',
      _airsideHourController,
      _airsideHourFocus,
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

  @override
  void dispose() {
    _airsideHourController.dispose();
    // _airsideHourFocus.dispose();
    super.dispose();
  }

  Map<String, dynamic> getData() {
    return {
      'airside_national_international_hour': _airsideHourController.text,
    };
  }

  void setData(Airside data) {
    _qualityKey.currentState?.setData(data.quality ?? []);
    _securityKey.currentState?.setData(data.security ?? []);
    _environmentKey.currentState?.setData(data.environment ?? []);
  }

  Future<void> _saveField(String field, dynamic value) async {
    if (_cargoId == null) return;
    final service = ref.read(cargoServiceProvider);

    final cargo = await service.loadCargoForInspection(widget.inspection.id!);
    if (cargo == null) return;

    final updated = cargo.copyWithField(field, value);
    await service.saveCargo(updated);
  }

  Widget _buildGroup(
    String title,
    GlobalKey<FormFieldArrayState<AirsideEntry>> key,
    List<AirsideEntry> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        FormFieldArray<AirsideEntry>(
          key: key,
          initialValue: items,
          itemBuilder: (ctx, entry, idx) => CriteriaLineCard(
            key: ValueKey(entry.id),
            criteria: entry,
            onChanged: (updated) async {
              if (_cargoId == null) return;
              final service = ref.read(cargoServiceProvider);
              await service.saveAirside([updated as AirsideEntry], _cargoId!);
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  String _formatHHmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

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
    debugPrint("CARGO: ${cargo?.id}");
    if (cargo == null) return;
    _cargoId = cargo.id; // guardar cargoId para autosave por ítem

    final List<AirsideEntry>? list =
        await service.loadAirsideForCargo(cargo.id!);

    setState(() {
      _airsideHourController.text =
          cargo.airsideNationalInternationalHour ?? '';
      if (list != null && list.isNotEmpty) {
        debugPrint('🛫 Airside (${list.length} filas) para cargo ${cargo.id}:');
        for (final e in list) {
          debugPrint(
              '  • id=${e.id}  parent=${e.parent}  seq=${e.sequence}  name=${e.name}');
        }
        final airside = Airside.fromEntries(list);
        _airsideDetail = airside;
        setData(airside);
      } else {
        _airsideDetail = Airside(quality: [], security: [], environment: []);
        setData(_airsideDetail!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.inspection.id == null || widget.inspection.id == 0) {
      return const Scaffold(
        body: Center(child: Text("No existen datos")),
      );
    }

    if (!_dataLoaded) {
      _dataLoaded = true;
      Future.microtask(() => _loadDataFromSQLite(widget.inspection.id!));
    }

    if (_airsideDetail == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      buildEditableField(
                        label: 'Hora lado aire',
                        field: 'airside_national_international_hour',
                        readOnly: true,
                        controller: _airsideHourController,
                        focusNode: _airsideHourFocus,
                        onTap: () => _selectTime(
                            'airside_national_international_hour',
                            _airsideHourController),
                        suffixIcon: const Icon(Icons.access_time),
                      ),
                      _buildGroup('Calidad', _qualityKey,
                          _airsideDetail?.quality ?? []),
                      _buildGroup('Seguridad', _securityKey,
                          _airsideDetail?.security ?? []),
                      _buildGroup('Medio-ambiente', _environmentKey,
                          _airsideDetail?.environment ?? []),
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
