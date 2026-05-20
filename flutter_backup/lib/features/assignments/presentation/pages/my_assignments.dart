import 'package:epmsa_mobile/features/assignments/domain/usecases/inspectios_uc.dart';
import 'package:epmsa_mobile/features/assignments/presentation/pages/register_inspection.dart';
import 'package:epmsa_mobile/features/assignments/presentation/pages/register_test.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../novedades/presentation/pages/create_inspection_bottom_sheet.dart';
import '../../domain/model/task_dto.dart';
import '../widgets/status_card.dart';
import '../widgets/task_card.dart';

enum Pages { assigned, inspection, test, report }

class MyAssignments extends StatefulWidget {

  @override
  _MyAssignmentsState createState() {
    return _MyAssignmentsState();
  }
}

class _MyAssignmentsState extends State<MyAssignments> {
  List<TaskDto> tasks=[];
  Pages selectedPage=Pages.assigned;
  @override
  void initState() {
    super.initState();
    getData();
  }

  void getData() async {
    tasks= await InspectionsUC().getAllInspections();
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  TaskDto? selectedInspection;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: bodyRegisterInspectionOrTest(),
    );
  }

  Widget bodyMyAssignments(){
    return ListView(
      children: [
        Text('Mis Asignaciones',style: AppTextStyles.titleBoldBlack,),
        Text('Gestiona todas tus inspecciones y pruebas asignadas',style: AppTextStyles.subTitleGrey,),
        SizedBox(height: 10),
        rowResumeCards(),
        gridTasksCards(),
      ],
    );
  }

  Widget bodyRegisterInspectionOrTest(){
    switch (selectedPage){
      case Pages.inspection:
        return RegisterInspection(
          taskDto: selectedInspection!,
          onClose: () {
            selectedPage=Pages.assigned;
            setState(() {
            });
            getData();
          },
        );
      case Pages.test:
        return RegisterTest(
          taskDto: selectedInspection!,
          onClose: () {
            selectedPage=Pages.assigned;
            setState(() {
            });
            getData();
          },
        );
      case Pages.assigned:
        return bodyMyAssignments();
      default: return Center();
    }
  }


  Widget gridTasksCards(){
   // tasks=[task,task,task,task,task];
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth < 600 ? 1 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 4 / 3,
          ),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            return
              TaskCard(
                task: tasks[index],
                onOpen: () {
                  selectedInspection=tasks[index];
                  selectedPage= tasks[index].isInspection?Pages.inspection:Pages.test;
                  setState(() {
                  });
                },
                onReport: () {
                //  selectedPage=Pages.report;
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
                          child: CreateInspectionBottomSheet(isInspection: tasks[index].isInspection,testInspectionId: tasks[index].id,),
                        );
                      }
                    ),

                  );
                },
            );
          },
        );
      },
    );
  }

  Widget rowResumeCards(){
    return Container(
      width: double.maxFinite,
      child: Row(
        children: [
          Expanded(child: StatusCard(color: Colors.yellow[600]!, text: 'Pendientes',number: tasks.length,icon: Icons.access_time_rounded,)),
          SizedBox(width: 20),
          Expanded(child: StatusCard(color: Colors.blue[600]!, text: 'En Progreso',number: 0,icon: Icons.check_circle_outline,)),
      /*    SizedBox(width: 20),
          Expanded(child: StatusCard(color: Colors.green[600]!, text: 'Enviadas',number: 0,icon: Icons.send,)),*/
        ],
      ),
    );
  }

}