import 'package:epmsa_mobile/core/handlers/sqlite_handler.dart';
import 'package:epmsa_mobile/core/presentation/login_screen.dart';
//import 'package:epmsa_mobile/features/inspections/header/presentation/dashboard_inspection_screen.dart';
//import 'package:epmsa_mobile/features/inspections/header/presentation/inspection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sqliteHandler = SqliteHandler();
  await sqliteHandler.initDB(); // Inicializa la base de datos

  debugPrint = (String? msg, {int? wrapWidth}) {
    if (msg == null) return;

    const chunkSize = 800; // < 4 000 bytes que impone logcat
    for (var i = 0; i < msg.length; i += chunkSize) {
      final end = (i + chunkSize < msg.length) ? i + chunkSize : msg.length;
      print(msg.substring(i, end));
    }
  };

  runApp(
    ProviderScope(
      overrides: [
        sqliteHandlerProvider.overrideWithValue(sqliteHandler),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Acta de infracción',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme:
              ColorScheme.fromSeed(seedColor: AppColors.primary),
          useMaterial3: true,
        ),
        home: LoginScreen());
    //home: InspectionScreen(),
    //home: DashboardInspectionScreen());
  }
}

final sqliteHandlerProvider = Provider<SqliteHandler>((ref) {
  throw UnimplementedError(); // Evita que se use antes de estar disponible
});
