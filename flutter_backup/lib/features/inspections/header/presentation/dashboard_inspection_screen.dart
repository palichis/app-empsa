import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:epmsa_mobile/core/presentation/dashboard_screen.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/international/presentation/international_arrivals_screen.dart';
import 'package:epmsa_mobile/features/inspections/arrivals/national/presentation/national_arrivals_screen.dart';
import 'package:epmsa_mobile/features/inspections/cargo/presentation/cargo_screen.dart';
import 'package:epmsa_mobile/features/inspections/departures/international/presentation/international_departures_screen.dart';
import 'package:epmsa_mobile/features/inspections/departures/national/presentation/national_departures_screen.dart';
import 'package:epmsa_mobile/features/inspections/header/domain/Inspection.dart';
import 'package:epmsa_mobile/features/inspections/header/providers/inspections_providers.dart';
//import 'package:epmsa_mobile/features/inspections/header/services/inspections_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/handlers/sqlite_handler.dart';

class DashboardInspectionScreen extends ConsumerStatefulWidget {
  const DashboardInspectionScreen({super.key});

  @override
  _DashboardInspectionScreenState createState() =>
      _DashboardInspectionScreenState();
}

class _DashboardInspectionScreenState
    extends ConsumerState<DashboardInspectionScreen> {
  bool isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        isOnline = result != ConnectivityResult.none;
      });
    });
  }

  void _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      isOnline = connectivityResult != ConnectivityResult.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    final inspectionsAsync = ref.watch(assignedInspectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspecciones Asignadas',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        /*leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardScreen()),
            );
          },
        ),*/
        actions: [
          Icon(
            isOnline ? Icons.wifi : Icons.wifi_off,
            color: isOnline ? Colors.green : Colors.red,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(inspectionsRepositoryProvider),
            color: Colors.white,
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1024),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Banner de conectividad
                  Container(
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Icon(
                          isOnline ? Icons.check_circle : Icons.error,
                          color: isOnline ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isOnline ? 'Estás en línea' : 'Modo sin conexión',
                          style: TextStyle(
                            color: isOnline ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Lista de inspecciones
                  inspectionsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) {
                      debugPrint('❌ Provider error: $error, $stackTrace');
                      return const Center(
                        child: Text('Error cargando inspecciones'),
                      );
                    },
                    data: (inspections) {
                      if (inspections.isEmpty) {
                        return const Center(
                          child: Text('No hay inspecciones asignadas'),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: inspections.length,
                        itemBuilder: (context, index) {
                          final inspection = inspections[index];
                          return InspectionCard(inspection: inspection);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InspectionCard extends StatefulWidget {
  final Inspection inspection;
  InspectionCard({super.key, required this.inspection});

  @override
  State<InspectionCard> createState() => _InspectionCardState();
}

class _InspectionCardState extends State<InspectionCard> {
  bool isActive=false;
  final sqlite = SqliteHandler();
  List<int> allInspectionsActives=[];

  @override
  void initState() {
    getData();
  }

  void getData() async {
    allInspectionsActives= await sqlite.getInspeccionesActivas();
    setState(() {
    });
  }

  void saveActiveInspection(int idInspection) async {
    final sqlite = SqliteHandler();
    sqlite.saveInspeccionActiva(idInspection);
  }

  String get readableTitle {
    if (widget.inspection.operation == 'none' && widget.inspection.type == 'none') {
      return 'Inspección de Carga';
    }
    final tipo = widget.inspection.type == 'D' ? 'Nacionales' : 'Internacionales';
    final operacion =
        widget.inspection.operation == 'departure' ? 'Salidas' : 'Arribos';
    return 'Inspección $operacion $tipo';
  }

  String get formattedDate {
    final date = widget.inspection.date;
    if (date == null) return '';
    return '${_pad(date.day)}/${_pad(date.month)}/${date.year} - ${_pad(date.hour)}:${_pad(date.minute)} ';
  }

  String _pad(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    isActive = allInspectionsActives.contains(widget.inspection.id);

    return Card(
      //margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      margin: const EdgeInsets.symmetric(
          vertical: 6), // antes: horizontal + vertical

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  switch (widget.inspection.operation) {
                    'departure' => Icons.flight_takeoff,
                    'arrival' => Icons.flight_land,
                    _ => Icons.flight,
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    readableTitle,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Asignada',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(widget.inspection.dateStr ?? '',
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    return ElevatedButton.icon(
                      icon: const Icon(Icons.sync),
                      label: const Text("Sincronizar"),
                      onPressed: () async {
                        if (widget.inspection.id == null) return;
                        showDialog(
                          context: context,
                          barrierDismissible: false, // NO se puede cerrar tocando afuera
                          builder: (context) {
                            return const AlertDialog(
                              content: Row(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(width: 20),
                                  Expanded(
                                    child: Text("Sincronizando..."),
                                  ),
                                ],
                              ),
                            );
                          },
                        );

                        print("SINCRONIZANDO INSPECCION: ${widget.inspection.id}");

                        final synced = await ref
                            .read(inspectionsServiceProvider)
                            .syncInspection(widget.inspection);

                        await ref
                            .read(inspectionsServiceProvider)
                            .syncPhotos(widget.inspection.id!);
                        // Cerrar el popup automáticamente
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(synced
                                  ? 'Sincronización exitosa'
                                  : 'Fallo la sincronización'),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (widget.inspection.id == null) return;
                    saveActiveInspection(widget.inspection.id!);
                    if (widget.inspection.operation == 'none' &&
                        widget.inspection.type == 'none') {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CargoInspectionScreen(inspection: widget.inspection),
                        ),
                      );
                      allInspectionsActives= await sqlite.getInspeccionesActivas();
                      setState(() {});
                    }

                    if (widget.inspection.operation == 'departure' &&
                        widget.inspection.type == 'I') {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InternationalDeparturesScreen(
                              inspection: widget.inspection),
                        ),
                      );
                      allInspectionsActives= await sqlite.getInspeccionesActivas();
                      setState(() {});
                    }

                    if (widget.inspection.operation == 'departure' &&
                        widget.inspection.type == 'D') {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              NationalDeparturesScreen(inspection: widget.inspection),
                        ),
                      );
                      allInspectionsActives= await sqlite.getInspeccionesActivas();
                      setState(() {});
                    }
                    if (widget.inspection.operation == 'arrival' &&
                        widget.inspection.type == 'D') {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              NationalArrivalsScreen(inspection: widget.inspection),
                        ),
                      );
                      allInspectionsActives= await sqlite.getInspeccionesActivas();
                      setState(() {
                      });
                    }
                    if (widget.inspection.operation == 'arrival' &&
                        widget.inspection.type == 'I') {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InternationalArrivalsScreen(
                              inspection: widget.inspection),
                        ),
                      );
                      allInspectionsActives= await sqlite.getInspeccionesActivas();
                      setState(() {});
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? Colors.green[100] : Colors.blue[100],
                  ),
                  child: Text(isActive?'Continuar':'Iniciar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
