import 'package:epmsa_mobile/core/presentation/fields.dart';
import 'package:epmsa_mobile/core/providers/auto_save_provider.dart';
import 'package:epmsa_mobile/features/inspections/header/providers/inspections_providers.dart';
import 'package:epmsa_mobile/features/inspections/shared/providers/arrivals_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/baggage_time_data.dart';

class ArrivalBaggageTimeForm extends StatefulWidget {
  final TextEditingController flightController;
  final TextEditingController originController;
  final TextEditingController hourAController;
  final TextEditingController hourBController;
  //final TextEditingController diffBAController;
  final TextEditingController beltController;
  final TextEditingController hourCController;
  final TextEditingController hourDController;
  final TextEditingController hourEController;
  //final TextEditingController diffDCController;
  // final TextEditingController diffEDController;
  //final TextEditingController ndsTimeController;

  final int arrivalId; // national_arrival_id (padre)
  final WidgetRef ref;
  final int? id; // id de arrival_baggage_time_details (detalle)

  const ArrivalBaggageTimeForm({
    super.key,
    required this.id,
    required this.arrivalId,
    required this.ref,
    required this.flightController,
    required this.originController,
    required this.hourAController,
    required this.hourBController,
    //required this.diffBAController,
    required this.beltController,
    required this.hourCController,
    required this.hourDController,
    required this.hourEController,
    /*required this.diffDCController,
    required this.diffEDController,
    required this.ndsTimeController,*/
  });

  @override
  State<ArrivalBaggageTimeForm> createState() => _ArrivalBaggageTimeFormState();
}

class _ArrivalBaggageTimeFormState extends State<ArrivalBaggageTimeForm> {
  // FocusNodes estables por campo
  late final FocusNode _fnFlight;
  late final FocusNode _fnOrigin;
  late final FocusNode _fnHourA;
  late final FocusNode _fnHourB;
  late final FocusNode _fnBelt;
  late final FocusNode _fnHourC;
  late final FocusNode _fnHourD;
  late final FocusNode _fnHourE;

  @override
  void initState() {
    super.initState();

    _fnFlight = FocusNode();
    _fnOrigin = FocusNode();
    _fnHourA = FocusNode();
    _fnHourB = FocusNode();
    _fnBelt = FocusNode();
    _fnHourC = FocusNode();
    _fnHourD = FocusNode();
    _fnHourE = FocusNode();

    // Registra listeners UNA sola vez
    _setupAutoSaveField('flight_number', widget.flightController, _fnFlight);
    _setupAutoSaveField('origin', widget.originController, _fnOrigin);
    _setupAutoSaveField(
        'scheduled_time_a_hhmm', widget.hourAController, _fnHourA);
    _setupAutoSaveField(
        'arrival_time_b_hhmm', widget.hourBController, _fnHourB);
    _setupAutoSaveField('assigned_belt', widget.beltController, _fnBelt);
    _setupAutoSaveField(
        'first_pax_arrival_c_hhmm', widget.hourCController, _fnHourC);
    _setupAutoSaveField(
        'first_bag_arrival_d_hhmm', widget.hourDController, _fnHourD);
    _setupAutoSaveField(
        'last_bag_arrival_e_hhmm', widget.hourEController, _fnHourE);
  }

  @override
  void dispose() {
    _fnFlight.dispose();
    _fnOrigin.dispose();
    _fnHourA.dispose();
    _fnHourB.dispose();
    _fnBelt.dispose();
    _fnHourC.dispose();
    _fnHourD.dispose();
    _fnHourE.dispose();
    super.dispose();
  }

  // ─────────── Autosave hacia tabla detalle (NACIONAL) ───────────

  void _setupAutoSaveField(
    String field,
    TextEditingController controller,
    FocusNode focusNode,
  ) {
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        widget.ref.read(autoSaveServiceProvider).saveField(
              field: field,
              value: controller.text,
              onSave: _saveField,
            );
      }
    });
  }

  Future<void> _saveField(String field, dynamic value) async {
    final String v = (value is String) ? value : (value?.toString() ?? '');

    // Campos de arrival_baggage_time_details
    const baggageFields = <String>{
      'flight_number',
      'origin',
      'scheduled_time_a_hhmm',
      'arrival_time_b_hhmm',
      'assigned_belt',
      'first_pax_arrival_c_hhmm',
      'first_bag_arrival_d_hhmm',
      'last_bag_arrival_e_hhmm',
      // 'diff_ba','diff_dc','diff_ed','nds_time_function',
    };

    if (!baggageFields.contains(field)) {
      //debugPrint('ℹ️ Campo no-baggage ignorado en este form: $field');
      return;
    }

    if (widget.id == null || widget.id == 0 || widget.arrivalId == 0) {
      debugPrint('⚠️ id (detalle) null/0; no se puede guardar baggage.');
      return;
    }

    final partial = BaggageTimeData(id: widget.id).copyWithField(field, v);

    final baggageService = widget.ref.read(baggageServiceProvider);
    await baggageService.saveNationalArrivalBaggageField(
      widget.arrivalId,
      widget.id!,
      partial,
    );

    debugPrint(
        '💾 [BAGGAGE-NAT] $field = $v (arrival=${widget.arrivalId}, id=${widget.id})');
  }

  void _triggerAutoSave(String field, TextEditingController controller) {
    widget.ref.read(autoSaveServiceProvider).saveField(
          field: field,
          value: controller.text,
          onSave: _saveField,
        );
  }

  Future<void> _selectTime(BuildContext context, String field,
      TextEditingController controller) async {
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
      _triggerAutoSave(field, controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildEditableField(
          label: 'Nro. vuelo',
          field: 'flight_number',
          controller: widget.flightController,
          focusNode: _fnFlight,
          keyboardType: TextInputType.number,
          //setupAutoSaveField: _setupAutoSaveField,
        ),
        const SizedBox(height: 16),
        buildEditableField(
          label: 'Origen',
          field: 'origin',
          controller: widget.originController,
          focusNode: _fnOrigin,
          //setupAutoSaveField: _setupAutoSaveField,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: buildEditableField(
                label: 'Hora itinerario (A)',
                field: 'scheduled_time_a_hhmm',
                controller: widget.hourAController,
                focusNode: _fnHourA,
                onTap: () => _selectTime(
                    context, 'scheduled_time_a_hhmm', widget.hourAController),
                suffixIcon: const Icon(Icons.access_time),
                //setupAutoSaveField: _setupAutoSaveField,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildEditableField(
                label: 'Hora arribo (B)',
                field: 'arrival_time_b_hhmm',
                controller: widget.hourBController,
                focusNode: _fnHourB,
                onTap: () => _selectTime(
                    context, 'arrival_time_b_hhmm', widget.hourBController),
                suffixIcon: const Icon(Icons.access_time),
                //setupAutoSaveField: _setupAutoSaveField,
              ),
            ),
          ],
        ),
        /*const SizedBox(height: 16),
        buildLabelField('Diferencia B - A', widget.diffBAController),*/
        const SizedBox(height: 16),
        buildEditableField(
          label: 'Banda asignada',
          field: 'assigned_belt',
          controller: widget.beltController,
          focusNode: _fnBelt,
          keyboardType: TextInputType.number,
          //setupAutoSaveField: _setupAutoSaveField,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: buildEditableField(
                label: 'Hora 1ra persona (C)',
                field: 'first_pax_arrival_c_hhmm',
                controller: widget.hourCController,
                focusNode: _fnHourC,
                onTap: () => _selectTime(context, 'first_pax_arrival_c_hhmm',
                    widget.hourCController),
                suffixIcon: const Icon(Icons.access_time),
                //setupAutoSaveField: _setupAutoSaveField,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildEditableField(
                label: 'Hora 1ra maleta (D)',
                field: 'first_bag_arrival_d_hhmm',
                controller: widget.hourDController,
                focusNode: _fnHourD,
                onTap: () => _selectTime(context, 'first_bag_arrival_d_hhmm',
                    widget.hourDController),
                suffixIcon: const Icon(Icons.access_time),
                //setupAutoSaveField: _setupAutoSaveField,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: buildEditableField(
                label: 'Hora última maleta (E)',
                field: 'last_bag_arrival_e_hhmm',
                controller: widget.hourEController,
                focusNode: _fnHourE,
                onTap: () => _selectTime(
                    context, 'last_bag_arrival_e_hhmm', widget.hourEController),
                suffixIcon: const Icon(Icons.access_time),
                //setupAutoSaveField: _setupAutoSaveField,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ArrivalsBaggageTimeScreen extends ConsumerStatefulWidget {
  const ArrivalsBaggageTimeScreen({super.key});

  @override
  ConsumerState<ArrivalsBaggageTimeScreen> createState() =>
      ArrivalsBaggageTimeScreenState();
}

class ArrivalsBaggageTimeScreenState
    extends ConsumerState<ArrivalsBaggageTimeScreen> {
  final List<Map<String, TextEditingController>> _controllersList = [];
  int? _expandedIndex;
  bool _dataLoaded = false;
  bool _isLoading = false;
  int? _loadedForId;

  Future<void> _loadData(arrivalId) async {
    if (_loadedForId == arrivalId) return; // evita recargas por el mismo id
    setState(() => _isLoading = true);
    final service = ref.read(baggageServiceProvider);
    final result =
        await service.loadBaggageTimeDataforNationalArrival(arrivalId!);

    _controllersList.clear();

    for (var record in result) {
      _controllersList.add({
        'id': TextEditingController(text: record.id?.toString() ?? ''),
        'flight': TextEditingController(text: record.flightNumber ?? ''),
        'origin': TextEditingController(text: record.origin ?? ''),
        'hourA': TextEditingController(text: record.scheduledTimeA),
        'hourB': TextEditingController(text: record.arrivalTimeB),
        //'diffBA': TextEditingController(text: record.diffBA),
        'belt':
            TextEditingController(text: record.assignedBelt?.toString() ?? ''),
        'hourC': TextEditingController(text: record.firstPaxTimeC),
        'hourD': TextEditingController(text: record.firstBagTimeD),
        'hourE': TextEditingController(text: record.lastBagTimeE),
        //'diffDC': TextEditingController(text: record.diffDC),
        //'diffED': TextEditingController(text: record.diffED),
        //'ndsTime': TextEditingController(text: record.ndsTimeFunction)
      });
    }

    setState(() {
      _expandedIndex = _controllersList.isNotEmpty ? 0 : null;
      _loadedForId = arrivalId;
      _isLoading = false;
    });
  }

  /*void _addNewForm() {
    setState(() {
      _controllersList.add({
        'id': TextEditingController(),
        'flight': TextEditingController(),
        'origin': TextEditingController(),
        'hourA': TextEditingController(),
        'hourB': TextEditingController(),
        //'diffBA': TextEditingController(),
        'belt': TextEditingController(),
        'hourC': TextEditingController(),
        'hourD': TextEditingController(),
        'hourE': TextEditingController(),
        //'diffDC': TextEditingController(),
        //'diffED': TextEditingController(),
        //'ndsTime': TextEditingController(),
      });
      _expandedIndex = _controllersList.length - 1;
    });
  }*/

  @override
  Widget build(BuildContext context) {
    final inspection = ref.watch(inspectionDetailsProvider);

    if (inspection == null || inspection.id == null || inspection.id == 0) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadedForId != inspection.id && !_isLoading) {
      setState(() => _isLoading = true);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _loadData(inspection.id!);
      });
    }

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                ExpansionPanelList.radio(
                  expandedHeaderPadding: EdgeInsets.zero,
                  initialOpenPanelValue: _expandedIndex,
                  children: List.generate(_controllersList.length, (index) {
                    final c = _controllersList[index];
                    return ExpansionPanelRadio(
                      value: index,
                      headerBuilder: (context, isExpanded) => ListTile(
                        title: Text('${c['flight']?.text}'),
                        textColor: Colors.blue,
                      ),
                      body: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ArrivalBaggageTimeForm(
                          arrivalId:
                              ref.read(inspectionDetailsProvider)?.id ?? 0,
                          id: int.tryParse(c['id']?.text ?? '0'),
                          ref: ref,
                          flightController: c['flight']!,
                          originController: c['origin']!,
                          hourAController: c['hourA']!,
                          hourBController: c['hourB']!,
                          //diffBAController: c['diffBA']!,
                          beltController: c['belt']!,
                          hourCController: c['hourC']!,
                          hourDController: c['hourD']!,
                          hourEController: c['hourE']!,
                          //diffDCController: c['diffDC']!,
                          //diffEDController: c['diffED']!,
                          //ndsTimeController: c['ndsTime']!,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
