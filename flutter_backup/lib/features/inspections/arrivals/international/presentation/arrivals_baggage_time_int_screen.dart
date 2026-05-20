import 'package:epmsa_mobile/core/presentation/fields.dart';
import 'package:epmsa_mobile/core/providers/auto_save_provider.dart';
import 'package:epmsa_mobile/features/inspections/header/providers/inspections_providers.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/baggage_time_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/providers/arrivals_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ArrivalsBaggageTimeInternationalScreen extends ConsumerStatefulWidget {
  const ArrivalsBaggageTimeInternationalScreen({super.key});

  @override
  ConsumerState<ArrivalsBaggageTimeInternationalScreen> createState() =>
      ArrivalsBaggageTimeInternationalScreenState();
}

class ArrivalsBaggageTimeInternationalScreenState
    extends ConsumerState<ArrivalsBaggageTimeInternationalScreen> {
  int selectedFlightIndex = 0;
  List<String> flightNumbers = [];
  List<BaggageTimeData> _dataList = [];

  @override
  void initState() {
    super.initState();

    // Registrar autosave UNA sola vez por campo (DB keys válidas)
    _setupAutosaveField(
      'origin',
      controllers['origin']!,
      focusNodes['origin']!,
    );
    _setupAutosaveField(
      'scheduled_time_a_hhmm',
      controllers['scheduled_time_a_hhmm']!,
      focusNodes['scheduled_time_a_hhmm']!,
    );
    _setupAutosaveField(
      'arrival_time_b_hhmm',
      controllers['arrival_time_b_hhmm']!,
      focusNodes['arrival_time_b_hhmm']!,
    );
    _setupAutosaveField(
      'assigned_belt',
      controllers['assigned_belt']!,
      focusNodes['assigned_belt']!,
    );
    _setupAutosaveField(
      'first_pax_arrival_c_hhmm',
      controllers['first_pax_arrival_c_hhmm']!,
      focusNodes['first_pax_arrival_c_hhmm']!,
    );
    _setupAutosaveField(
      'first_bag_arrival_d_hhmm',
      controllers['first_bag_arrival_d_hhmm']!,
      focusNodes['first_bag_arrival_d_hhmm']!,
    );
    _setupAutosaveField(
      'last_bag_arrival_e_hhmm',
      controllers['last_bag_arrival_e_hhmm']!,
      focusNodes['last_bag_arrival_e_hhmm']!,
    );
  }

  // ✅ Keys alineadas a DB/JSON
  final Map<String, TextEditingController> controllers = {
    'scheduled_time_a_hhmm': TextEditingController(),
    'arrival_time_b_hhmm': TextEditingController(),
    //'diff_ba': TextEditingController(),
    'assigned_belt': TextEditingController(),
    'first_pax_arrival_c_hhmm': TextEditingController(),
    'first_bag_arrival_d_hhmm': TextEditingController(),
    'last_bag_arrival_e_hhmm': TextEditingController(),
    /*'diff_dc': TextEditingController(),
    'diff_ed': TextEditingController(),*/
    //'nds_time_function': TextEditingController(),
    'origin': TextEditingController(),
    'gate_position': TextEditingController(),
  };

  final Map<String, FocusNode> focusNodes = {
    'scheduled_time_a_hhmm': FocusNode(),
    'arrival_time_b_hhmm': FocusNode(),
    //'diff_ba': FocusNode(),
    'assigned_belt': FocusNode(),
    'first_pax_arrival_c_hhmm': FocusNode(),
    'first_bag_arrival_d_hhmm': FocusNode(),
    'last_bag_arrival_e_hhmm': FocusNode(),
    //'diff_dc': FocusNode(),
    //'diff_ed': FocusNode(),
    //'nds_time_function': FocusNode(),
    'origin': FocusNode(),
    'gate_position': FocusNode(),
  };

  bool _dataLoaded = false;

  // 🆕 detailId de la fila activa (del dropdown)
  int? _currentDetailId;

  /*Future<void> _selectTime(TextEditingController controller) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      controller.text = picked.format(context);
    }
  }*/

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
    final arrival = ref.watch(inspectionDetailsProvider);

    if (arrival == null || arrival.id == null || arrival.id == 0) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_dataLoaded) {
      _dataLoaded = true;
      Future.microtask(() => _loadDataFromSQLite(arrival.id!));
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Retiro de equipaje/ Nds ADRM 10ma - 11ra - 12da ed. (TIEMPO)",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                DropdownButton<int>(
                  value: selectedFlightIndex < flightNumbers.length
                      ? selectedFlightIndex
                      : null,
                  hint: const Text('Selecciona un vuelo'),
                  onChanged: (value) {
                    if (value == null || value >= flightNumbers.length) return;
                    setState(() {
                      selectedFlightIndex = value;
                    });
                    _loadDataFromIndex(value);
                  },
                  items: flightNumbers.asMap().entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: buildEditableField(
                      label: 'Procedencia del vuelo',
                      field: 'origin',
                      controller: controllers['origin']!,
                      focusNode: focusNodes['origin']!,
                      onTap: _captureCurrentDetailId,
                      //setupAutoSaveField: _setupAutosaveField,
                    ),
                  ),
                  const SizedBox(width: 12),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: buildEditableField(
                      label: 'Hora Programada A',
                      field: 'scheduled_time_a_hhmm',
                      controller: controllers['scheduled_time_a_hhmm']!,
                      focusNode: focusNodes['scheduled_time_a_hhmm']!,
                      suffixIcon: const Icon(Icons.access_time),
                      onTap: () {
                        _captureCurrentDetailId();
                        _selectTime(controllers['scheduled_time_a_hhmm']!);
                      },
                      //setupAutoSaveField: _setupAutosaveField,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildEditableField(
                      label: 'Hora Llegada B',
                      field: 'arrival_time_b_hhmm',
                      controller: controllers['arrival_time_b_hhmm']!,
                      focusNode: focusNodes['arrival_time_b_hhmm']!,
                      suffixIcon: const Icon(Icons.access_time),
                      onTap: () {
                        _captureCurrentDetailId();
                        _selectTime(controllers['arrival_time_b_hhmm']!);
                      },
                      //setupAutoSaveField: _setupAutosaveField,
                    ),
                  ),
                ]),
                buildEditableField(
                  label: 'Banda Asignada',
                  field: 'assigned_belt',
                  controller: controllers['assigned_belt']!,
                  focusNode: focusNodes['assigned_belt']!,
                  onTap: _captureCurrentDetailId,
                  //setupAutoSaveField: _setupAutosaveField,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: false),
                ),
                Row(children: [
                  Expanded(
                    child: buildEditableField(
                      label: 'Hora Primer PAX C',
                      field: 'first_pax_arrival_c_hhmm',
                      controller: controllers['first_pax_arrival_c_hhmm']!,
                      focusNode: focusNodes['first_pax_arrival_c_hhmm']!,
                      suffixIcon: const Icon(Icons.access_time),
                      onTap: () {
                        _captureCurrentDetailId();
                        _selectTime(controllers['first_pax_arrival_c_hhmm']!);
                      },
                      //setupAutoSaveField: _setupAutosaveField,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildEditableField(
                      label: 'Hora Primera Maleta D',
                      field: 'first_bag_arrival_d_hhmm',
                      controller: controllers['first_bag_arrival_d_hhmm']!,
                      focusNode: focusNodes['first_bag_arrival_d_hhmm']!,
                      suffixIcon: const Icon(Icons.access_time),
                      onTap: () {
                        _captureCurrentDetailId();
                        _selectTime(controllers['first_bag_arrival_d_hhmm']!);
                      },
                      //setupAutoSaveField: _setupAutosaveField,
                    ),
                  ),
                ]),
                Row(children: [
                  Expanded(
                    flex: 1,
                    child: buildEditableField(
                      label: 'Hora Última Maleta E',
                      field: 'last_bag_arrival_e_hhmm',
                      controller: controllers['last_bag_arrival_e_hhmm']!,
                      focusNode: focusNodes['last_bag_arrival_e_hhmm']!,
                      suffixIcon: const Icon(Icons.access_time),
                      onTap: () {
                        _captureCurrentDetailId();
                        _selectTime(controllers['last_bag_arrival_e_hhmm']!);
                      },
                      //setupAutoSaveField: _setupAutosaveField,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Spacer(flex: 1),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadDataFromSQLite(int arrivalId) async {
    final service = ref.read(baggageServiceProvider);
    final result =
        await service.loadBaggageTimeDataforInternationalArrival(arrivalId);

    _dataList = result;
    flightNumbers = result.map((e) => e.flightNumber ?? 'Vuelo').toList();

    if (_dataList.isNotEmpty) {
      setState(() {
        selectedFlightIndex = 0;
      });
      _loadData(_dataList[0]);
    } else {
      _clearControllers();
      _currentDetailId = null;
    }
  }

  void _clearControllers() {
    for (final c in controllers.values) {
      c.text = '';
    }
  }

  void _loadData(BaggageTimeData data) {
    // Modelo → UI (DB keys)
    controllers['scheduled_time_a_hhmm']!.text = data.scheduledTimeA ?? '';
    controllers['arrival_time_b_hhmm']!.text = data.arrivalTimeB ?? '';
    controllers['assigned_belt']!.text = data.assignedBelt ?? '';
    controllers['first_pax_arrival_c_hhmm']!.text = data.firstPaxTimeC ?? '';
    controllers['first_bag_arrival_d_hhmm']!.text = data.firstBagTimeD ?? '';
    controllers['last_bag_arrival_e_hhmm']!.text = data.lastBagTimeE ?? '';
    controllers['origin']!.text = data.origin ?? '';
    // controllers['gate_position']!.text = data.gatePosition ?? '';

    // id de la fila activa
    _currentDetailId = data.id;
  }

  void _loadDataFromIndex(int index) {
    if (_dataList.isEmpty || index >= _dataList.length) return;
    final data = _dataList[index];
    _loadData(data);
  }

  // Registra fila activa al tocar el campo (por si cambia la selección)
  void _captureCurrentDetailId() {
    if (selectedFlightIndex >= 0 && selectedFlightIndex < _dataList.length) {
      _currentDetailId = _dataList[selectedFlightIndex].id;
    }
  }

  void _setupAutosaveField(
    String field,
    TextEditingController controller,
    FocusNode focusNode,
  ) {
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        ref.read(autoSaveServiceProvider).saveField(
              field: field, // ← ya viene con la key de DB
              value: controller.text,
              onSave: _saveField,
            );
      }
    });
  }

  Future<void> _saveField(String field, dynamic value) async {
    // Solo guardamos campos de la tabla detalle
    const baggageFields = <String>{
      'flight_number',
      'origin',
      'scheduled_time_a_hhmm',
      'arrival_time_b_hhmm',
      'assigned_belt',
      'first_pax_arrival_c_hhmm',
      'first_bag_arrival_d_hhmm',
      'last_bag_arrival_e_hhmm',
    };
    if (!baggageFields.contains(field)) {
      debugPrint('ℹ️ Campo no-baggage ignorado (Intl): $field');
      return;
    }

    final String v = (value is String) ? value : (value?.toString() ?? '');

    // arrival (padre)
    final arrival = ref.read(inspectionDetailsProvider);
    final int? parentId = arrival?.id;
    if (parentId == null || parentId == 0) {
      debugPrint('⚠️ arrival vacío en baggage Intl.');
      return;
    }

    // detail id (fila activa)
    final int? detailId = _currentDetailId;
    if (detailId == null || detailId == 0) {
      debugPrint(
          '⚠️ _currentDetailId null/0 en Intl. Asegúrate de setearlo (onTap / load).');
      return;
    }

    // Guarda en baggage internacional
    final partial = BaggageTimeData(id: detailId).copyWithField(field, v);
    final baggageService = ref.read(baggageServiceProvider);

    await baggageService.saveInternationalArrivalBaggageField(
      parentId,
      detailId,
      partial,
    );

    // refresco local (opcional)
    if (selectedFlightIndex >= 0 && selectedFlightIndex < _dataList.length) {
      final row = _dataList[selectedFlightIndex];
      setState(() {
        _dataList[selectedFlightIndex] = row.copyWithField(field, v);
      });
    }

    debugPrint(
        '💾 [BAGGAGE-INT] $field = $v (arrival=$parentId, id=$detailId)');
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    for (final f in focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }
}
