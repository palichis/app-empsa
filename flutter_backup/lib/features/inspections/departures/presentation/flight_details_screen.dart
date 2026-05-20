import 'package:epmsa_mobile/core/presentation/fields.dart';
import 'package:epmsa_mobile/core/providers/auto_save_provider.dart';
import 'package:epmsa_mobile/features/inspections/departures/data/flight_preboarding_room.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/flight_check_counter_number.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/flight_data.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/flight_option.dart';
import 'package:epmsa_mobile/features/inspections/departures/national/domain/national_departures.dart';
import 'package:epmsa_mobile/features/inspections/departures/providers/depatures_provider.dart';
import 'package:epmsa_mobile/features/inspections/header/domain/Inspection.dart';
import 'package:epmsa_mobile/features/inspections/header/providers/inspections_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

class FlightDetailsScreen extends ConsumerStatefulWidget {
  final Inspection inspection;
  const FlightDetailsScreen({super.key, required this.inspection});

  @override
  ConsumerState<FlightDetailsScreen> createState() =>
      FlightDetailsScreenState();
}

class FlightDetailsScreenState extends ConsumerState<FlightDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _dataLoaded = false;
  List<bool> _counterSelections = [];
  List<bool> _preboardingSelections = [];
  List<FlightPreboardingRoom> _preboardingRooms = [];

  List<FlightOption> _flightOptions = [];
  FlightOption? _selectedOption;

  final _flightCountController = TextEditingController();
  final _passengerNumberController = TextEditingController();
  //final _flightNumberController = TextEditingController();
  final _destinyController = TextEditingController();
  //final _counterNumberController = TextEditingController();
  List<FlightCheckCounterNumber> _counterNumbers = [];
  //FlightCheckCounterNumber? _selectedCounter;
  final _preboardingRoomController = TextEditingController();
  final _scheduleTimeController = TextEditingController();
  final _realDepartureTimeController = TextEditingController();

  final _flightCountFocus = FocusNode();
  final _passengerNumberFocus = FocusNode();
  final _flightNumberFocus = FocusNode();
  final _destinyFocus = FocusNode();
  final _counterNumberFocus = FocusNode();
  final _preboardingRoomFocus = FocusNode();
  final _scheduleTimeFocus = FocusNode();
  final _realDepartureTimeFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    // Números
    _setupAutoSaveField(
      'flight_count',
      _flightCountController,
      _flightCountFocus,
    );
    _setupAutoSaveField(
      'flight_pax_number',
      _passengerNumberController,
      _passengerNumberFocus,
    );

    // Texto
    _setupAutoSaveField(
      'flight_destiny',
      _destinyController,
      _destinyFocus,
    );
    _setupAutoSaveField(
      'flight_preboarding_room',
      _preboardingRoomController,
      _preboardingRoomFocus,
    );

    // Horas (también guardan al seleccionar hora; aquí guardan al perder foco)
    _setupAutoSaveField(
      'flight_scheduled_time',
      _scheduleTimeController,
      _scheduleTimeFocus,
    );
    _setupAutoSaveField(
      'flight_actual_departure_time',
      _realDepartureTimeController,
      _realDepartureTimeFocus,
    );
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
    final inspection = ref.read(inspectionDetailsProvider);
    if (inspection == null) return;

    final updated = inspection.copyWithField(field, value);
    final service = ref.read(inspectionServiceSelectorProvider(updated));
    await service.save(updated);

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
      ref.read(autoSaveServiceProvider).saveField(
            field: field,
            value: controller.text,
            onSave: _saveField,
          );
    }
  }

 String convertTime(String time) {
    if (time.isNotEmpty) {
      try {
        final parts = time.split(':');
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        final timeOfDay = TimeOfDay(hour: hour, minute: minute);
        return timeOfDay.format(context); 
      } catch (_) {
        return TimeOfDay.now().toString();
      }
    } else {
      return TimeOfDay.now().toString();
    }
  }

  void _loadListsFromSQLite(int departureId, bool isNational) async {
    final svr = ref.read(flightDetailsServiceProvider);

    final opts = await svr.loadFlightOptions(
      departureId,
      isNational: isNational,
    );

    final cnts = await svr.loadFlightCounters(
      departureId,
      isNational: isNational,
    );

    final rooms = await svr.loadPreboardingRooms(
      departureId,
      isNational: isNational,
    );

    // 1) Busca si ya hay uno seleccionado
    FlightOption? sel = opts.firstWhereOrNull((o) => o.selected == 1);

    // 2) Si no hay, selecciona el primero y PERSISTE esa selección
    if (sel == null && opts.isNotEmpty) {
      sel = opts.first;

      await svr.markFlightOptionSelected(
        departureId: departureId,
        optionId: sel.id,
        isNational: isNational,
      );

      // Refleja el cambio en memoria
      for (final f in opts) {
        f.selected = f.id == sel.id ? 1 : 0;
      }
      // Actualiza destino y guárdalo porque onChanged no se disparó
      _destinyController.text = sel.destiny;
    _scheduleTimeController.text = sel.time;
      /*ref.read(autoSaveServiceProvider).saveField(
            field: 'flight_destiny',
            value: _destinyController.text,
            onSave: _saveField,
          );*/
    } else if (sel != null) {
      // Ya había uno seleccionado: sincroniza el destino
      _destinyController.text = sel.destiny;
      _scheduleTimeController.text = sel.time;
    }

    if (!mounted) return;
    setState(() {
      _flightOptions = opts;
      _counterNumbers = cnts;
      _preboardingRooms = rooms;

      _selectedOption = sel;
      _counterSelections = _counterNumbers.map((c) => c.selected == 1).toList();
      _preboardingSelections =
          _preboardingRooms.map((r) => r.selected == 1).toList();
    });
  }

  void setData(FlightData data) {
    _flightCountController.text = (data.flightCount ?? 0).toString();
    _passengerNumberController.text = (data.flightPaxNumber ?? 0).toString();
    // (_flightOptions.isNotEmpty ? _flightOptions.first : null);
    _destinyController.text = _selectedOption?.destiny ?? '';
    _scheduleTimeController.text = _selectedOption?.time?? '';
    //_preboardingRoomController.text = (_preboardingRooms ?? []).join(', ');
    _scheduleTimeController.text = data.flightScheduledTime ?? '';
    _realDepartureTimeController.text = data.flightActualDepartureTime ?? '';
  }

  Map<String, dynamic> getData() => {
        'flight_count': int.tryParse(_flightCountController.text) ?? 0,
        'flight_pax_number': int.tryParse(_passengerNumberController.text) ?? 0,
        'flight_number': _flightOptions.map((e) => e.toJson()).toList(),
        'flight_check_counter_number':
            _counterNumbers.map((e) => e.toJson()).toList(),
        'flight_preboarding_room': _preboardingRoomController.text,
        'flight_scheduled_time': _scheduleTimeController.text,
        'flight_actual_departure_time': _realDepartureTimeController.text,
      };

  bool validate() => _formKey.currentState?.validate() ?? false;

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(inspectionDetailsProvider);
    if (details == null) {
      return const Center(child: CircularProgressIndicator());
    } else {
      final belongs = details.inspectionId == widget.inspection.id;

      if (!belongs) {
        return const Center(child: CircularProgressIndicator());
      }
      bool isNational = details is NationalDepartures;
      if (!_dataLoaded) {
        _dataLoaded = true;
        Future.microtask(() => _loadListsFromSQLite(
              details.id!,
              isNational,
            ));
      }
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Detalles del vuelo',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                        child: buildEditableField(
                          label: 'Nro de vuelos',
                          field: 'flight_count',
                          controller: _flightCountController,
                          focusNode: _flightCountFocus,
                          keyboardType: TextInputType.number,
                          //setupAutoSaveField: _setupAutoSaveField,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: buildEditableField(
                          label: 'Nro de pasajeros',
                          field: 'flight_pax_number',
                          controller: _passengerNumberController,
                          focusNode: _passengerNumberFocus,
                          keyboardType: TextInputType.number,
                          //setupAutoSaveField: _setupAutoSaveField,
                        ),
                      )
                    ]),
                    /*buildEditableField(
                    label: 'Vuelo',
                    field: 'flight_number',
                    controller: _flightNumberController,
                    focusNode: _flightNumberFocus,
                    //setupAutoSaveField: _setupAutoSaveField,
                  ),*/
                    DropdownButtonFormField<FlightOption>(
                      value: _selectedOption, // ⇦ opción actual
                      items: _flightOptions
                          .map((o) => DropdownMenuItem(
                                value: o,
                                child: Text(o.name),
                              ))
                          .toList(),
                      decoration: const InputDecoration(
                        labelText: 'Vuelo',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (opt) async {
                        if (opt == null) return;
                        final svr = ref.read(flightDetailsServiceProvider);
                        await svr.markFlightOptionSelected(
                            departureId: details.id!,
                            optionId: opt.id,
                            isNational: isNational);
                        setState(() {
                          _selectedOption = opt;
                          _destinyController.text = opt.destiny;
                          _scheduleTimeController.text = opt.time;
                          for (final f in _flightOptions) {
                            f.selected = f.id == opt.id ? 1 : 0;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    buildEditableField(
                      label: 'Destino del vuelo',
                      field: 'flight_destiny',
                      controller: _destinyController,
                      focusNode: _destinyFocus,
                      //setupAutoSaveField: _setupAutoSaveField,
                    ),
                    /*buildEditableField(
                    label: 'Número de mostrador',
                    field: 'flight_check_counter_number',
                    controller: _counterNumberController,
                    focusNode: _counterNumberFocus,
                    //setupAutoSaveField: _setupAutoSaveField,
                  ),*/
                    Text("Nro. de Counter"),
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
                                .read(flightDetailsServiceProvider)
                                .markCounterSelected(
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

                    //const SizedBox(height: 16),
                    /*buildEditableField(
                    label: 'Sala de pre‑embarque',
                    field: 'flight_preboarding_room',
                    controller: _preboardingRoomController,
                    focusNode: _preboardingRoomFocus,
                    //setupAutoSaveField: _setupAutoSaveField,
                  ),*/
                    Text("Sala de pre-embarque"),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          List.generate(_preboardingRooms.length, (index) {
                        final room = _preboardingRooms[index];
                        final selected = _preboardingSelections[index];

                        return ChoiceChip(
                          label: Text(
                            room.name,
                          ),
                          selected: selected,
                          selectedColor: Colors.blue,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : Colors.black,
                          ),
                          onSelected: (bool value) async {
                            await ref
                                .read(flightDetailsServiceProvider)
                                .markPreboardingSelected(
                                  departureId: details.id!,
                                  isNational: isNational,
                                  roomId: room.id,
                                  newValue: value,
                                );

                            setState(() {
                              _preboardingSelections[index] = value;
                              _preboardingRooms[index].selected = value ? 1 : 0;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    buildEditableField(
                      label: 'Hora itinerario',
                      field: 'flight_scheduled_time',
                      controller: _scheduleTimeController,
                      focusNode: _scheduleTimeFocus,
                      onTap: () => _selectTime(
                          _scheduleTimeController, 'flight_scheduled_time'),
                      suffixIcon: const Icon(Icons.access_time),
                    ),
                    buildEditableField(
                      label: 'Hora real de salida',
                      field: 'flight_actual_departure_time',
                      controller: _realDepartureTimeController,
                      focusNode: _realDepartureTimeFocus,
                      onTap: () => _selectTime(_realDepartureTimeController,
                          'flight_actual_departure_time'),
                      suffixIcon: const Icon(Icons.access_time),
                      //setupAutoSaveField: _setupAutoSaveField,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _flightCountController.dispose();
    _passengerNumberController.dispose();
    //_flightNumberController.dispose();
    _destinyController.dispose();
    //_counterNumberController.dispose();
    _preboardingRoomController.dispose();
    _scheduleTimeController.dispose();
    _realDepartureTimeController.dispose();

    _flightCountFocus.dispose();
    _passengerNumberFocus.dispose();
    _flightNumberFocus.dispose();
    _destinyFocus.dispose();
    _counterNumberFocus.dispose();
    _preboardingRoomFocus.dispose();
    _scheduleTimeFocus.dispose();
    _realDepartureTimeFocus.dispose();
    super.dispose();
  }
}
