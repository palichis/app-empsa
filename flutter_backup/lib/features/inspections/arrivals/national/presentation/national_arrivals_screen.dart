import 'package:epmsa_mobile/core/providers/auto_save_provider.dart';
import 'package:epmsa_mobile/features/inspections/header/providers/inspections_providers.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/baggage_area_data.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/national/domain/national_arrivals.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/public_hall_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/presentation/arrivals_baggage_area_screen.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/national/presentation/arrivals_baggage_time_screen.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/general_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/presentation/general_data_screen.dart';
import 'package:epmsa_mobile/features/inspections/shared/presentation/observations_screen.dart';
import 'package:epmsa_mobile/features/inspections/shared/presentation/public_hall_screen.dart';
import 'package:epmsa_mobile/features/inspections/shared/providers/arrivals_provider.dart';
import 'package:epmsa_mobile/features/inspections/header/domain/Inspection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class NationalArrivalsScreen extends ConsumerStatefulWidget {
  final Inspection inspection;

  const NationalArrivalsScreen({super.key, required this.inspection});

  @override
  NationalArrivalsScreenState createState() => NationalArrivalsScreenState();
}

class NationalArrivalsScreenState extends ConsumerState<NationalArrivalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _tabScrollController = ScrollController();
  final List<GlobalKey> _tabKeys = List.generate(5, (_) => GlobalKey());

  /*final generalKey = GlobalKey<GeneralDataScreenState>();
  final hallKey = GlobalKey<PublicHallScreenState>();
  final baggageAreaKey = GlobalKey<ArrivalsBaggageAreaScreenState>();
  final baggageTimeKey = GlobalKey<ArrivalsBaggageTimeScreenState>();
  final observationsKey = GlobalKey<ObservationsScreenState>();*/

  late GlobalKey<GeneralDataScreenState> generalKey;
  late GlobalKey<PublicHallScreenState> hallKey;
  late GlobalKey<ArrivalsBaggageAreaScreenState> baggageAreaKey;
  late GlobalKey<ArrivalsBaggageTimeScreenState> baggageTimeKey;
  late GlobalKey<ObservationsScreenState> observationsKey;

  String? tipoVuelo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    final id = widget.inspection.id ?? 'pending';

    generalKey = GlobalKey<GeneralDataScreenState>(debugLabel: 'general-$id');
    hallKey = GlobalKey<PublicHallScreenState>(debugLabel: 'hall-$id');
    baggageAreaKey = GlobalKey<ArrivalsBaggageAreaScreenState>(
        debugLabel: 'baggageArea-$id');
    baggageTimeKey = GlobalKey<ArrivalsBaggageTimeScreenState>(
        debugLabel: 'baggageTime-$id');
    observationsKey =
        GlobalKey<ObservationsScreenState>(debugLabel: 'observations-$id');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final service = ref.read(nationalArrivalServiceProvider);
      final inspectionId = widget.inspection.id;
      NationalArrival? arrival = (await service
          .loadArrivalForInspection(inspectionId!)) as NationalArrival?;
      print('📦 Inspección $inspectionId cargada desde SQLite: ${arrival?.id}');
      if (arrival == null) {
        final generalDataMap = GeneralData(
            measurementDate: widget.inspection.date!,
            peakHour: '',
            flightCount: 0,
            preparedBy: widget.inspection.employee.name,
            reviewedBy: '');
        final publicHallMap =
            PublicHallData(time: '', paxWaiting: 0, ndsArea: '', ndsTime: '');

        final baggageAreaMap = BaggageAreaData(
            belts: [],
            time1: '',
            pax1: 0,
            time2: '',
            pax2: 0,
            time3: '',
            pax3: 0,
            ndsAreaFunction: '');

        arrival = NationalArrival.fromJson({
          ...generalDataMap.toJson(),
          ...publicHallMap.toJson(),
          ...baggageAreaMap.toJson(),
          // 'observations': {
          'observations_event_time': '', 'observations_location': '',
          'observations_description': '', 'observations_consequences': '',
          //'observations_photo': '',
          // }
          'inspection_id': inspectionId,
          //'id': arrivalId,
          //'id': currentArrival?.id ?? 0,
          'synced': 0,
        });
        await service.save(arrival);
        generalKey.currentState?.setData(generalDataMap);
      }
      debugPrint("${arrival.toJson()}");
      ref.read(inspectionProvider.notifier).setInspection(widget.inspection);
      ref
          .read(inspectionDetailsProvider.notifier)
          .setInspectionDetails(arrival);
      generalKey.currentState?.setData(arrival.general);
      hallKey.currentState?.setData(arrival.publicHall);
      baggageAreaKey.currentState?.setData(arrival.baggageArea);
      //baggageTimeKey.currentState?.setData(arrival.baggageTime);
      observationsKey.currentState?.setData(arrival.observations);
    });
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _scrollToCurrentTab();
        setState(() {});
      }
    });
  }

  void _scrollToCurrentTab() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final index = _tabController.index;
      final keyContext = _tabKeys[index].currentContext;
      if (keyContext != null) {
        double alignment;
        if (index == 0) {
          alignment = 0.0;
        } else if (index == _tabController.length - 1) {
          alignment = 1.0;
        } else {
          alignment = 0.5;
        }
        Scrollable.ensureVisible(
          keyContext,
          duration: const Duration(milliseconds: 200), // Ajuste de duración
          curve: Curves.easeInOut,
          alignment: alignment,
        );
      }
    });
  }

  Future<void> _guardarDatos() async {
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      await ref.read(autoSaveServiceProvider).flush();
      final isValidGeneral = generalKey.currentState?.validate() ?? false;
      final isValidHall = hallKey.currentState?.validate() ?? false;
      final isValidArea = baggageAreaKey.currentState?.validate() ?? false;
      //final isValidTime = baggageTimeKey.currentState?.validate() ?? false;
      final isValidObs = observationsKey.currentState?.validate() ?? false;

      if (!isValidGeneral ||
          !isValidHall ||
          !isValidArea ||
          //!isValidTime ||
          !isValidObs) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  '⚠️ Completa todos los campos obligatorios antes de guardar')),
        );
        return;
      }
      final Map<String, dynamic> generalData =
          generalKey.currentState?.getData() ?? {};
      final Map<String, dynamic> hallData =
          hallKey.currentState?.getData() ?? {};
      final Map<String, dynamic> areaData =
          baggageAreaKey.currentState?.getData() ?? {};
      /*final List<ArrivalBaggageTime> timeData =
          baggageTimeKey.currentState?.getData() ?? [];*/
      final Map<String, dynamic> observationsData =
          observationsKey.currentState?.getData() ?? {};
      final currentArrival = ref.read(inspectionDetailsProvider);
      final dataCombined = {
        ...generalData,
        ...hallData,
        ...areaData,
        //'baggage_time_details': timeData.map((e) => e.toMap()).toList(),
        ...observationsData,
        'inspection_id': widget.inspection.id,
        //'id': arrivalId,
        'id': currentArrival?.id ?? 0,
        'synced': 0,
      };
      final arrival = NationalArrival.fromJson(dataCombined);
      final service = ref.read(nationalArrivalServiceProvider);
      await service.save(arrival);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Llegada guardada correctamente')),
      );
    } catch (e, s) {
      debugPrint("${e.toString()} ---- ${s}");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '❌ Se ha producido un error al guardar el arribo nacional')));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parentKey = ValueKey(
      'national-arrival-${widget.inspection.id}',
    );
    return Scaffold(
      appBar: AppBar(
        key: parentKey,
        backgroundColor: Colors.blue,
        elevation: 0,
        title: const Text('Inspección Arribo Nacional',
            style: TextStyle(color: Colors.white)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30.0),
          child: Container(
            color: Colors.yellow[50],
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${DateFormat('dd-MM-yyyy').format(widget.inspection.date!)} (Iniciada: ${DateFormat('HH:mm').format(DateTime.now())})',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: _tabController.index > 0
                      ? () {
                          _tabController.animateTo(
                            _tabController.index - 1, // Ajuste de duración
                            curve: Curves.easeInOut, // Suaviza el cambio
                          );
                          //Future.delayed(const Duration(milliseconds: 300), () {
                          _scrollToCurrentTab();
                          //});
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
                      unselectedLabelColor: Colors.black,
                      indicatorColor: Colors.blue,
                      tabs: [
                        Tab(child: Text('Datos Generales', key: _tabKeys[0])),
                        Tab(child: Text('Hall Público', key: _tabKeys[1])),
                        Tab(
                            child: Text('Retiro de equipaje (ÁREA)',
                                key: _tabKeys[2])),
                        Tab(
                            child: Text('Retiro de equipaje (TIEMPO)',
                                key: _tabKeys[3])),
                        Tab(
                            child: Text('Observaciones y Novedades',
                                key: _tabKeys[4])),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: _tabController.index < _tabController.length - 1
                      ? () {
                          _tabController.animateTo(
                            _tabController.index + 1, // Ajuste de duración
                            curve: Curves.easeInOut, // Suaviza el cambio
                          );

                          _scrollToCurrentTab();
                        }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: IndexedStack(
                index: _tabController.index,
                children: [
                  GeneralDataScreen(
                      key: generalKey, inspection: widget.inspection),
                  PublicHallScreen(key: hallKey, inspection: widget.inspection),
                  ArrivalsBaggageAreaScreen(
                      key: baggageAreaKey, inspection: widget.inspection),
                  ArrivalsBaggageTimeScreen(key: baggageTimeKey),
                  ObservationsScreen(
                      key: observationsKey, inspection: widget.inspection),
                ],
              ),
            ),
          ],
        ),
      ),
      /*
      floatingActionButton: FloatingActionButton.extended(
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
}
