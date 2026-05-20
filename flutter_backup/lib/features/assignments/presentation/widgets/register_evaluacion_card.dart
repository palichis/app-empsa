import 'package:flutter/material.dart';

class EvaluacionCard extends StatefulWidget {
  final String item;
  final String titulo;
  final String descripcion;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;

  const EvaluacionCard({
    super.key,
    required this.item,
    required this.titulo,
    required this.descripcion,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  State<EvaluacionCard> createState() => _EvaluacionCardState();
}

class _EvaluacionCardState extends State<EvaluacionCard> {
  final List<Map<String, dynamic>> opciones = [
    {"valor": "Satisfactorio", "color": Colors.green, "label": "Satisfactorio"},
    {"valor": "Poco satisfactorio", "color": Colors.orange, "label": "Poco\nsatisfactorio"},
    {"valor": "No cumple", "color": Colors.red, "label": "No cumple"},
    {"valor": "No aplica", "color": Colors.black, "label": "No aplica"},
    {"valor": "No observado", "color": Colors.blue, "label": "No observado"},
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Etiqueta Item
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(widget.item, style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 10),

            // Título
           /* Text(
              widget.titulo,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),*/

            // Descripción
            Text(
              widget.descripcion,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),

            // Evaluación label
            const Text(
              "Evaluación *",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),

            // Opciones de evaluación
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: opciones.map((opcion) {
                return InkWell(
                  onTap: () {
                      widget.onChanged(opcion["valor"]);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<String>(
                        value: opcion["valor"],
                        groupValue: widget.selectedValue,
                        onChanged: widget.onChanged,
                        activeColor: opcion["color"],
                      ),
                      Text(
                        opcion["label"],
                        style: TextStyle(
                          color: opcion["color"],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }
}
