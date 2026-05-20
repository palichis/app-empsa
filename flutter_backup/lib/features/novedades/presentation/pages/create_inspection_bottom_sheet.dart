import 'package:flutter/material.dart';
import '../../data/datasource/novelty_remote_ds.dart';
import '../../data/model/criticality_dto.dart';
import '../../data/model/categories_dto.dart';
import '../../../../core/presentation/custom_alert.dart';
import '../../../../core/theme/app_theme.dart';


class CreateInspectionBottomSheet extends StatefulWidget {
  final bool isInspection;
  final int testInspectionId;

  const CreateInspectionBottomSheet({
    Key? key,
    required bool this.isInspection,
    required int this.testInspectionId
  }) : super(key: key);

  @override
  State<CreateInspectionBottomSheet> createState() =>
      _CreateInspectionBottomSheetState();
}

class _CreateInspectionBottomSheetState extends State<CreateInspectionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _incidentDateTime = DateTime.now();
  String? _name;
  String? _description;
  String? _place;
  DateTime _date = DateTime.now();

  List<CategoriesDTO> _allCategories=[];
  List<CriticalityDTO> _allCriticality=[];
  CategoriesDTO _selectedCategorie= CategoriesDTO(id: -1,name: '');
  CriticalityDTO _selectedCriticali= CriticalityDTO(id: -1,name: '');

  bool _loading = false;


  @override
  void initState() {
    super.initState();
    getData();
  }

  void getData() async {
    NoveltyRemoteDS nrds=NoveltyRemoteDS();
    _allCategories = await nrds.fetchCategories();
    _selectedCategorie=_allCategories.first;
    _allCriticality = await nrds.fetchCriticality();
    _selectedCriticali=_allCriticality.first;
    setState(() {

    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ) return;
    _formKey.currentState!.save();
    setState(() => _loading = true);
    try {
      bool syncResult = await NoveltyRemoteDS().syncNovelty(
        name: _name!,
        description: _description!,
        date: _date.toIso8601String(),
        categoryId: _selectedCategorie.id,
        criticalityId: _selectedCriticali.id, // valor por defecto
        place: _place ?? '',
        inspectionId: widget.testInspectionId,
        isInspection: widget.isInspection,
      );

      Navigator.of(context).pop();
      await showResultDialog(
        context: context,
        success: syncResult,
        title: syncResult?"Éxito":"Error",
        description: syncResult?"Reporte generado exitosamente":"Hubo un problema al crear el reporte.",
      );
    } catch (e) {
      print(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Formatea la fecha para mostrar en el TextField
  String _formatDateForDisplay(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  // Formatea la fecha al formato que espera el backend: "YYYY-MM-DDTHH:mm:ss"
  String _formatDateForBackend(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    final ss = d.second.toString().padLeft(2, '0');
    return '$y-$m-$day\T$hh:$mm:$ss';
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initialDate = _incidentDateTime ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate == null) return; // el usuario canceló

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (pickedTime == null) {
      // Si cancela el timePicker, asumimos 00:00 o dejamos la fecha previa.
      setState(() {
        _incidentDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          initialDate.hour,
          initialDate.minute,
        );
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Wrap(
            children: [
              Center(
                child: Text("Nueva Novedad",
                    style: AppTextStyles.titleBoldBlack,textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // Nombre
              TextFormField(
                decoration: const InputDecoration(labelText: "Título"),
                validator: (v) => v == null || v.isEmpty ? "Campo requerido" : null,
                onSaved: (v) => _name = v,
              ),

              // Descripción
              TextFormField(
                decoration: const InputDecoration(labelText: "Descripción"),
                validator: (v) => v == null || v.isEmpty ? "Campo requerido" : null,
                onSaved: (v) => _description = v,
                maxLines: 2,
              ),

              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Fecha y hora del incidente",
                  hintText: _incidentDateTime != null
                      ? _formatDateForDisplay(_incidentDateTime!)
                      : "Seleccionar fecha y hora",
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                validator: (_) =>
                _incidentDateTime == null ? 'Fecha requerida' : null,
                onTap: _pickDateTime,
                controller: TextEditingController(
                    text: _incidentDateTime != null
                        ? _formatDateForDisplay(_incidentDateTime!)
                        : ''),
              ),

              // Lugar
              TextFormField(
                decoration: const InputDecoration(labelText: "Lugar"),
                validator: (v) => v == null || v.isEmpty ? "Campo requerido" : null,
                onSaved: (v) => _place = v,
              ),

              const SizedBox(height: 12),

              // Categoría
              Container(
                width: double.maxFinite,
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<CategoriesDTO>(
                        decoration: const InputDecoration(labelText: "Categoría"),
                        value: _selectedCategorie,
                        items: _allCategories!
                            .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat.name),
                        ))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedCategorie = value!),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: DropdownButtonFormField<CriticalityDTO>(
                        decoration: const InputDecoration(labelText: "Criticidad"),
                        value: _selectedCriticali,
                        items: _allCriticality
                            .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat.name),
                        ))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedCriticali = value!),
                      ),
                    ),
                  ],
                ),
              ),


              const SizedBox(height: 10),

Container(
                margin: EdgeInsets.only(top: 10),
                    width: double.maxFinite,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: (){
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                            ),
                            label: const Text("Cancelar",style: TextStyle(color: Colors.black),),
                          ),
                          SizedBox(width: 20),
                          ElevatedButton.icon(
                                        onPressed: _submit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                        ),
                                        icon: const Icon(Icons.send,color: Colors.white,),
                                        label: const Text("Enviar",style: TextStyle(color: Colors.white),),
                                      ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
