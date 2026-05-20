import 'package:epmsa_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

import '../../../../core/helpers/session_helper.dart';
import '../../../../core/presentation/login_screen.dart';
import '../../../assignments/presentation/pages/my_assignments.dart';
import '../../../inspections/header/presentation/dashboard_inspection_screen.dart';
import '../../../penalties/presentation/penalties_screen.dart';
import '../../../settings/presentation/pages/settings.dart';
import '../widgets/menu_item.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() {
    return _HomeScreenState();
  }
}

enum SelectedIndex {misAsignaciones, novedades, sanciones, inspecciones, ajustes, cerrarSesion}

class _HomeScreenState extends State<HomeScreen> {
  bool isExpanded = true; // Indica si el menú está expandido o colapsado
  SelectedIndex selectedIndex = SelectedIndex.misAsignaciones;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "E",
                    style: AppTextStyles.titleBoldWhite,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Text(
                "EPMSA Auditoría",
                style: AppTextStyles.titleBoldBlack,
              )
            ],
          ),
          backgroundColor: Colors.white,
        ),
        body: Row(
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: isExpanded ? 210 : 50, // ancho dependiendo de estado
              color: AppColors.primary,
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.all(10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (isExpanded) ...[
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  "E",
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "EPMSA",
                                  style: AppTextStyles.titleBoldWhite,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "App de Campo",
                                  style: AppTextStyles.subTitleWhite,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            const SizedBox(width: 5),
                          ],
                          InkWell(
                            child: Container(
                                width: 30,
                                height: 30,
                                child: Icon(
                                  isExpanded
                                      ? Icons.arrow_back_ios
                                      : Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 20,
                                )),
                            onTap: () {
                              setState(() {
                                isExpanded = !isExpanded;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  /*MenuItem(
                      icon: Icons.calendar_today_rounded,
                      text: "Agenda de Hoy",
                      isExpanded: isExpanded,
                      isSelected: selectedIndex == 0,
                      onTap: () {
                        setState(() {
                          selectedIndex = 0;
                        });
                      },
                    ),*/
                  MenuItem(
                    icon: Icons.assignment_outlined,
                    text: "Mis Asignaciones",
                    isExpanded: isExpanded,
                    isSelected: selectedIndex == SelectedIndex.misAsignaciones,
                    onTap: () {
                      setState(() {
                        selectedIndex = SelectedIndex.misAsignaciones;
                      });
                    },
                  ),
                  /*MenuItem(
                    icon: Icons.history,
                    text: "Historial",
                    isExpanded: isExpanded,
                    isSelected: selectedIndex == 2,
                    onTap: () {
                      setState(() {
                        selectedIndex = 2;
                      });
                    },
                  ),*/
                  /*MenuItem(
                    icon: Icons.warning_amber_outlined,
                    text: "Novedades",
                    isExpanded: isExpanded,
                    isSelected: selectedIndex == SelectedIndex.novedades,
                    onTap: () {
                      setState(() {
                        selectedIndex = SelectedIndex.novedades;
                      });
                    },
                  ),
                  MenuItem(
                    icon: Icons.sync,
                    text: "Sincronización",
                    isExpanded: isExpanded,
                    isSelected: selectedIndex == 4,
                    onTap: () {
                      setState(() {
                        selectedIndex = 4;
                      });
                    },
                  ),*/
                  MenuItem(
                    icon: Icons.gavel,
                    text: "Sanciones",
                    isExpanded: isExpanded,
                    isSelected: selectedIndex == SelectedIndex.sanciones,
                    onTap: () {
                      setState(() {
                        selectedIndex = SelectedIndex.sanciones;
                      });
                    },
                  ),
                  MenuItem(
                    icon: Icons.assignment,
                    text: "Inspecciones",
                    isExpanded: isExpanded,
                    isSelected: selectedIndex == SelectedIndex.inspecciones,
                    onTap: () {
                      setState(() {
                        selectedIndex = SelectedIndex.inspecciones;
                      });
                    },
                  ),
                  /*MenuItem(
                    icon: Icons.settings_outlined,
                    text: "Ajustes",
                    isExpanded: isExpanded,
                    isSelected: selectedIndex == SelectedIndex.ajustes,
                    onTap: () {
                      setState(() {
                        selectedIndex = SelectedIndex.ajustes;
                      });
                    },
                  ),*/
                  MenuItem(
                    icon: Icons.logout,
                    text: "Cerrar sesión",
                    isExpanded: isExpanded,
                    isSelected: selectedIndex == SelectedIndex.cerrarSesion,
                    onTap: () {
                      setState(() {
                        selectedIndex = SelectedIndex.cerrarSesion;
                      });
                      SessionManager.clear();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: AppColors.background,
                child: getContent(),
              ),
            ),
          ],
        ));
  }

  Widget getContent(){
    switch (selectedIndex){
      case SelectedIndex.misAsignaciones:
        return MyAssignments();
      case SelectedIndex.sanciones:
        return PenaltiesScreen();
      case SelectedIndex.inspecciones:
        return DashboardInspectionScreen();
      case SelectedIndex.ajustes:
        return Settings();
      default:
        return Center();
    }
  }

}
