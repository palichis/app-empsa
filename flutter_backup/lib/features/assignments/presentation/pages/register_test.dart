import 'dart:convert';
import 'dart:io';

import 'package:epmsa_mobile/core/presentation/confirm_dialog.dart';
import 'package:epmsa_mobile/features/assignments/data/model/entities/employee_dto.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/presentation/custom_alert.dart';
import '../../../novedades/presentation/pages/create_inspection_bottom_sheet.dart';
import '../../data/datasource/inspections_local_ds.dart';
import '../../data/datasource/inspectios_remote_ds.dart';
import '../../data/model/entities/area_dto.dart';
import '../../data/model/entities/nationality_dto.dart';
import '../../data/model/entities/process_dto.dart';
import '../../data/repository/areas_repository.dart';
import '../../data/repository/nationalities_repository.dart';
import '../../data/repository/process_repository.dart';
import '../../domain/model/photo_item.dart';
import '../../presentation/widgets/dates_test_card.dart';
import '../../presentation/widgets/kind_test_card.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/model/task_dto.dart';
import '../model/auditoria_test_dto.dart';
import '../widgets/cabezera_test.dart';
import '../widgets/item_test_card.dart';
import '../widgets/observations_test_card.dart';
import '../widgets/passenger_info_test_card.dart';
import '../widgets/take_pictures.dart';

class RegisterTest extends StatefulWidget {
  final VoidCallback? onClose;
  final TaskDto taskDto;

  const RegisterTest({
    Key? key,
    this.onClose,
    required this.taskDto,
  }) : super(key: key);

  @override
  _RegisterTestState createState() {
    return _RegisterTestState();
  }
}

class _RegisterTestState extends State<RegisterTest> {
  List<ProcessDto> allProcess = [];
  List<AreaDto> allAreas = [];
  List<NationalityDto> allNationalities = [];
  List<EmployeeDto> allEmployees = [];
  String tipoPrueba='equipment';
  TextEditingController marca= TextEditingController();
  TextEditingController modelo=TextEditingController();
  TextEditingController _lugarOcultamientoSeleccionado = TextEditingController();
  Deteccion _deteccionSeleccionada = Deteccion.no;
  OpcionSiNo _accionCorrectiva=OpcionSiNo.no;
  TextEditingController _nombreColaborador = TextEditingController();
  NationalityDto? _nacionalidad;
  TextEditingController _cvppt = TextEditingController();
  OpcionSiNo _firmaCarta=OpcionSiNo.no;
  TextEditingController _correo = TextEditingController();
  TextEditingController _observaciones = TextEditingController();
  TextEditingController _recomendaciones = TextEditingController();
  AreaDto? areaSelected;
  EmployeeDto? employeeDtoSelectd;
  DateTime fechaSelected= DateTime.now();
  TimeOfDay horaSelected = TimeOfDay.now();
  List<PhotoItem> _photos = [];

  @override
  void initState() {
    super.initState();
    getRemoteData();
    getLocalData();
  }

  void getRemoteData() async {
    allProcess = await ProcessRepository.fetchProcess();
    allAreas = await AreasRepository().fetchAreas();
    areaSelected=allAreas.first;
    allNationalities = await NationalitiesRepository().fetchNationalities();
    _nacionalidad=allNationalities.first;
    allEmployees = await NationalitiesRepository().fetchEmployees();
    employeeDtoSelectd=allEmployees.first;
    employeeDtoSelectd=allEmployees.first;
    setState(() {
    });
  }

  void getLocalData() async {
    Map<String, dynamic>? aux=await InspectionsLocalDS().getTestById(widget.taskDto.id);
    if(aux!=null){
      AuditoriaTestDto testLolcal = AuditoriaTestDto.fromJson(jsonDecode(aux['json_prueba']));

      marca.text=testLolcal.brand;
      modelo.text=testLolcal.model;
      _lugarOcultamientoSeleccionado.text =testLolcal.hidingSite;//=='yes'?;
      _accionCorrectiva=testLolcal.correctiveAction=='yes'?OpcionSiNo.si:OpcionSiNo.no;
      _nombreColaborador.text = testLolcal.collaboratorName;
    //  NationalityDto? _nacionalidad;
      _cvppt.text = testLolcal.collaboratorIdentity;
      _firmaCarta=testLolcal.autorization=='yes'?OpcionSiNo.si:OpcionSiNo.no;
      _correo.text =testLolcal.collaboratorEmail;
      _observaciones.text = testLolcal.observation;
      _recomendaciones.text = testLolcal.recomendation;
      print(_recomendaciones);
      /*AreaDto? areaSelected;
      EmployeeDto? employeeDtoSelectd;*/
      fechaSelected=DateTime.parse(testLolcal.dateTest);
      try {
        String horaStr = testLolcal
            .timeTest; // <-- contiene un U+202F en vez de espacio normal

        // 1. Reemplazar el caracter U+202F (narrow no-break space) por espacio normal
        horaStr = horaStr.replaceAll('\u202F', ' ');

        // 2. Por seguridad, normalizar otros posibles espacios raros
        horaStr = horaStr.replaceAll(RegExp(r'\s+'), ' ').trim();

        // 3. Parsear con intl
        DateTime dateTime = DateFormat.jm().parse(horaStr);

        // 4. Convertir a TimeOfDay
        horaSelected = TimeOfDay.fromDateTime(dateTime);
      }catch(e){
        print(e);
      }


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
                      Text(widget.taskDto.title,
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
            ), //title
            Expanded(
              child: ListView(
                children: [
                  CabezeraTest(
                    numeroPrueba: widget.taskDto.description,
                    version: widget.taskDto.version ?? '',
                    codigo: widget.taskDto.code,
                    fecha: widget.taskDto.date,
                  ),
                  SizedBox(height: 10),
                  ItemCard(
                    items: widget.taskDto.itemIds,
                    lugarOcultamientoSeleccionado: _lugarOcultamientoSeleccionado,
                    onChanged: (lugar, deteccion) {
                      setState(() {
                      //  _lugarOcultamientoSeleccionado = lugar;
                        _deteccionSeleccionada = deteccion;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  Card(
                      elevation: 4,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.green,
                                      size: 25,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      'Datos de la Prueba',
                                      style: AppTextStyles.titleBoldBlack,
                                    )
                                  ],
                                ),
                                Text(
                                    'Información editable sobre la ejecución de la prueba',
                                    style: AppTextStyles.subTitleGrey)
                              ],
                            ),
                            DatesTestCard(
                              allAreas: allAreas,
                              onFechaChanged: (value) {
                                fechaSelected = value!;
                              },
                              onHoraChanged: (value) {
                                horaSelected=value!;
                              },
                              onLugarChanged: (value) {
                                areaSelected = value;
                              },
                              resultadoInicial: "Prueba superada.",
                              onResultadoChanged: (nuevo) {
                                print("El usuario seleccionó: $nuevo");
                              },
                            ),
                            KindTestCard(
                              tipoPrueba: tipoPrueba,
                              agente: employeeDtoSelectd,
                              marca: marca,
                              modelo: modelo,
                              allEmployeeDto: allEmployees,
                              onTipoPruebaChanged: (val) =>
                                  setState(() => tipoPrueba = val!),
                              onAgenteChanged: (val) => setState(() => employeeDtoSelectd = val!),
                              onMarcaChanged: (val){setState(() => marca.text = val);},
                              onModeloChanged: (val) => setState(() => modelo.text = val),
                            ),
                            PassengerInfoCard(
                              nationalities: allNationalities,
                              nombreColaborador: _nombreColaborador,
                              cvppt: _cvppt,
                              correo: _correo,
                              onChanged: ({
                                required accionCorrectiva,
                                required nombreColaborador,
                                required nacionalidad,
                                required cvppt,
                                required firmaCarta,
                                required correo,
                              }) {
                                // Actualiza el estado del widget padre con los valores recibidos
                                setState(() {
                                  _accionCorrectiva = accionCorrectiva??OpcionSiNo.no;
                                 // _nombreColaborador = nombreColaborador;
                                  _nacionalidad = nacionalidad;
                                //  _cvppt = cvppt;
                                  _firmaCarta = firmaCarta??OpcionSiNo.no;
                                //  _correo = correo;
                                });
                              },
                            ),
                            ObservationsCard(
                              onChanged: ({
                                required observaciones,
                                required recomendaciones,
                              }) {
                                setState(() {
                                });
                              },
                              observacionesController: _observaciones,
                              recomendacionesController: _recomendaciones,
                            ),
                          ],
                        ),
                      )),

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
                  actionsCard(),
                ],
              ),
            ),
          ],
        ));
  }

  Widget actionsCard() {
    bool puedeEnviar = true;

    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pending_actions_outlined,
                  color: Colors.blue,
                ),
                SizedBox(width: 10),
                const Text(
                  "Acciones",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                InspectionsLocalDS().sendTest(
                    id: widget.taskDto.id,
                    autorization: _firmaCarta==OpcionSiNo.si,
                    brand: marca.text,
                    collaborator_email: _correo.text,
                    collaborator_identity: _cvppt.text,
                    collaborator_nacionality: _nacionalidad!=null?_nacionalidad!.id:1,
                    collaborator_name: _nombreColaborador.text,
                    corrective_action: _accionCorrectiva==OpcionSiNo.si,
                    date_test: DateFormat('yyyy-MM-dd').format(fechaSelected),
                    detected: _accionCorrectiva==OpcionSiNo.si,
                    hiding_site: _lugarOcultamientoSeleccionado.text,
                    model: modelo.text,
                    observation: _observaciones.text,
                    recomendation: _recomendaciones.text,
                    site_test: areaSelected!=null?areaSelected!.id:0,
                    time_test: horaSelected.format(context),
                    type:tipoPrueba,
                    madeTo: employeeDtoSelectd!.id,
                    photos: _photos
                );
                showResultDialog(
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
                bool? isAccepted = await showConfirmDialog(
                  context: context,
                  title: "Atención",
                  description: "Al enviar el formulario, no podrá realizar cambios.\n¿Confirma que los datos son correctos y que ha registrado todas las novedades?",
                );

                if (puedeEnviar && (isAccepted ?? false)) {
                  await InspectionsRemoteDS().sendTest(
                    id: widget.taskDto.id,
                    autorization: _firmaCarta==OpcionSiNo.si,
                    brand: marca.text,
                    collaborator_email: _correo.text,
                    collaborator_identity: _cvppt.text,
                    collaborator_nacionality: _nacionalidad!=null?_nacionalidad!.id:1,
                    collaborator_name: _nombreColaborador.text,
                    corrective_action: _accionCorrectiva==OpcionSiNo.si,
                    date_test: DateFormat('yyyy-MM-dd').format(fechaSelected),
                    detected: _accionCorrectiva==OpcionSiNo.si,
                    hiding_site: _lugarOcultamientoSeleccionado.text,
                    model: modelo.text,
                    observation: _observaciones.text,
                    recomendation: _recomendaciones.text,
                    site_test: areaSelected!=null?areaSelected!.id:0,
                    time_test: horaSelected.format(context),
                    type:tipoPrueba,
                    madeTo: employeeDtoSelectd!.id,
                    photos: _photos
                  );
                  await showResultDialog(
                    context: context,
                    success: true,
                    title: "Éxito",
                    description: "La prueba se ha enviado exitosamente.",
                  );
                   widget.onClose!.call();
                }
              },
              icon: const Icon(Icons.send_outlined),
              label: const Text("Enviar prueba"),
              style: ElevatedButton.styleFrom(
                backgroundColor: puedeEnviar ? Colors.blue : Colors.grey,
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
}
