import 'package:flutter/material.dart';

import '../../domain/model/task_dto.dart';

class TaskCard extends StatelessWidget {
  final TaskDto task;
  final VoidCallback? onOpen;
  final VoidCallback? onReport;

  const TaskCard({
    Key? key,
    required this.task,
    this.onOpen,
    this.onReport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.yellow, // El color del borde izquierdo deseado
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(left: 3.0), // El grosor del borde
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(task.isInspection?Icons.assignment:Icons.science_sharp, color: task.isInspection?Colors.blue: Colors.green,),
                SizedBox(width: 5),
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    task.status,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "${task.isInspection?'Inspección':'Prueba'} • ${task.code}",
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            // Fecha y duración
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                Text("${task.date}"),
                const Spacer(),
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Text(task.duration),
              ],
            ),
            const SizedBox(height: 5),
            Text("Asignado por: ${task.assignedTo}"),
            Text(task.description),
            const SizedBox(height: 5),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.remove_red_eye),
                    label: const Text("Abrir"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReport,
                    icon: const Icon(Icons.warning_amber_rounded),
                    label: const Text("Reportar"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
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
