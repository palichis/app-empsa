import 'package:epmsa_mobile/core/presentation/fields.dart';
import 'package:epmsa_mobile/features/inspections/header/domain/Inspection.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/general_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GeneralDataScreen extends ConsumerStatefulWidget {
  final Inspection inspection;

  const GeneralDataScreen({super.key, required this.inspection});

  @override
  ConsumerState<GeneralDataScreen> createState() => GeneralDataScreenState();
}

class GeneralDataScreenState extends ConsumerState<GeneralDataScreen> {
  final _horaPicoController = TextEditingController();
  final _horaController = TextEditingController();
  final _reviewedController = TextEditingController();
  final _inspectorController = TextEditingController();
  final _fechaController = TextEditingController();
  final _numVuelosController = TextEditingController();

  final _horaFocus = FocusNode();
  final _horaPicoFocus = FocusNode();
  final _reviewedFocus = FocusNode();
  final _fechaFocus = FocusNode();
  final _numVuelosFocus = FocusNode();

  final _formKey = GlobalKey<FormState>();
  int? _reviewedId;
  int? _inspectorId;

  late final bool _hideFlightCount;

  @override
  void initState() {
    super.initState();
    final i = widget.inspection;
    _hideFlightCount =
        (i.operation == 'none' && i.type == 'none' && i.flightType == 'cargo');
  }

  void setData(GeneralData data) {
    _fechaController.text = data.measurementDate != null
        ? data.measurementDate!.toIso8601String().substring(0, 10)
        : '';
    _horaController.text = data.hour ?? '';
    _horaPicoController.text = data.peakHour ?? '';
    _numVuelosController.text = data.flightCount.toString() ?? '0';
    //_inspectorController.text = data.preparedBy!;
    _inspectorController.text = data.preparedBy ?? '';
    _inspectorId = (data.preparedById != null) ? data.preparedById : 0;
    _reviewedController.text = data.reviewedBy ?? '';
    setState(() {
      _reviewedId = (data.reviewedById != null) ? data.reviewedById : 0;
    });
  }

  Map<String, dynamic> getData() {
    return {
      'general_data_measurement_date': _fechaController.text,
      'general_data_hour':
          _horaController.text.isNotEmpty ? _horaController.text : ' ',
      'general_data_peak_hour':
          _horaPicoController.text.isNotEmpty ? _horaPicoController.text : ' ',
      'general_data_flight_count': int.tryParse(_numVuelosController.text) ?? 0,
      'general_data_prepared_by': _inspectorController.text,
      'general_data_prepared_by_id': _inspectorId ?? 0,
      'general_data_reviewed_by_id': _reviewedId ?? 0,
      'general_data_reviewed_by': _reviewedController.text,
    };
  }

  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }

  @override
  void dispose() {
    _horaController.dispose();
    _horaPicoController.dispose();
    _reviewedController.dispose();
    _inspectorController.dispose();
    _fechaController.dispose();
    _numVuelosController.dispose();
    _horaPicoFocus.dispose();
    _horaFocus.dispose();
    _reviewedFocus.dispose();
    _fechaFocus.dispose();
    _numVuelosFocus.dispose();
    super.dispose();
  }

  Widget buildLabelField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        enabled: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //List<Supervisor> supervisors = widget.inspection.supervisors ?? [];
    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: 720), // ancho máximo de la card
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 10), // más espacio lateral
            child: Form(
              key: _formKey,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Datos generales',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      /*buildEditableField(
                        label: 'Fecha de medición',
                        field: 'measurement_date',
                        controller: _fechaController,
                        focusNode: _fechaFocus,
                        keyboardType: TextInputType.datetime,
                        //setupAutoSaveField: _setupAutoSaveField,
                      ),*/
                      buildLabelField('Fecha de medición', _fechaController),
                      if (_hideFlightCount) ...[
                        const SizedBox(height: 8),
                        //buildLabelField('Hora de inspección', _horaController),
                        buildEditableField(
                          label: 'Hora de inspección',
                          field: 'hour',
                          controller: _horaController,
                          focusNode: _horaFocus,
                          suffixIcon: const Icon(Icons.access_time),
                          keyboardType: TextInputType.text,
                        )
                      ],

                      if (!_hideFlightCount) ...[
                        const SizedBox(height: 8),
                        buildLabelField(
                            'Hora pico del arribo', _horaPicoController),
                        /*buildEditableField(
                        label: 'Hora pico del arribo',
                        field: 'peak_hour',
                        controller: _horaController,
                        focusNode: _horaFocus,
                        suffixIcon: const Icon(Icons.access_time),
                        keyboardType: TextInputType.text,
                      ),*/
                        const SizedBox(height: 8),
                        buildEditableField(
                          label: 'Número de vuelos en el período',
                          field: 'flight_count',
                          controller: _numVuelosController,
                          focusNode: _numVuelosFocus,
                          keyboardType: TextInputType.number,
                          //setupAutoSaveField: _setupAutoSaveField,
                        ),
                      ],
                      const SizedBox(height: 8),
                      buildLabelField('Inspector', _inspectorController),
                      //const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
