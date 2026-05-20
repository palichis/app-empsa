import 'package:epmsa_mobile/core/presentation/dashboard_screen.dart';
import 'package:epmsa_mobile/features/penalties/presentation/penalties_catalog_screen.dart';
import 'package:epmsa_mobile/features/penalties/presentation/penalties_record_data_screen.dart';
import 'package:epmsa_mobile/features/penalties/providers/penalties_catalog_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PenaltiesScreen extends ConsumerStatefulWidget {
  const PenaltiesScreen({super.key});

  @override
  PenaltiesScreenState createState() => PenaltiesScreenState();
}

class PenaltiesScreenState extends ConsumerState<PenaltiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ValueNotifier<int> amountNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    final penaltiesNotifier = ref.read(penaltiescatalogProvider.notifier);
    penaltiesNotifier.loadPenaltiesCatalog();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Genera una multa"),
          /*leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => DashboardScreen()),
              );
            },
          ),*/
          bottom: TabBar(
            indicatorColor: Colors.blue,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.black,
            tabs: [
              Tab(icon: Icon(Icons.list), text: "Sanciones"),
              Tab(icon: Icon(Icons.edit), text: "Registro"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PenaltiesCatalogScreen(),
            PenaltiesRecordDataScreen(),
          ],
        ),
      ),
    );
  }
}
