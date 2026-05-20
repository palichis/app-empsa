import 'dart:io';
import 'dart:async';
import 'dart:math' as math;

import 'package:epmsa_mobile/core/helpers/photo_helpers.dart';
import 'package:epmsa_mobile/core/presentation/fields.dart';
import 'package:epmsa_mobile/core/providers/auto_save_provider.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/public_hall_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/public_hall_options.dart';
import 'package:epmsa_mobile/features/inspections/header/domain/Inspection.dart';
import 'package:epmsa_mobile/features/inspections/header/providers/inspections_providers.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

class PublicHallScreen extends ConsumerStatefulWidget {
  final Inspection inspection;
  const PublicHallScreen({super.key, required this.inspection});

  @override
  ConsumerState<PublicHallScreen> createState() => PublicHallScreenState();
}

class PublicHallScreenState extends ConsumerState<PublicHallScreen> {
  final _formKey = GlobalKey<FormState>();
  final _timeController = TextEditingController();
  final _paxWaitingController = TextEditingController();
  final _ndsAreaController = TextEditingController();
  final _ndsTimeController = TextEditingController();
  final _photoController = TextEditingController();

  List<File> _images = [];
  List<InspectionPhoto> _photos = [];
  bool _photoLoaded = false;
  PublicHallOption? _selectedOption;
  List<PublicHallOption> _publicHallOptions = [];

  final _timeFocusNode = FocusNode();
  final _paxWaitingFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _setupAutoSaveField(
      'public_hall_time',
      _timeController,
      _timeFocusNode,
    );
    _setupAutoSaveField(
      'public_hall_pax_waiting_area',
      _paxWaitingController,
      _paxWaitingFocusNode,
    );
  }

  @override
  void dispose() {
    _timeController.dispose();
    _paxWaitingController.dispose();
    _ndsAreaController.dispose();
    _ndsTimeController.dispose();
    super.dispose();
  }

  void _setupAutoSaveField(
    String field,
    TextEditingController controller,
    FocusNode focusNode,
  ) {
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        ref.read(autoSaveServiceProvider).saveField(
              field: field,
              value: controller.text,
              onSave: _saveField,
            );
      }
    });
  }

  Future<void> _saveField(String field, dynamic value) async {
    final inspection = ref.read(inspectionDetailsProvider);
    if (inspection == null) return;

    final updated = inspection.copyWithField(field, value);
    final service = ref.read(inspectionServiceSelectorProvider(updated));

    await service.save(updated);
    ref.read(inspectionDetailsProvider.notifier).setInspectionDetails(updated);

    debugPrint(
        '💾 Guardando $field = $value, en arrival id = ${inspection.id}');
  }

  Future<void> _handlePhoto() async {
    final path = await PhotoHelper.takeAndSavePhoto(context: context);
    if (path == null) return;

    final caption = await _askPhotoCaptionOverlay(
      context,
      imageFile: File(path),
      // initialText: opcional
    );

    setState(() => _images.add(File(path)));

    final photo = InspectionPhoto(
      inspectionId: widget.inspection.id!,
      path: path,
      timestamp: DateTime.now(),
      section: 'public_hall',
      caption: (caption?.isEmpty ?? true) ? null : caption,
    );
    await ref.read(photoServiceProvider).savePhoto(photo);

    setState(() {
      _photos.add(photo);
    });
  }

  Future<void> _loadExistingPhoto(int id) async {
    final photos = await ref
        .read(photoServiceProvider)
        .getPhotosBySection(id, 'public_hall');

    if (photos.isNotEmpty) {
      setState(() {
        _photos = photos;
        _images = photos.map((p) => File(p.path)).toList();
      });
    }
  }

  Widget _photoWidget() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: _handlePhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Foto – Public Hall'),
          ),
          if (_images.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _photos.map((p) {
                final img = File(p.path);
                final hasCaption = (p.caption ?? '').isNotEmpty;
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        img,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (hasCaption)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Tooltip(
                          message: p.caption!,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.chat_bubble,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
        ],
      );

  void setData(PublicHallData arrival) {
    _timeController.text = arrival.time ?? '';
    _paxWaitingController.text = arrival.paxWaiting.toString();
    _selectedOption =
        _publicHallOptions.firstWhereOrNull((o) => o.selected == 1) ??
            (_publicHallOptions.isNotEmpty ? _publicHallOptions.first : null);
    _ndsAreaController.text = arrival.ndsArea ?? '';
    _ndsTimeController.text = arrival.ndsTime ?? '';
  }

  Map<String, dynamic> getData() {
    return {
      'public_hall_id': _publicHallOptions.map((e) => e.toJson()).toList(),
      'public_hall_time': _timeController.text,
      'public_hall_pax_waiting_area':
          int.tryParse(_paxWaitingController.text) ?? 0,
      'public_hall_ndsArea': _ndsAreaController.text,
      'public_hall_ndsTime': _ndsTimeController.text,
    };
  }

  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }

  Future<void> _selectTime(TextEditingController controller) async {
    TimeOfDay initialTime;
    if (controller.text.isNotEmpty) {
      try {
        final parts = controller.text.split(':');
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        initialTime = TimeOfDay(hour: hour, minute: minute);
      } catch (_) {
        initialTime = TimeOfDay.now();
      }
    } else {
      initialTime = TimeOfDay.now();
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      controller.text = picked.format(context);
    }
  }

  void _loadListsFromSQLite(int inspectionId) async {
    final svr = ref.read(publicHallOptionRepositoryProvider);

    final opts = await svr.getPublicHallsDetails(inspectionId);

    PublicHallOption? sel = opts.firstWhereOrNull((o) => o.selected == 1);

    if (sel == null && opts.isNotEmpty) {
      sel = opts.first;

      await svr.markOptionSelected(
        inspectionId: inspectionId,
        id: sel.id,
      );

      for (final f in opts) {
        f.selected = f.id == sel.id ? 1 : 0;
      }
    }

    if (!mounted) return;

    setState(() {
      _publicHallOptions = opts;
      _selectedOption = sel;
      for (final f in _publicHallOptions) {
        f.selected = (f.id == sel!.id) ? 1 : 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(inspectionDetailsProvider);
    if (details == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final belongs = details.inspectionId == widget.inspection.id;

    if (!belongs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (details.id != null && !_photoLoaded) {
      _photoLoaded = true;
      Future.microtask(() => {
            _loadExistingPhoto(widget.inspection.id!),
            _loadListsFromSQLite(widget.inspection.id!)
          });
    }
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hall Público',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<PublicHallOption>(
                    value: _selectedOption,
                    items: _publicHallOptions
                        .map((o) => DropdownMenuItem(
                              value: o,
                              child: Text(o.name),
                            ))
                        .toList(),
                    decoration: const InputDecoration(
                      labelText: 'Hall',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (opt) async {
                      if (opt == null) return;
                      final svr = ref.read(publicHallOptionRepositoryProvider);
                      await svr.markOptionSelected(
                        inspectionId: widget.inspection.id!,
                        id: opt.id!,
                      );
                      setState(() {
                        _selectedOption = opt;
                        for (final f in _publicHallOptions) {
                          f.selected = f.id == opt.id ? 1 : 0;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  buildEditableField(
                    label: 'Hora',
                    field: 'public_hall_time',
                    controller: _timeController,
                    focusNode: _timeFocusNode,
                    onTap: () => _selectTime(_timeController),
                  ),
                  buildEditableField(
                    label: 'PAX área de espera (unidades)',
                    field: 'public_hall_pax_waiting_area',
                    controller: _paxWaitingController,
                    focusNode: _paxWaitingFocusNode,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _photoWidget(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Overlay para comentario estilo WhatsApp, con IME inmediato ---
Future<String?> _askPhotoCaptionOverlay(
  BuildContext context, {
  required File imageFile,
  String? initialText,
}) async {
  return Navigator.of(context, rootNavigator: true).push<String>(
    PageRouteBuilder(
      opaque: true, // pantalla completa para menor sobrecosto de composición
      barrierDismissible: true,
      barrierColor: Colors.black,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (ctx, _, __) => WAfastCaptionOverlay(
        imageFile: imageFile,
        initialText: initialText,
      ),
      transitionsBuilder: (_, __, ___, child) => child,
    ),
  );
}

// --- Overlay para comentario estilo WhatsApp ---
class WAfastCaptionOverlay extends StatefulWidget {
  final File imageFile;
  final String? initialText;
  const WAfastCaptionOverlay({required this.imageFile, this.initialText});

  @override
  State<WAfastCaptionOverlay> createState() => WAfastCaptionOverlayState();
}

class WAfastCaptionOverlayState extends State<WAfastCaptionOverlay> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _showImage = false;

  // Seguimiento IME sólo para ESTA animación
  double _kbPrev = 0.0;
  double _kbPeak = 0.0; // pico local de esta subida
  bool _kbAnimating = false;
  Timer? _kbSettle;
  static const Duration _kbSettleDelay = Duration(milliseconds: 220);

  // Tolerancia y rampa de apagado cerca del final
  static const double _kbToleranceMax = 40.0; // tu colchón
  static const double _rampWindow = 56.0; // últimos px donde apagamos el extra

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.initialText ?? '';

    // No auto-IME; sólo mostramos la imagen un toque después
    Future.delayed(const Duration(milliseconds: 30), () {
      if (mounted) setState(() => _showImage = true);
    });
  }

  @override
  void dispose() {
    _kbSettle?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  // Mostrar teclado sólo cuando el usuario toca el campo
  void _startEditing() {
    if (!_focus.hasFocus) _focus.requestFocus();
    SystemChannels.textInput.invokeMethod('TextInput.show');
  }

  // Extra DURANTE animación:
  //  - Base: distancia que falta (kbPeak - kb), limitada por _kbToleranceMax
  //  - Rampa: en los últimos _rampWindow dp, el extra se reduce proporcionalmente a 0
  double _extraWhileAnimating(double kb) {
    double missing = _kbPeak - kb; // cuánto falta para el final local
    if (missing < 0) missing = 0.0;

    // tope normal por tolerancia máxima
    double extra = (missing > _kbToleranceMax) ? _kbToleranceMax : missing;

    // rampa de apagado cerca del final para evitar "irse arriba" al final
    if (missing < _rampWindow) {
      final scale = (missing / _rampWindow); // 1 -> 0 al acercarse al final
      extra = extra * scale;
    }
    return extra;
  }

  // Track de kb/pico y detección de "asentado"
  void _trackKb(double kb) {
    if ((kb - _kbPrev).abs() < 0.5) return; // ignora ruido
    _kbPrev = kb;

    // inicio de animación
    if (!_kbAnimating && kb > 0.0) {
      setState(() {
        _kbAnimating = true;
        _kbPeak = kb; // reinicia el pico para ESTA animación
      });
    }

    // mientras sube, actualiza el pico
    if (_kbAnimating && kb > _kbPeak) {
      _kbPeak = kb;
    }

    // fin (asentado): si no cambia por un rato
    _kbSettle?.cancel();
    _kbSettle = Timer(_kbSettleDelay, () {
      if (!mounted) return;

      // fijamos el pico al valor FINAL real para que missing==0 ⇒ extra==0
      _kbPeak = _kbPrev;
      setState(() => _kbAnimating = false);
    });
  }

  void _submit() {
    if (_navigated) return;
    _navigated = true;
    final text = _ctrl.text.trim();
    Navigator.of(context, rootNavigator: true).pop(text);
   /*//TODO esto cambiaba el flujo de navegación y se perdia el caption, validar en inspecciones q no dañe nada quitar esta pantalla aunque esta de mas
   Navigator.of(context, rootNavigator: true).pushReplacement(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => _PhotoPreviewPage(
          imageFile: widget.imageFile,
          caption: text,
        ),
        transitionsBuilder: (_, __, ___, child) => child,
      ),
    );*/
  }

  @override
  Widget build(BuildContext context) {
    final double kb =
        MediaQuery.viewInsetsOf(context).bottom; // altura real IME
    _trackKb(kb);

    // DURANTE: kb + extra con rampa hacia 0 al acercarse al final (sin overshoot)
    // ESTABLE:  extra=0 (ya no hay tolerancia ⇒ nada que "rebote")
    final double extra = _kbAnimating ? _extraWhileAnimating(kb) : 0.0;
    final double bottomPad = (kb <= 0.0) ? 0.0 : kb + extra;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: _showImage
                ? Image.file(widget.imageFile, fit: BoxFit.contain)
                : const SizedBox.shrink(),
          ),
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(null),
                tooltip: 'Cerrar',
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPad)
                    .add(const EdgeInsets.fromLTRB(12, 8, 12, 12)),
                child: RepaintBoundary(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(250),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            focusNode: _focus,
                            autofocus: false, // no auto-IME
                            onTap: _startEditing, // lo abre el usuario
                            minLines: 1,
                            maxLines: 5,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            autocorrect: false,
                            enableSuggestions: false,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Añade un comentario…',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                              isCollapsed: true,
                            ),
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.check_circle,
                              color: Colors.white),
                          onPressed: _submit,
                          tooltip: 'Guardar',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- PREVIEW de foto a pantalla completa (cierra devolviendo el caption) ---
class _PhotoPreviewPage extends StatelessWidget {
  final File imageFile;
  final String caption;
  const _PhotoPreviewPage(
      {super.key, required this.imageFile, required this.caption});

  @override
  Widget build(BuildContext context) {
    print('***************************************************************');
    print(caption);    print(caption);    print(caption);    print(caption);    print(caption);
    print('***************************************************************');
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Guardar',
            icon: const Icon(Icons.check_circle),
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(caption),
            color: Colors.white,
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Image.file(imageFile, fit: BoxFit.contain),
        ),
      ),
      bottomNavigationBar: caption.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.black.withAlpha(250),
                child:
                    Text(caption, style: const TextStyle(color: Colors.white)),
              ),
            ),
    );
  }
}

// TIP Android: en AndroidManifest.xml, MainActivity debería tener:
// <activity
//   android:name=".MainActivity"
//   android:windowSoftInputMode="stateHidden|adjustResize" />
