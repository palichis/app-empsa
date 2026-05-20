import 'package:epmsa_mobile/features/inspections/cargo/domain/cargo_item.dart';
import 'package:flutter/material.dart';

class CriteriaLineCard extends StatefulWidget {
  final CriteriaItem criteria;
  final void Function(CriteriaItem)? onChanged;

  const CriteriaLineCard({
    super.key,
    required this.criteria,
    this.onChanged,
  });

  @override
  State<CriteriaLineCard> createState() => _CriteriaLineCardState();
}

class _CriteriaLineCardState extends State<CriteriaLineCard> {
  late CriteriaItem _current; // <- estado acumulador local

  late final TextEditingController ctrlValue;
  late final TextEditingController ctrlNote;
  late int _displayPct;

  final FocusNode _focusValue = FocusNode();
  final FocusNode _focusNote = FocusNode();

  // --- Dropdown autosave ---
  final FocusNode _focusQual = FocusNode();
  String? _selectedQual;

  static const _allowedQuals = {'Óptimo', 'Hallazgo', 'No Aplica'};
  String? _normalizeQual(String? v) => _allowedQuals.contains(v) ? v : null;

  @override
  void initState() {
    super.initState();

    _current = widget.criteria; // base inicial

    ctrlValue = TextEditingController(
      text: _current.controlValue?.toStringAsFixed(0) ?? '',
    );
    ctrlNote = TextEditingController(
      text: _current.note ?? '',
    );
    _displayPct = (_current.percentage * 100).round();

    // Inicial del dropdown normalizado
    _selectedQual = _normalizeQual(_current.qualification);

    _focusValue.addListener(() {
      if (!_focusValue.hasFocus) _commitAndRecalc(ctrlValue.text);
    });

    // Autosave de nota al perder foco
    _focusNote.addListener(() {
      if (!_focusNote.hasFocus) {
        _current = _current.copyWithField('note', ctrlNote.text);
        widget.onChanged?.call(_current);
      }
    });

    // Autosave de dropdown al perder foco (además del onChanged)
    _focusQual.addListener(() {
      if (!_focusQual.hasFocus) {
        _current = _current.copyWithField('qualification', _selectedQual);
        widget.onChanged?.call(_current);
      }
    });
  }

  @override
  void didUpdateWidget(covariant CriteriaLineCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si el padre envía un objeto actualizado, sincroniza la base local
    if (!identical(oldWidget.criteria, widget.criteria)) {
      _current = widget.criteria;
    }

    if (oldWidget.criteria.controlValue != widget.criteria.controlValue &&
        !_focusValue.hasFocus) {
      ctrlValue.text = widget.criteria.controlValue?.toStringAsFixed(0) ?? '';
    }

    if (oldWidget.criteria.percentage != widget.criteria.percentage &&
        !_focusValue.hasFocus) {
      _displayPct = (widget.criteria.percentage * 100).round();
    }

    if (oldWidget.criteria.note != widget.criteria.note &&
        !_focusNote.hasFocus) {
      ctrlNote.text = widget.criteria.note ?? '';
    }

    if (oldWidget.criteria.qualification != widget.criteria.qualification &&
        !_focusQual.hasFocus) {
      _selectedQual = _normalizeQual(widget.criteria.qualification);
    }
  }

  @override
  void dispose() {
    _focusValue.dispose();
    _focusNote.dispose();
    _focusQual.dispose();
    ctrlValue.dispose();
    ctrlNote.dispose();
    super.dispose();
  }

  void _commitAndRecalc(String raw) {
    final maxV = _current.maxValue; // usar siempre la base local
    if (maxV <= 0) {
      setState(() => _displayPct = 0);
      _current = _current.copyWithField('percentage', 0);
      widget.onChanged?.call(_current);
      return;
    }

    final val = double.tryParse(raw.replaceAll(',', '.')) ?? 0.0;
    int pct = ((val / maxV) * 100).round();
    if (pct < 0) pct = 0;
    if (pct > 100) pct = 100;

    setState(() => _displayPct = pct);

    _current = _current
        .copyWithField('control_value', val)
        .copyWithField('percentage', pct);

    widget.onChanged?.call(_current);
  }

  @override
  Widget build(BuildContext context) {
    final criteria = _current; // mostrar siempre el estado vigente
    final bool isMaxValueValid= criteria.maxValue!=0;
    return SizedBox(
      height: isMaxValueValid?375:225, // alto fijo
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ① Nombre
              Text(
                criteria.name,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              // ② Calificación (Dropdown con autosave)
              DropdownButtonFormField<String>(
                focusNode: _focusQual,
                value: _selectedQual, // siempre normalizado
                items: const [
                  DropdownMenuItem(value: 'Óptimo', child: Text('Óptimo')),
                  DropdownMenuItem(value: 'Hallazgo', child: Text('Hallazgo')),
                  DropdownMenuItem(
                      value: 'No Aplica', child: Text('No Aplica')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Calificación',
                  isDense: true,
                ),
                onChanged: (v) {
                  setState(() => _selectedQual = _normalizeQual(v));
                  _current =
                      _current.copyWithField('qualification', _selectedQual);
                  widget.onChanged?.call(_current);
                },
              ),
              const SizedBox(height: 12),

              // ③ Valor máximo
              if(isMaxValueValid)
              Text('Valor máximo: ${criteria.maxValue.toStringAsFixed(0)}'),
              if(isMaxValueValid)
              const SizedBox(height: 12),

              // ④ Valor editable
              if(isMaxValueValid)
              TextFormField(
                controller: ctrlValue,
                focusNode: _focusValue,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  isDense: true,
                ),
                onFieldSubmitted: (v) => _commitAndRecalc(v),
                onTapOutside: (_) => _commitAndRecalc(ctrlValue.text),
              ),
              if(isMaxValueValid)
              const SizedBox(height: 12),

              // Porcentaje
              if(isMaxValueValid)
              Text('Porcentaje: $_displayPct%'),
              if(isMaxValueValid)
              const SizedBox(height: 12),

              // ⑤ Nota (autosave al perder foco o tap fuera)
              TextFormField(
                controller: ctrlNote,
                focusNode: _focusNote,
                decoration: const InputDecoration(
                  labelText: 'Nota',
                  isDense: true,
                ),
                maxLines: 2,
                onTapOutside: (_) {
                  _current = _current.copyWithField('note', ctrlNote.text);
                  widget.onChanged?.call(_current);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
