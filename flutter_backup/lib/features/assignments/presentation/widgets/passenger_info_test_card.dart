import 'package:flutter/material.dart';

import '../../data/model/entities/nationality_dto.dart';

// Asegúrate de que las clases de datos y el enum estén en un archivo accesible, o pégalos aquí.
enum OpcionSiNo { si, no }

class PassengerInfoCard extends StatefulWidget {
  final List<NationalityDto> nationalities;
  final Function({
  required OpcionSiNo? accionCorrectiva,
  required String nombreColaborador,
  required NationalityDto? nacionalidad,
  required String cvppt,
  required OpcionSiNo? firmaCarta,
  required String correo,
  }) onChanged;
  final TextEditingController nombreColaborador;
  final TextEditingController cvppt;
  final TextEditingController correo;

  const PassengerInfoCard({
    Key? key,
    required this.nationalities,
    required this.onChanged,
    required this.nombreColaborador,
    required this.cvppt,
    required this.correo,
  }) : super(key: key);

  @override
  State<PassengerInfoCard> createState() => _PassengerInfoCardState();
}

class _PassengerInfoCardState extends State<PassengerInfoCard> {
  // Variables de estado para los valores del formulario
  OpcionSiNo? _accionCorrectiva;
  NationalityDto? _nacionalidadSeleccionada;
  OpcionSiNo? _firmaCartaAutorizacion;

  @override
  void initState() {
    super.initState();
    // Escucha los cambios en los controladores de texto para notificar al padre
    widget.nombreColaborador.addListener(_notifyParent);
    widget.cvppt.addListener(_notifyParent);
    widget.correo.addListener(_notifyParent);
  }

  @override
  void dispose() {
    // Es importante deshacerse de los controladores para evitar fugas de memoria
    widget.nombreColaborador.dispose();
    widget.cvppt.dispose();
    widget.correo.dispose();
    super.dispose();
  }

  // Método que notifica al widget padre con todos los valores actuales
  void _notifyParent() {
    widget.onChanged(
      accionCorrectiva: _accionCorrectiva,
      nombreColaborador: widget.nombreColaborador.text,
      nacionalidad: _nacionalidadSeleccionada,
      cvppt: widget.cvppt.text,
      firmaCarta: _firmaCartaAutorizacion,
      correo: widget.correo.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de "Acción Correctiva" (Radio Buttons)
            _buildRadioSection(
              title: 'Acción Correctiva',
              groupValue: _accionCorrectiva,
              onChanged: (value) {
                setState(() {
                  _accionCorrectiva = value;
                });
                _notifyParent();
              },
            ),

            const SizedBox(height: 20),

            // Sección de "PASAJERO / FUNCIONARIO" (Encabezado)
            const Text(
              'PASAJERO / FUNCIONARIO QUE COLABORA EN LA PRUEBA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),

            // Campos de texto para el pasajero/funcionario
            _buildTextField(
              label: 'Nombre Colaborador',
              controller: widget.nombreColaborador,
            ),

            const SizedBox(height: 16),

            // Fila con Nacionalidad y CVPPT
            Row(
              children: [
                Expanded(
                  child: _buildDropdownSection(
                    title: 'Nacionalidad',
                    value: _nacionalidadSeleccionada,
                    items: widget.nationalities,
                    onChanged: (NationalityDto? newValue) {
                      setState(() {
                        _nacionalidadSeleccionada = newValue;
                      });
                      _notifyParent();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'CI/PPT',
                    controller: widget.cvppt,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Fila con Firma Carta de Autorización y Correo
            Row(
              children: [
                Expanded(
                  child: _buildRadioSection(
                    title: 'Firma Carta de Autorización',
                    groupValue: _firmaCartaAutorizacion,
                    onChanged: (value) {
                      setState(() {
                        _firmaCartaAutorizacion = value;
                      });
                      _notifyParent();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'Correo',
                    controller: widget.correo,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widgets auxiliares para reutilizar el código
  Widget _buildRadioSection({
    required String title,
    required OpcionSiNo? groupValue,
    required ValueChanged<OpcionSiNo?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Radio<OpcionSiNo>(
              value: OpcionSiNo.si,
              groupValue: groupValue,
              onChanged: onChanged,
            ),
            const Text('Sí'),
            Radio<OpcionSiNo>(
              value: OpcionSiNo.no,
              groupValue: groupValue,
              onChanged: onChanged,
            ),
            const Text('No'),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownSection({
    required String title,
    required NationalityDto? value,
    required List<NationalityDto> items,
    required ValueChanged<NationalityDto?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Autocomplete<NationalityDto>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return widget.nationalities;
            }
            return widget.nationalities.where((area) =>
                area.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
          },
          displayStringForOption: (NationalityDto option) => option.name,
          onSelected: onChanged,
        )
      ],
    );
  }
}