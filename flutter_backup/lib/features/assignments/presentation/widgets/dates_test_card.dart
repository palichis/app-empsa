import 'package:flutter/material.dart';

import '../../data/model/entities/area_dto.dart';



class DatesTestCard extends StatefulWidget {
  final List<AreaDto> allAreas;

  final ValueChanged<DateTime?> onFechaChanged;
  final ValueChanged<TimeOfDay?> onHoraChanged;
  final ValueChanged<AreaDto?> onLugarChanged;
  final String? resultadoInicial; // valor por defecto
  final void Function(String)? onResultadoChanged;

  const DatesTestCard({
    super.key,
    required this.allAreas,
    required this.onFechaChanged,
    required this.onHoraChanged,
    required this.onLugarChanged,
    this.resultadoInicial,
    this.onResultadoChanged,
  });

  @override
  State<DatesTestCard> createState() => _DatesTestCardState();
}

class _DatesTestCardState extends State<DatesTestCard> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  AreaDto? selectedArea;
  late String? _resultado;

  @override
  void initState() {
    super.initState();
    _resultado = widget.resultadoInicial;
  }

  Future<void> _selectDate() async {
    DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      widget.onFechaChanged(picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
      widget.onHoraChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Fecha y Hora
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Fecha de Prueba",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            selectedDate == null
                                ? "Seleccionar fecha"
                                : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Hora de Prueba",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _selectTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            selectedTime == null
                                ? "Seleccionar hora"
                                : "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text("Lugar de Prueba",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 20),
                Expanded(
                  child: Autocomplete<AreaDto>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return widget.allAreas;
                      }
                      return widget.allAreas.where((area) =>
                          area.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    displayStringForOption: (AreaDto option) => option.name,
                    onSelected: (AreaDto selection) {
                      widget.onLugarChanged(selection);
                    },
                  )
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ResultadoDropdown(
                    label: "Resultado de la prueba",
                    value: _resultado,
                    onChanged: (nuevo) {
                      setState(() {
                        _resultado = nuevo;
                      });
                      widget.onResultadoChanged?.call(nuevo!);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
class _ResultadoDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final void Function(String?) onChanged;

  const _ResultadoDropdown({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: "Prueba superada.",
              child: Text("Prueba superada."),
            ),
            DropdownMenuItem(
              value: "Prueba no superada.",
              child: Text("Prueba no superada."),
            ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}