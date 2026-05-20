import 'package:epmsa_mobile/features/penalties/domain/penalty_catalog.dart';
import 'package:epmsa_mobile/features/penalties/providers/penalties_amount_provider.dart';
import 'package:epmsa_mobile/features/penalties/providers/penalties_catalog_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PenaltiesCatalogScreen extends ConsumerStatefulWidget {
  const PenaltiesCatalogScreen({super.key});

  @override
  PenaltiesCatalogScreenState createState() => PenaltiesCatalogScreenState();
}

class PenaltiesCatalogScreenState extends ConsumerState<PenaltiesCatalogScreen>
    with SingleTickerProviderStateMixin {
  PenaltyCatalog? _selectedPenaltyCatalog;

  late PageController _pageController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _updateAmount() {
    if (_selectedPenaltyCatalog != null) {
      ref
          .read(penaltyAmountProvider.notifier)
          .updateAmount(_selectedPenaltyCatalog?.parentId);
    }
  }

  Widget _buildPenaltyCatalogList(List<PenaltyCatalog> penaltiesCatalog) {
    return ListView(
      children: penaltiesCatalog.map((penalty) {
        return RadioListTile<PenaltyCatalog>(
          title: Text(penalty.name),
          value: penalty,
          groupValue: _selectedPenaltyCatalog,
          onChanged: (value) {
            setState(() {
              _selectedPenaltyCatalog = value;
              _updateAmount();
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final penaltiesCatalog = ref.watch(penaltiescatalogProvider);

    return PageView(
      controller: _pageController,
      physics: NeverScrollableScrollPhysics(),
      children: [
        Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: "Leves"),
                Tab(text: "Graves"),
                Tab(text: "Muy Graves"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPenaltyCatalogList(
                      penaltiesCatalog.where((p) => p.parentId == 2).toList()),
                  _buildPenaltyCatalogList(
                      penaltiesCatalog.where((p) => p.parentId == 3).toList()),
                  _buildPenaltyCatalogList(
                      penaltiesCatalog.where((p) => p.parentId == 4).toList()),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
