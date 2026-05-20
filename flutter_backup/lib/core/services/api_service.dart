import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static Future<String> getBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //String serverIp = prefs.getString('server_ip') ?? "http://192.168.18.18";
    String serverIp = prefs.getString('server_ip') ??
        "https://erppruebas.aeropuertoquito.gob.ec";
    String serverPort = prefs.getString('server_port') ?? "443";
    //return "$serverIp:$serverPort";
    return "$serverIp";
  }

  static Future<String> getDbName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('db_name') ?? "epmsa_pruebas";
    //return prefs.getString('db_name') ?? "odooDB";
  }
}
