import 'package:epmsa_mobile/core/presentation/criteria_line_card.dart';
import 'package:epmsa_mobile/core/presentation/form_field_array.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/cargo_item.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/landside_entry.dart';
import 'package:flutter/material.dart';

class FormArraySection extends StatelessWidget {
  final String title;
  final GlobalKey<FormFieldArrayState> keyArray;
  final String fieldKey;
  final Future<void> Function(String key, List<CriteriaItem>) onSave;

  const FormArraySection({
    super.key,
    required this.title,
    required this.keyArray,
    required this.fieldKey,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        FormFieldArray<CriteriaItem>(
          key: keyArray,
          // ⬇️ autosave: cuando cambia cualquier fila
          onChanged: (list) => onSave(fieldKey, list),

          // firma correcta: (ctx, entry, onEntryChanged)
          itemBuilder: (ctx, entry, onEntryChanged) => CriteriaLineCard(
            criteria: entry,
            onChanged: (updated) => onEntryChanged(updated),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
