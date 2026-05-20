import 'package:flutter/material.dart';

typedef FormFieldArrayItemBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  ValueChanged<T> onChanged,
);

class FormFieldArray<T> extends FormField<List<T>> {
  FormFieldArray({
    super.key,
    required FormFieldArrayItemBuilder<T> itemBuilder,
    List<T>? initialValue,
    ValueChanged<List<T>>? onChanged, // ← autosave
    super.onSaved,
    super.validator,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
  }) : super(
          initialValue: initialValue ?? const [],
          autovalidateMode: autovalidateMode,
          builder: (fieldState) {
            final state = fieldState as FormFieldArrayState<T>;
            return Column(
              children: [
                for (final item in state._items)
                  itemBuilder(
                    fieldState.context,
                    item,
                    (updated) => state._updateItem(item, updated),
                  ),
              ],
            );
          },
        );

  @override
  FormFieldState<List<T>> createState() => FormFieldArrayState<T>();
}

class FormFieldArrayState<T> extends FormFieldState<List<T>> {
  late List<T> _items;

  void setData(List<T> data) {
    setState(() {
      _items = List<T>.from(data);
      didChange(_items); // dispara onChanged externo
    });
  }

  List<T> getData() => List.unmodifiable(_items);

  @override
  void initState() {
    super.initState();
    _items = List<T>.from(widget.initialValue ?? const []);
  }

  void _updateItem(T oldItem, T newItem) {
    final idx = _items.indexOf(oldItem);
    if (idx == -1) return;
    setState(() {
      _items[idx] = newItem;
      didChange(_items);
    });
  }
}
