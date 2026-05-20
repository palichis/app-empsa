import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/model/task_dto.dart';

enum Deteccion { si, no }

// El widget del card
class ItemCard extends StatefulWidget {
  final List<ItemDTO> items;
  final Function(String, Deteccion) onChanged;
  final TextEditingController lugarOcultamientoSeleccionado;

  const ItemCard({
    Key? key,
    required this.items,
    required this.onChanged,
    required this.lugarOcultamientoSeleccionado
  }) : super(key: key);

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  // Variables para almacenar los valores del card
  String _lugarOcultamiento = '';
  Deteccion? _deteccion;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de encabezado "ITEMS"
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined,color: Colors.deepOrange,size: 25,),
                    SizedBox(width: 10,),
                    Text('Información del Objeto',style: AppTextStyles.titleBoldBlack,)
                  ],
                ),
                Text('Objeto utilizado en la prueba (desde catálogo local)',style: AppTextStyles.subTitleGrey)
              ],
            ),
            const SizedBox(height: 16),
            // Tabla con los items
            Table(
              border: TableBorder.all(color: Colors.grey),
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(4),
              },
              children: [
                // Fila de encabezado de la tabla
                const TableRow(
                  decoration: BoxDecoration(color: Colors.black12),
                  children: [
                    TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('N°', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Código', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                // Filas dinámicas de la tabla a partir de la lista de items
                ...widget.items.map((item) {
                  return TableRow(
                    children: [
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${item.id}'),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${item.codigo}'),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(item.descripcion),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
            const SizedBox(height: 16),
            // Sección de Lugar de Ocultamiento y Detección
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campo de texto para Lugar de Ocultamiento
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Lugar de Ocultamiento', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: widget.lugarOcultamientoSeleccionado,
                        onChanged: (value) {
                          setState(() {
                            _lugarOcultamiento = value;
                          });
                          // Llamar a la función de callback para notificar al padre
                          widget.onChanged(_lugarOcultamiento, _deteccion ?? Deteccion.no);
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Radio buttons para Detección
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Detección', style: TextStyle(fontWeight: FontWeight.bold)),
                      RadioListTile<Deteccion>(
                        title: const Text('Sí'),
                        value: Deteccion.si,
                        groupValue: _deteccion,
                        onChanged: (Deteccion? value) {
                          setState(() {
                            _deteccion = value;
                          });
                          // Llamar a la función de callback
                          widget.onChanged(_lugarOcultamiento, _deteccion ?? Deteccion.no);
                        },
                        dense: true,
                      ),
                      RadioListTile<Deteccion>(
                        title: const Text('No'),
                        value: Deteccion.no,
                        groupValue: _deteccion,
                        onChanged: (Deteccion? value) {
                          setState(() {
                            _deteccion = value;
                          });
                          // Llamar a la función de callback
                          widget.onChanged(_lugarOcultamiento, _deteccion ?? Deteccion.no);
                        },
                        dense: true,
                      ),
                    ],
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