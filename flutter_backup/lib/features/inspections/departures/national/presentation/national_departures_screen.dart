import 'package:epmsa_mobile/core/providers/auto_save_provider.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/checkin_counter_area_data.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/checkin_counter_time_data.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/flight_data.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/security_filters_area_data.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/security_filters_time_data.dart';
import 'package:epmsa_mobile/features/inspections/departures/domain/self_checkin_kiosks_data.dart';
import 'package:epmsa_mobile/features/inspections/departures/presentation/preboarding_screen.dart';
import 'package:epmsa_mobile/features/inspections/header/providers/inspections_providers.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/general_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/public_hall_data.dart';
import 'package:epmsa_mobile/features/inspections/shared/presentation/observations_screen.dart';
import 'package:epmsa_mobile/features/inspections/shared/presentation/public_hall_screen.dart';
import 'package:epmsa_mobile/features/inspections/shared/presentation/general_data_screen.dart';
import 'package:epmsa_mobile/features/inspections/departures/national/domain/national_departures.dart';
import 'package:epmsa_mobile/features/inspections/departures/providers/depatures_provider.dart';
import 'package:epmsa_mobile/features/inspections/header/domain/Inspection.dart';
import 'package:flutter/material.dart';
import 'package:epmsa_mobile/features/inspections/departures/presentation/flight_details_screen.dart';
import 'package:epmsa_mobile/features/inspections/departures/presentation/kiosk_screen.dart';
import 'package:epmsa_mobile/features/inspections/departures/presentation/checkin_screen.dart';
import 'package:epmsa_mobile/features/inspections/departures/presentation/security_filters_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NationalDeparturesScreen extends ConsumerStatefulWidget {
  final Inspection inspection;

  const NationalDeparturesScreen({super.key, required this.inspection});

  @override
  NationalDeparturesScreenState createState() =>
      NationalDeparturesScreenState();
}

class NationalDeparturesScreenState
    extends ConsumerState<NationalDeparturesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _tabScrollController = ScrollController();
  final List<GlobalKey> _tabKeys = List.generate(8, (_) => GlobalKey());
  /*final generalKey = GlobalKey<GeneralDataScreenState>();
  final flightKey = GlobalKey<FlightDetailsScreenState>();
  final hallKey = GlobalKey<PublicHallScreenState>();
  final kioskKey = GlobalKey<SelfCheckinKiosksScreenState>();
  final checkinKey = GlobalKey<CheckinScreenState>();
  final securityKey = GlobalKey<SecurityFiltersScreenState>();
  final boardingKey = GlobalKey<PreboardingScreenState>();
  final observationsKey = GlobalKey<ObservationsScreenState>();*/
  late GlobalKey<GeneralDataScreenState> generalKey;
  late GlobalKey<FlightDetailsScreenState> flightKey;
  late GlobalKey<PublicHallScreenState> hallKey;
  late GlobalKey<SelfCheckinKiosksScreenState> kioskKey;
  late GlobalKey<CheckinScreenState> checkinKey;
  late GlobalKey<SecurityFiltersScreenState> securityKey;
  late GlobalKey<PreboardingScreenState> boardingKey;
  late GlobalKey<ObservationsScreenState> observationsKey;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    final id = widget.inspection.id;
    generalKey = GlobalKey<GeneralDataScreenState>(debugLabel: 'general-$id');
    flightKey = GlobalKey<FlightDetailsScreenState>(debugLabel: 'flight-$id');
    hallKey = GlobalKey<PublicHallScreenState>(debugLabel: 'hall-$id');
    kioskKey = GlobalKey<SelfCheckinKiosksScreenState>(debugLabel: 'kiosk-$id');
    checkinKey = GlobalKey<CheckinScreenState>(debugLabel: 'checkin-$id');
    securityKey =
        GlobalKey<SecurityFiltersScreenState>(debugLabel: 'security-$id');
    boardingKey = GlobalKey<PreboardingScreenState>(debugLabel: 'boarding-$id');
    observationsKey =
        GlobalKey<ObservationsScreenState>(debugLabel: 'observations-$id');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _scrollToCurrentTab();
      final service = ref.read(NationaldeparturesServiceProvider);
      final inspectionId = widget.inspection.id;
      NationalDepartures? departure =
          await service.loadNationalDepartureForInspection(inspectionId!);
      print(
          '📦 Inspección $inspectionId cargada desde SQLite: ${departure?.id}');

      if (departure == null) {
        final generalDataMap = GeneralData(
            measurementDate: widget.inspection.date!,
            peakHour: '',
            flightCount: 0,
            preparedBy: widget.inspection.employee.name,
            reviewedBy: '');
        final publicHallMap =
            PublicHallData(time: '', paxWaiting: 0, ndsArea: '', ndsTime: '');
        final flightMap = FlightData(
            flightActualDepartureTime: '',
            //flightCheckCounterNumber: [],
            flightCount: 0,
            //flightNumbers: [],
            flightPaxNumber: 0,
            //flightPreboardingRoom: [],
            flightScheduledTime: '');
        final selfCheckinKioskMap = SelfCheckinKiosksData(
          selfCheckinKiosksTime: '',
          selfCheckinKiosksServiceTimePerPax1: '',
          selfCheckinKiosksServiceTimePerPax2: '',
          selfCheckinKiosksAverage: '',
          selfCheckinKiosksMaximumWaitingTime: '',
          selfCheckinKiosksNdsTimeFunction: '',
        );
        final checkinCounterAreaMap = CheckinCounterAreaData(
            checkinCounterTime: '',
            checkinCounterAssignedCountersZone: '',
            checkinCounterAssignedCounters: 0,
            checkinCounterOperatingCounters: 0,
            checkinCounterPaxWaitingArea: 0,
            checkinCounterOfflineTime: '');

        final checkinCounterTimeMap = CheckinCounterTimeData(
          checkinCounterAttentionTimePerPax1: '',
          checkinCounterAttentionTimePerPax2: '',
          checkinCounterAttentionTimePerPax3: '',
          checkinCounterAttentionTimePerPax4: '',
          checkinCounterAttentionTimePerPax5: '',
          checkinCounterAttentionTimePerPaxMax: '',
        );
        final securityFiltersAreaMap = SecurityFiltersAreaData(
            securityFiltersTime: '',
            securityFiltersObservedDomesticOperators: 0,
            securityFiltersObservedInternationalOperators: 0,
            securityFiltersObservedDocumentReviewAgents: 0,
            securityFiltersPaxWaitingArea: 0,
            securityFiltersOfflineTime: '');
        final securityFiltersTimeMap = SecurityFiltersTimeData(
          securityFiltersAttentionTimePerPax1: '',
          securityFiltersAttentionTimePerPax2: '',
          securityFiltersAttentionTimePerPax3: '',
          securityFiltersAttentionTimePerPax4: '',
          securityFiltersAttentionTimePerPax5: '',
        );
        departure = NationalDepartures.fromJson({
          ...generalDataMap.toJson(),
          ...publicHallMap.toJson(),
          ...flightMap.toJson(),
          ...selfCheckinKioskMap.toJson(),
          ...checkinCounterAreaMap.toJson(),
          ...checkinCounterTimeMap.toJson(),
          ...securityFiltersAreaMap.toJson(),
          ...securityFiltersTimeMap.toJson(),
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

        await service.save(departure);
        generalKey.currentState?.setData(generalDataMap);
      }
      debugPrint("${departure.toJson()}");
      ref.read(inspectionProvider.notifier).setInspection(widget.inspection);
      ref
          .read(inspectionDetailsProvider.notifier)
          .setInspectionDetails(departure);
      generalKey.currentState?.setData(departure.general);
      hallKey.currentState?.setData(departure.publicHall);
      observationsKey.currentState?.setData(departure.observations);
      flightKey.currentState?.setData(departure.flight);
      kioskKey.currentState?.setData(departure.selfCheckinKiosks);
      checkinKey.currentState
          ?.setData(departure.checkinCounterArea, departure.checkinCounterTime);
      securityKey.currentState?.setData(
          departure.securityFiltersArea, departure.securityFiltersTime);
    });
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _scrollToCurrentTab();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _scrollToCurrentTab() {
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: alignment,
      );
    }
  }

  Future<void> _guardarDatos() async {
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      await ref.read(autoSaveServiceProvider).flush();
      final Map<String, dynamic> generalData =
          generalKey.currentState?.getData() ?? {};
      final Map<String, dynamic> hallData =
          hallKey.currentState?.getData() ?? {};

      final Map<String, dynamic> flightData =
          flightKey.currentState?.getData() ?? {};
      final Map<String, dynamic> checkinData =
          checkinKey.currentState?.getData() ?? {};
      final Map<String, dynamic> kiosksData =
          await kioskKey.currentState?.getData() ?? {};
      final Map<String, dynamic> securityData =
          securityKey.currentState?.getData() ?? {};
      final Map<String, dynamic> observationsData =
          observationsKey.currentState?.getData() ?? {};

      final currentArrival = ref.read(inspectionDetailsProvider);

      final Map<String, dynamic> dataCombined = {
        ...generalData,
        ...hallData,
        ...flightData,
        ...checkinData,
        ...kiosksData,
        ...securityData,
        ...observationsData,
        'inspection_id': widget.inspection.id,
        //'id': arrivalId,
        'id': currentArrival?.id ?? 0,
        'synced': 0,
      };
      final departure = NationalDepartures.fromJson(dataCombined);
      final service = ref.read(NationaldeparturesServiceProvider);
      await service.save(departure);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Llegada guardada correctamente')),
      );
    } catch (e, st) {
      debugPrint('❌ Error guardando salida nacional: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar datos')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final parentKey = ValueKey(
      'national-departure-${widget.inspection.id}',
    );
    return Scaffold(
      appBar: AppBar(
        key: parentKey,
        backgroundColor: Colors.blue,
        elevation: 0,
        title: const Text('Inspección Salida Nacional',
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
                          _tabController.animateTo(_tabController.index - 1);
                          _scrollToCurrentTab();
                          setState(() {});
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
                        Tab(text: 'Datos Generales', key: _tabKeys[0]),
                        Tab(text: 'Datos del Vuelo', key: _tabKeys[1]),
                        Tab(text: 'Hall Público', key: _tabKeys[2]),
                        Tab(text: 'Quioscos', key: _tabKeys[3]),
                        Tab(text: 'Check-in', key: _tabKeys[4]),
                        Tab(text: 'Filtros de Seguridad', key: _tabKeys[5]),
                        Tab(text: 'Salas de Pre-Embarque', key: _tabKeys[6]),
                        Tab(text: 'Observaciones', key: _tabKeys[7]),
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
                          setState(() {});
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
                  FlightDetailsScreen(
                      key: flightKey, inspection: widget.inspection),
                  PublicHallScreen(key: hallKey, inspection: widget.inspection),
                  SelfCheckinKiosksScreen(
                      key: kioskKey, inspection: widget.inspection),
                  CheckinScreen(key: checkinKey, inspection: widget.inspection),
                  SecurityFiltersScreen(
                      key: securityKey, inspection: widget.inspection),
                  PreboardingScreen(
                      key: boardingKey, inspection: widget.inspection),
                  ObservationsScreen(
                      key: observationsKey, inspection: widget.inspection)
                ],
              ),
            ),
          ],
        ),
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
}
