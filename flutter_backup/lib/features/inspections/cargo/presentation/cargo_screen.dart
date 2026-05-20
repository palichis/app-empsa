import 'package:epmsa_mobile/core/providers/auto_save_provider.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/airside.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/cargo.dart';
import 'package:epmsa_mobile/features/inspections/cargo/domain/landside.dart';
import 'package:epmsa_mobile/features/inspections/cargo/presentation/cargo_airside_screen.dart';
import 'package:epmsa_mobile/features/inspections/cargo/presentation/cargo_landside_screen.dart';
import 'package:epmsa_mobile/features/inspections/cargo/presentation/galley_screen.dart';
import 'package:epmsa_mobile/features/inspections/cargo/providers/cargo_provider.dart';
import 'package:epmsa_mobile/features/inspections/header/domain/Inspection.dart';
import 'package:epmsa_mobile/features/inspections/header/providers/inspections_providers.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/general_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/presentation/general_data_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CargoInspectionScreen extends ConsumerStatefulWidget {
  final Inspection inspection;

  const CargoInspectionScreen({super.key, required this.inspection});

  @override
  ConsumerState<CargoInspectionScreen> createState() =>
      _CargoInspectionScreenState();
}

class _CargoInspectionScreenState extends ConsumerState<CargoInspectionScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  /*final generalKey = GlobalKey<GeneralDataScreenState>();
  final landsideKey = GlobalKey<CargoLandsideScreenState>();
  final airsideKey = GlobalKey<CargoAirsideScreenState>();
  final photosKey = GlobalKey<GalleryScreenState>();*/

  late GlobalKey<GeneralDataScreenState> generalKey;
  late GlobalKey<CargoLandsideScreenState> landsideKey;
  late GlobalKey<CargoAirsideScreenState> airsideKey;
  late GlobalKey<GalleryScreenState> photosKey;

  final _tabScrollController = ScrollController();
  final List<GlobalKey> _tabKeys = List.generate(4, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final id = widget.inspection.id;

    generalKey = GlobalKey<GeneralDataScreenState>(debugLabel: 'general-$id');
    landsideKey =
        GlobalKey<CargoLandsideScreenState>(debugLabel: 'landside-$id');
    airsideKey = GlobalKey<CargoAirsideScreenState>(debugLabel: 'airside-$id');
    photosKey = GlobalKey<GalleryScreenState>(debugLabel: 'photos-$id');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final service = ref.read(cargoServiceProvider);
      final inspectionId = widget.inspection.id;
      Cargo? cargo = await service.loadCargoForInspection(inspectionId!);
      print('📦 Cargo $inspectionId cargado desde SQLite: ${cargo?.id}');

      if (cargo == null) {
        final general = GeneralData(
          measurementDate: widget.inspection.date!,
          preparedBy: widget.inspection.employee.name,
          reviewedBy: '',
        );

        cargo = Cargo(
          id: 0,
          inspectionId: inspectionId,
          general: general,
        );

        await service.saveCargo(cargo);
        generalKey.currentState?.setData(general);
      }
      print("---------PRELOADING CARGO--------");
      debugPrint("${cargo.toJson()}");
      generalKey.currentState?.setData(cargo.general);
      /*landsideKey.currentState?.setData(cargo.landside);
      airsideKey.currentState?.setData(cargo.airside);*/
    });

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  void _scrollToCurrentTab() {
    final index = _tabController.index;
    final keyContext = _tabKeys[index].currentContext;
    if (keyContext != null) {
      double alignment = (index == 0)
          ? 0.0
          : (index == _tabController.length - 1)
              ? 1.0
              : 0.5;
      Scrollable.ensureVisible(keyContext,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: alignment);
    }
  }

  Future<void> _guardarDatos() async {
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      await ref.read(autoSaveServiceProvider).flush();
      final generalData = generalKey.currentState?.getData() ?? {};
      final landsideData = landsideKey.currentState?.getData() ?? {};
      final airsideData = airsideKey.currentState?.getData() ?? {};
      final photoData = photosKey.currentState?.getData() ?? {};
      //final currentArrival = ref.read(inspectionDetailsProvider);
      final service = ref.read(cargoServiceProvider);
      final inspectionId = widget.inspection.id;
      Cargo? cargo = await service.loadCargoForInspection(inspectionId!);

      final dataCombined = {
        ...generalData,
        ...landsideData,
        ...airsideData,
        ...photoData,
        'inspection_id': widget.inspection.id,
        'id': cargo?.id ?? 0,
        'synced': 0,
      };
      final newCargo = Cargo.fromJson(dataCombined);
      final serviceCargo = ref.read(cargoServiceProvider);
      await serviceCargo.saveCargo(newCargo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Inspección guardada correctamente")),
        );
      }
    } catch (e, s) {
      debugPrint("${e.toString()} ---- ${s}");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '❌ Se ha producido un error al guardar la inspección de cargo')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final parentKey = ValueKey(
      'cargo-${widget.inspection.id}',
    );
    return Scaffold(
      appBar: AppBar(
        key: parentKey,
        title: const Text("Inspección de Carga",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.yellow[100],
            child: Text(
              '${DateFormat('dd-MM-yyyy').format(widget.inspection.date!)} (Iniciada: ${DateFormat('HH:mm').format(DateTime.now())})',
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildTabNavigation(),
          Expanded(
            child: IndexedStack(
              index: _tabController.index,
              children: [
                GeneralDataScreen(
                  key: generalKey,
                  inspection: widget.inspection,
                ),
                CargoLandsideScreen(
                  key: landsideKey,
                  inspection: widget.inspection,
                ),
                CargoAirsideScreen(
                  key: airsideKey,
                  inspection: widget.inspection,
                ),
                GalleryScreen(
                  key: photosKey,
                  inspectionId: widget.inspection.id!,
                ),
              ],
            ),
          ),
        ],
      ),
      /*floatingActionButton: FloatingActionButton.extended(
        onPressed: _guardarDatos,
        icon: const Icon(Icons.save),
        label: const Text("Guardar"),
      ),*/
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 200,
            child: FilledButton.icon(
              onPressed: _guardarDatos,
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabNavigation() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: _tabController.index > 0
              ? () {
                  _tabController.animateTo(_tabController.index - 1);
                  _scrollToCurrentTab();
                }
              : null,
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _tabScrollController,
            scrollDirection: Axis.horizontal,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(text: 'Datos Generales'),
                Tab(text: 'Lado Tierra'),
                Tab(text: 'Lado Aire'),
                Tab(text: 'Fotos'),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: _tabController.index < _tabController.length - 1
              ? () {
                  _tabController.animateTo(_tabController.index + 1);
                  _scrollToCurrentTab();
                }
              : null,
        ),
      ],
    );
  }
}
