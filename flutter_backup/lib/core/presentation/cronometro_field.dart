import 'package:flutter/material.dart';
import 'dart:async';

class CronometroField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String helperText;

  /// 🔑 Clave estable para rehidratar el crono entre reconstrucciones/rutas.
  final String persistKey;

  final String hintText;

  const CronometroField(
      {Key? key,
      required this.label,
      required this.controller,
      required this.persistKey,
      this.helperText = '',
      this.hintText = 'mm:ss'})
      : super(key: key);

  @override
  State<CronometroField> createState() => CronometroFieldState();
}

class CronometroFieldState extends State<CronometroField> {
  Duration _duration = Duration.zero;
  Timer? _timer;
  bool _isRunning = false;
  late final VoidCallback _externalListener;

  // Store lógico: vive mientras el proceso siga activo
  static final Map<String, _ChronoState> _store = {};

  _ChronoState _stateFor(String k) => _store[k] ??=
      _ChronoState(isRunning: false, startedAtUtc: null, accumulatedMs: 0);
  void _persist(String k, _ChronoState s) => _store[k] = s;

  @override
  void initState() {
    super.initState();
    _rehydrateFromStore();
    _adoptInitialControllerValueIfEmptyState();

    _externalListener = () {
      if (!_isRunning) {
        final parsed = _parseDuration(widget.controller.text);
        if (parsed != null && parsed != _duration) {
          setState(() {
            _duration = parsed;
            final s = _stateFor(widget.persistKey);
            s.accumulatedMs = _duration.inMilliseconds;
            _persist(widget.persistKey, s);
          });
        }
      }
    };
    widget.controller.addListener(_externalListener);
  }

  @override
  void didUpdateWidget(covariant CronometroField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // (1) Si cambia el controller, re-enchufar el listener
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_externalListener);
      widget.controller.addListener(_externalListener);
      _rehydrateFromStore();
      _adoptInitialControllerValueIfEmptyState();
    }

    // (2) Si cambia la persistKey, re-sincronizar SIN tocar el store global
    if (oldWidget.persistKey != widget.persistKey) {
      _timer?.cancel();
      _isRunning = false;

      _rehydrateFromStore();
      _adoptInitialControllerValueIfEmptyState();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller.removeListener(_externalListener);
    super.dispose();
  }

  void _rehydrateFromStore() {
    final s = _stateFor(widget.persistKey);
    final now = DateTime.now().toUtc();

    if (s.isRunning && s.startedAtUtc != null) {
      final ms =
          s.accumulatedMs + now.difference(s.startedAtUtc!).inMilliseconds;
      _duration = Duration(milliseconds: ms);
      widget.controller.text = _formatDuration(_duration);
      _startTickerOnly();
      _isRunning = true;
    } else {
      if (s.accumulatedMs > 0) {
        _duration = Duration(milliseconds: s.accumulatedMs);
        widget.controller.text = _formatDuration(_duration);
      }
      _isRunning = false;
    }
  }

  void _adoptInitialControllerValueIfEmptyState() {
    final s = _stateFor(widget.persistKey);
    final hasState = s.isRunning || s.accumulatedMs > 0;
    if (hasState) return;

    final parsed = _parseDuration(widget.controller.text);
    if (parsed != null) {
      _duration = parsed;
      widget.controller.text = _formatDuration(_duration);
      s.accumulatedMs = _duration.inMilliseconds;
      _persist(widget.persistKey, s);
    } else {
      widget.controller.text = _formatDuration(Duration.zero);
    }
  }

  Duration? _parseDuration(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    final m = RegExp(r'^(\d{1,2}):([0-5]\d)$').firstMatch(t);
    if (m != null) {
      return Duration(
          minutes: int.parse(m.group(1)!), seconds: int.parse(m.group(2)!));
    }
    final secs = int.tryParse(t);
    if (secs != null) return Duration(seconds: secs);
    return null;
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final hours = two(d.inHours);
    final minutes = two(d.inMinutes.remainder(60));
    final seconds = two(d.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  static String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final hours = two(d.inHours);
    final minutes = two(d.inMinutes.remainder(60));
    final seconds = two(d.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  void start() => _startStopwatch();

  Duration stopAndCommit() {
    //_stopStopwatch();
    widget.controller.text = _formatDuration(_duration);
    return _duration;
  }

  void _startTickerOnly() {
    readOnly=true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        final s = _stateFor(widget.persistKey);
        final now = DateTime.now().toUtc();
        final ms = s.isRunning && s.startedAtUtc != null
            ? s.accumulatedMs + now.difference(s.startedAtUtc!).inMilliseconds
            : s.accumulatedMs;
        _duration = Duration(milliseconds: ms);
        widget.controller.text = _formatDuration(_duration);
      });
    });
  }

  void _startStopwatch() {
    readOnly=true;
    if (_isRunning) return;
    final s = _stateFor(widget.persistKey);
    s.isRunning = true;
    s.startedAtUtc = DateTime.now().toUtc();
    _persist(widget.persistKey, s);

    setState(() {
      _duration = Duration(milliseconds: s.accumulatedMs);
      widget.controller.text = _formatDuration(_duration);
    });

    _startTickerOnly();
    _isRunning = true;
  }

  void _stopStopwatch() {
    readOnly=true;
    _timer?.cancel();
    final s = _stateFor(widget.persistKey);
    if (s.isRunning && s.startedAtUtc != null) {
      final now = DateTime.now().toUtc();
      s.accumulatedMs += now.difference(s.startedAtUtc!).inMilliseconds;
    }
    s.isRunning = false;
    s.startedAtUtc = null;
    _persist(widget.persistKey, s);

    _isRunning = false;
    setState(() {
      _duration = Duration(milliseconds: s.accumulatedMs);
      widget.controller.text = _formatDuration(_duration);
    });
  }
bool readOnly=true;
  void _editWatch() {
    readOnly=false;
    _timer?.cancel();
    final s = _stateFor(widget.persistKey);
    if (s.isRunning && s.startedAtUtc != null) {
      final now = DateTime.now().toUtc();
      s.accumulatedMs += now.difference(s.startedAtUtc!).inMilliseconds;
    }
    s.isRunning = false;
    s.startedAtUtc = null;
    _persist(widget.persistKey, s);

    _isRunning = false;
    setState(() {
      _duration = Duration(milliseconds: s.accumulatedMs);
      widget.controller.text = _formatDuration(_duration);
    });
  }

  void _resetStopwatch() {
    readOnly=true;
    _stopStopwatch();
    setState(() {
      _duration = Duration.zero;
      widget.controller.text = '';
    });
    final s = _stateFor(widget.persistKey);
    s.isRunning = false;
    s.startedAtUtc = null;
    s.accumulatedMs = 0;
    _persist(widget.persistKey, s);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: widget.hintText,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    icon: const Icon(Icons.play_arrow),
                    tooltip: 'Iniciar',
                    onPressed: _startStopwatch),
                IconButton(
                    icon: const Icon(Icons.stop),
                    tooltip: 'Detener',
                    onPressed: _stopStopwatch),
                IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Reiniciar',
                    onPressed: _resetStopwatch),
                IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Editar',
                    onPressed: _editWatch),
              ],
            ),
            helperText: widget.helperText,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  static _ChronoState _access(String k) => _store[k] ??=
      _ChronoState(isRunning: false, startedAtUtc: null, accumulatedMs: 0);

  static void _save(String k, _ChronoState s) => _store[k] = s;

  static Duration stopAndCommitGlobal({
    required String persistKey,
    required TextEditingController controller,
  }) {
    final s = _access(persistKey);
    if (s.isRunning && s.startedAtUtc != null) {
      final now = DateTime.now().toUtc();
      s.accumulatedMs += now.difference(s.startedAtUtc!).inMilliseconds;
    }
    s.isRunning = false;
    s.startedAtUtc = null;
    _save(persistKey, s);

    final d = Duration(milliseconds: s.accumulatedMs);
    controller.text = _fmt(d);
    return d;
  }
}

class _ChronoState {
  bool isRunning;
  DateTime? startedAtUtc;
  int accumulatedMs;

  _ChronoState({
    required this.isRunning,
    required this.startedAtUtc,
    required this.accumulatedMs,
  });
}
