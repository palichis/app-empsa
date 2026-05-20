import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

Future<bool?> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String description,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false, // el usuario debe tocar aceptar
    builder: (context) {
      return AlertDialog(backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),side: BorderSide(color: AppColors.primary)
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color:  Colors.yellow,
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow[700] ,
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
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Aceptar"),
          ),
        ],
      );
    },
  );
}
