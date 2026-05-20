import 'dart:convert';
import 'dart:io';

import 'package:epmsa_mobile/features/assignments/data/datasource/inspections_local_ds.dart';
import 'package:epmsa_mobile/features/assignments/data/datasource/inspectios_remote_ds.dart';
import 'package:flutter/material.dart';

import '../../../../core/presentation/confirm_dialog.dart';
import '../../../../core/presentation/custom_alert.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../novedades/presentation/pages/create_inspection_bottom_sheet.dart';
import '../../domain/model/photo_item.dart';
import '../../domain/model/task_dto.dart';
import '../widgets/progress_evaluation_card.dart';
import '../widgets/register_evaluacion_card.dart';
import '../widgets/take_pictures.dart';

class RegisterInspection extends StatefulWidget {
  final VoidCallback? onClose;
  final TaskDto taskDto;

  const RegisterInspection({
    Key? key,
    this.onClose,
    required this.taskDto,
  }) : super(key: key);

  @override
  _RegisterInspectionState createState() {
    return _RegisterInspectionState();
  }
}

class _RegisterInspectionState extends State<RegisterInspection> {
  Map<int,String> evaluationsRequirementIds=Map();
  List<PhotoItem> _photos = [];

  @override
  void initState() {
    super.initState();
    for(var a in widget.taskDto.inspectionRequirementIds){
      evaluationsRequirementIds[a[0]]='';
    }
    getLocalData();
  }

  void getLocalData() async {
    Map<String, dynamic>? aux=await InspectionsLocalDS().getInspectionById(widget.taskDto.id);
    if(aux!=null){
      final decoded = jsonDecode(aux['json_inspeccion']!);

      final List requirements = decoded['inspection_requirement_ids'];
      const Map<String, String> qualificationMap = {
        "Satifactory": "Satisfactorio",
        "Unsatisfactory": "Poco satisfactorio",
        "Notcomply": "No cumple",
        "Notapply": "No aplica",
        "Notobserved": "No observado",
      };

      for (var req in requirements)
        evaluationsRequirementIds[req['id']]=qualificationMap[req['qualification']]??'';

      tecObservations.text=decoded['observations'];

      final decodedPhotos = jsonDecode(aux['json_photos']!);
      final List<dynamic> photosList = decodedPhotos['photos'];

      if (photosList.isNotEmpty)
        _photos = photosList.map((photoMap) {
          print( photoMap['note']);
          return PhotoItem(
            file: File(photoMap['filePath']), // ruta completa
            caption: photoMap['note'] ?? '',
          );
        }).toList();
    }
    setState(() {
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<List<dynamic>> elements = widget.taskDto.inspectionRequirementIds;
    int completed=0;
    for(var a in evaluationsRequirementIds.values){
      if(a!=''){
        completed++;
      }
    }
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Quita el foco del TextField
      },
      child: Column(
        children: [
          Container(
            child: Row(
              children: [
                InkWell(
                  child: Icon(Icons.arrow_back),
                  onTap: widget.onClose,
                ),
                SizedBox(
                  width: 20,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.taskDto.description,
                        style: AppTextStyles.titleBoldBlack),
                    Text(widget.taskDto.code,
                        style: AppTextStyles.subTitleGrey)
                  ],
                ),
                Spacer(),
                OutlinedButton.icon(
                  onPressed: (){
                    showModalBottomSheet(
                      context: context,
                      isDismissible: true,
                      elevation: 4,
                      isScrollControlled: true,
                      builder: (context) => Builder(
                          builder: (context) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(context).viewInsets.bottom,
                              ),
                              child: CreateInspectionBottomSheet(isInspection: widget.taskDto.isInspection,testInspectionId: widget.taskDto.id,),
                            );
                          }
                      ),

                    );
                  },
                  icon: const Icon(Icons.warning_amber_rounded,color: Colors.white,size: 23,),
                  label: const Text("Reportar",style: AppTextStyles.subTitleWhiteBold),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.only(top: 5,bottom: 5,left: 10,right: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(width: 10)
              ],
            ),
          ),
          ProgressEvaluationCard(completados: completed,total: evaluationsRequirementIds.values.length,),
          Expanded(
            child: ListView(
              children: [
                ...elements.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return EvaluacionCard(
                    item: 'Ítem ${index + 1}',
                    titulo: '${item[0]}',
                    descripcion: item[1],
                    selectedValue: evaluationsRequirementIds[item[0]],
                    onChanged: (value) {
                      setState(() {
                        evaluationsRequirementIds[item[0]] = value!;
                      });
                    },
                  );
                }).toList(),
                observationsCard(),
                TakePictures(
                  images: _photos,
                  onAddPhoto: (file) {
                    setState(() => _photos.add(file));
                  },
                  onRemovePhoto: (file) {
                    setState(() => _photos.remove(file));
                  },
                ),
                SizedBox(height: 10),
                actionsCard()
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget actionsCard(){
    bool puedeEnviar=true;
    for(var a in evaluationsRequirementIds.values){
      if(a==''){
        puedeEnviar=false;
      }
    }

    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Acciones",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                InspectionsLocalDS().sendInspection(widget.taskDto.id,
                    tecObservations.text, evaluationsRequirementIds,
                    photos: _photos);
                await showResultDialog(
                  context: context,
                  success: true,
                  title: "Éxito",
                  description: "Guardado exitoso",
                );
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text("Guardar borrador"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                if(puedeEnviar){
                  bool? isAccepted = await showConfirmDialog(
                    context: context,
                    title: "Atención",
                    description: "Al enviar el formulario, no podrá realizar cambios.\n¿Confirma que los datos son correctos y que ha registrado todas las novedades?",
                  );
                  if(isAccepted ?? false) {
                    InspectionsRemoteDS().sendInspection(
                        widget.taskDto.id, tecObservations.text,
                        evaluationsRequirementIds, photos: _photos);
                    await showResultDialog(
                      context: context,
                      success: true,
                      title: "Éxito",
                      description: "La inspección se ha enviado exitosamente",
                    );
                    widget.onClose!.call();
                  }
                }
              },
              icon: const Icon(Icons.send_outlined),
              label: const Text("Enviar inspección"),
              style: ElevatedButton.styleFrom(
                backgroundColor: puedeEnviar?Colors.blue:Colors.grey,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 8),
            if (!puedeEnviar)
              const Text(
                "Completa todas las evaluaciones para enviar",
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  TextEditingController tecObservations=TextEditingController();
  Widget observationsCard(){
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Observaciones Generales",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Comentarios generales sobre toda la inspección",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tecObservations,
              maxLines: 5,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText: "Escribe observaciones generales sobre la inspección...",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}