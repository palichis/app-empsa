import 'package:epmsa_mobile/core/providers/users_provider.dart';
import 'package:epmsa_mobile/features/penalties/domain/penalty.dart';
import 'package:epmsa_mobile/features/penalties/domain/penalty_catalog.dart';
import 'package:epmsa_mobile/features/penalties/providers/penalties_amount_provider.dart';
import 'package:epmsa_mobile/features/penalties/providers/penalty_service_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PenaltiesRecordDataScreen extends ConsumerStatefulWidget {
  const PenaltiesRecordDataScreen({super.key});

  @override
  PenaltiesRecordDataScreenState createState() =>
      PenaltiesRecordDataScreenState();
}

class PenaltiesRecordDataScreenState
    extends ConsumerState<PenaltiesRecordDataScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  PenaltyCatalog? _selectedPenaltyCatalog;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _observationsController = TextEditingController();
  late PageController _pageController;
  int _selectedPartnerId = 0;
  String _selectedStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);
    final amount = ref.watch(penaltyAmountProvider);
    final penaltyService = ref.watch(penaltyServiceProvider);

    _amountController.text = amount.toString();

    return Scaffold(
      appBar: AppBar(title: Text('Registrar Penalización')),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: [
          Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  usersAsync.when(
                    data: (users) {
                      return DropdownButtonFormField<int>(
                        decoration: InputDecoration(labelText: 'Infractor'),
                        items: users.map((user) {
                          return DropdownMenuItem<int>(
                            value: user.serverId,
                            child: Text(user.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPartnerId = value ?? 0;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'El Infractor es obligatorio';
                          }
                          return null;
                        },
                      );
                    },
                    loading: () => CircularProgressIndicator(),
                    error: (err, stack) {
                      print(err);
                      return Text("Error al cargar usuarios");
                    },
                  ),
                  TextField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: 'Fecha',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );

                      if (pickedDate != null) {
                        String formattedDate =
                            "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                        _dateController.text = formattedDate;
                      }
                    },
                  ),
                  TextField(
                    controller: _amountController,
                    decoration: InputDecoration(labelText: 'Monto'),
                    keyboardType: TextInputType.number,
                    readOnly: true,
                  ),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Estado'),
                    value: _selectedStatus,
                    items: [
                      DropdownMenuItem(
                          value: 'pending', child: Text('Pendiente')),
                      DropdownMenuItem(value: 'paid', child: Text('Pagada')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'El estado es obligatorio';
                      }
                      return null;
                    },
                  ),
                  TextField(
                    controller: _observationsController,
                    decoration: InputDecoration(labelText: 'Observaciones'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final form = _formKey.currentState;
          if (form != null && form.validate()) {
            final penalty = Penalty(
              id: null,
              partnerId: _selectedPartnerId,
              parentId: _selectedPenaltyCatalog!.parentId ?? 0,
              penaltyId: _selectedPenaltyCatalog!.serverId,
              date: _dateController.text,
              amount: double.tryParse(_amountController.text) ?? 0.0,
              status: _selectedStatus,
              observations: _observationsController.text,
              synced: 0,
            );
            await penaltyService.savePenalty(penalty);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Penalización guardada exitosamente')),
            );
          } else {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Revise los datos del formulario')),
            );
          }
        },
        child: Icon(Icons.save),
      ),
    );
  }
}
