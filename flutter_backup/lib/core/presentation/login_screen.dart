import 'package:epmsa_mobile/core/helpers/session_helper.dart';
import 'package:epmsa_mobile/core/presentation/dashboard_screen.dart';
import 'package:epmsa_mobile/features/penalties/providers/penalties_catalog_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epmsa_mobile/core/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/home/presentation/pages/home_screen.dart';
import '../theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isHidenPass = true;

  String? _errorMessage;
  bool _isLoading = false;

  String serverIp = "";
  String serverPort = "";
  String dbName = "";

  @override
  void initState() {
    super.initState();
    /*_usernameController.text = 'anarvaez';
    _passwordController.text = 'epmsa_1234';*/
    //_usernameController.text = 'juan.leiva.marquez+controlcalidad@gmail.com';
    //_passwordController.text = '7ocFjwMT5HVcvj3mfzyq_*?';
    _usernameController.text = '';
    _passwordController.text = '';
    _loadServerConfig();
    _tryAutoLogin();
  }

  Future<void> _loadServerConfig() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      //serverIp = prefs.getString('server_ip') ?? "http://46.202.178.195";
      serverIp = prefs.getString('server_ip') ??
          "https://erppruebas.aeropuertoquito.gob.ec";
      serverPort = prefs.getString('server_port') ?? "443";
      dbName = prefs.getString('db_name') ?? "epmsa_pruebas";
    });
  }

  Future<void> _saveServerConfig(String ip, String port, String dbName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', ip);
    await prefs.setString('server_port', port);
    await prefs.setString('db_name', dbName);
    _loadServerConfig();
  }

  Future<void> _tryAutoLogin() async {
    final cached = await SessionManager.load();
    if (cached["session_id"] != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen())
      );
    }
  }

  Future<void> _login(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Limpia el error anterior
    });
    try {
      final authNotifier = ref.read(authProvider.notifier);
      print("login ...");
      final success = await authNotifier.login(
        _usernameController.text,
        _passwordController.text,
      );

      print("success: $success");
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        print("Error login: $_errorMessage");
        setState(() {
          _errorMessage = "Credenciales incorrectas. Inténtelo de nuevo.";
        });
      }
    } catch (e, st) {
      print("Error login: $e, $st");
      setState(() {
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showConfigDialog() {
    TextEditingController ipController = TextEditingController(text: serverIp);
    TextEditingController portController =
        TextEditingController(text: serverPort);
    TextEditingController dbController = TextEditingController(text: dbName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Configuración del Servidor"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ipController,
                decoration: InputDecoration(labelText: "IP del Servidor"),
              ),
              TextField(
                controller: portController,
                decoration: InputDecoration(labelText: "Puerto"),
              ),
              TextField(
                controller: dbController,
                decoration: InputDecoration(labelText: "Base de datos"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                _saveServerConfig(
                    ipController.text, portController.text, dbController.text);
                Navigator.pop(context);
              },
              child: Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          //title: Text('Iniciar Sesión'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: _showConfigDialog,
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/images/logo-epmsa.png",
                  height: 150,
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Usuario',
                    fillColor: Colors.white.withAlpha(8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    suffixIcon: InkWell(
                      onTap: (){
                        setState(() {
                          _isHidenPass=!_isHidenPass;
                        });
                      },
                        child: Icon(_isHidenPass?Icons.lock_outline:Icons.lock_open)
                    ),
                    labelText: 'Contraseña',
                    fillColor: Colors.white.withAlpha(8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  obscureText: _isHidenPass,
                ),
                if (_errorMessage != null && _errorMessage!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      _errorMessage ?? 'Error en el inicio de sesión',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                SizedBox(height: 20),
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  )
                else
                  ElevatedButton(
                    onPressed: () => _login(context),
                    child: Text('Ingresar'),
                  ),
                Spacer(),
                Text('Version: 2026.05.06',style: AppTextStyles.subTitleGrey,),
                SizedBox(height: 20)
              ],
            ),
          ),
        ));
  }
}
