import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

Future<void> showResultDialog({
  required BuildContext context,
  required bool success,
  required String title,
  required String description,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false, // el usuario debe tocar aceptar
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),side: BorderSide(color: AppColors.primary)
        ),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: success ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ),
          ],
        ),
        content: Text(
          description,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Aceptar"),
          ),
        ],
      );
    },
  );
}
