import 'package:epmsa_mobile/features/assignments/data/model/entities/employee_dto.dart';
import 'package:flutter/material.dart';

class KindTestCard extends StatelessWidget {
  final String? tipoPrueba;
  final EmployeeDto? agente;
  final TextEditingController marca;
  final TextEditingController modelo;
  final List<EmployeeDto> allEmployeeDto;

  final void Function(String?) onTipoPruebaChanged;
  final void Function(EmployeeDto?) onAgenteChanged;
  final void Function(String) onMarcaChanged;
  final void Function(String) onModeloChanged;

  const KindTestCard({
    super.key,
    required this.tipoPrueba,
    required this.agente,
    required this.marca,
    required this.modelo,
    required this.allEmployeeDto,
    required this.onTipoPruebaChanged,
    required this.onAgenteChanged,
    required this.onMarcaChanged,
    required this.onModeloChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ---- Tipos de pruebas ----
            Row(
              children: [
                const Expanded(
                    flex: 2,
                    child: Text("Tipos de pruebas",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                  flex: 5,
                  child: DropdownButtonFormField<String>(
                    value: tipoPrueba,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text("Seleccionar"),
                    items: const [
                      DropdownMenuItem(
                        value: "equipment",
                        child: Text("Equipo"),
                      ),
                      DropdownMenuItem(
                        value: "procedure",
                        child: Text("Procedimiento"),
                      ),
                    ],
                    onChanged: onTipoPruebaChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ---- Agente Seguridad ----
            Row(
              children: [
                const Expanded(
                    flex: 2,
                    child: Text("Agente Seguridad",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                  flex: 5,
                  child: DropdownButtonFormField<EmployeeDto?>(
                    value: agente??EmployeeDto(id: 0, name: ''),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text("Seleccionar"),
                    items: allEmployeeDto.map((emp){
                      return DropdownMenuItem(
                        value: emp,
                        child: Text(emp.name),
                      );
                    }).toList(),
                    onChanged: onAgenteChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ---- Marca ----
            Row(
              children: [
                const Expanded(
                    flex: 2,
                    child: Text("Marca",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                  flex: 5,
                  child: TextFormField(
                    controller: marca,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: onMarcaChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ---- Modelo ----
            Row(
              children: [
                const Expanded(
                    flex: 2,
                    child: Text("Modelo",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                  flex: 5,
                  child: TextFormField(
                    controller: modelo,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: onModeloChanged,
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
