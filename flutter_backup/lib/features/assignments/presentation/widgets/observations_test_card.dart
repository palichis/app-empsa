import 'package:flutter/material.dart';

class ObservationsCard extends StatefulWidget {
  final Function({
  required String observaciones,
  required String recomendaciones,
  }) onChanged;
  final TextEditingController observacionesController;
  final TextEditingController recomendacionesController;

  const ObservationsCard({
    Key? key,
    required this.onChanged,
    required this.observacionesController,
    required this.recomendacionesController,
  }) : super(key: key);

  @override
  State<ObservationsCard> createState() => _ObservationsCardState();
}

class _ObservationsCardState extends State<ObservationsCard> {

  @override
  void initState() {
    super.initState();

    // Escucha los cambios en los controladores y notifica al padre
    widget.observacionesController.addListener(_notifyParent);
    widget.recomendacionesController.addListener(_notifyParent);
  }

  @override
  void dispose() {
    // Es crucial liberar los controladores para evitar fugas de memoria
    widget.observacionesController.dispose();
    widget.recomendacionesController.dispose();
    super.dispose();
  }

  // Método que llama a la función de callback del padre
  void _notifyParent() {
    widget.onChanged(
      observaciones: widget.observacionesController.text,
      recomendaciones: widget.recomendacionesController.text,
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
            // Sección de Observaciones
            const Text(
              'OBSERVACIONES',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.observacionesController,
              maxLines: 3, // Campo multilínea
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            // Sección de Recomendaciones
            const Text(
              'RECOMENDACIONES',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.recomendacionesController,
              maxLines: 3, // Campo multilínea
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}