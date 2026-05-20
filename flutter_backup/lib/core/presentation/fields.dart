import 'package:flutter/material.dart';

Widget buildEditableField(
    {required String label,
    required String field,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    Icon? suffixIcon,
    required FocusNode focusNode,
    //required void Function(String, TextEditingController, FocusNode)
    // setupAutoSaveField,
    Function(void)? onChanged}) {
  //setupAutoSaveField(field, controller, focusNode);
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      focusNode: focusNode,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: suffixIcon,
      ),
      onChanged: onChanged,
    ),
  );
}

Widget buildLabelField(String label, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      enabled: false,
    ),
  );
}
