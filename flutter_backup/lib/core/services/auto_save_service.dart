class AutoSaveService {
  final Map<String, dynamic> _lastSavedValues = {};
  final Set<Future<void>> _pending = {}; // cola global de pendientes
  final Map<String, Future<void>> _inflightByField =
      {}; // evita saves paralelos del mismo campo

  Future<void> saveField({
    required String field,
    required dynamic value,
    required Future<void> Function(String field, dynamic value) onSave,
  }) async {
    if (_lastSavedValues[field] == value) return;

    // si ya hay un save en curso para ese field, encadénalo
    final previous = _inflightByField[field];
    final task = () async {
      try {
        if (previous != null) await previous; // serializa por campo
        _lastSavedValues[field] = value;
        final f = onSave(field, value); // <-- hace el write a SQLite
        _pending.add(f);
        await f;
      } finally {
        _pending.removeWhere((p) => p == previous); // limpieza defensiva
        _inflightByField.remove(field);
      }
    }();

    _inflightByField[field] = task;
    _pending.add(task);
    await task; // si tú llamas y quieres esperar; si no, flush() se encargará
  }

  Future<void> flush() async {
    if (_pending.isEmpty) return;
    // snapshot para evitar que la colección cambie mientras esperamos
    final list = List<Future<void>>.from(_pending);
    await Future.wait(list);
  }

  void reset() {
    _lastSavedValues.clear();
    _inflightByField.clear();
    _pending.clear();
  }
}
