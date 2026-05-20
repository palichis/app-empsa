import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../../../core/helpers/session_helper.dart';
import '../../../../core/services/api_service.dart';
import '../../domain/model/photo_item.dart';

class PhotoRemoteDS{

  void putPictures(bool isTest, List<PhotoItem> photos, int id) async{
    final cached = await SessionManager.load();
    final String? sid =cached["session_id"];
    String baseUrl = await ApiService.getBaseUrl();
    final Uri url = Uri.parse("$baseUrl/api/${isTest?'sync-tests-photos':'sync-inspections-photos'}");

    final zipPath = await createZip(photos);
    final zipBytes = await File(zipPath).readAsBytes();
    final zipBase64 = base64Encode(zipBytes);

    final Map<String, dynamic> payload = {
      "id": id,
      "photos": photos.map((file) {
        return {
          "path": p.basename(file.file.path), // solo el nombre del archivo
          "note": file.caption,
        };
      }).toList(),
      "compressed_photos": zipBase64,
    };

    print(url);
    print(payload);

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Cookie": "session_id=$sid",
      },
      body: jsonEncode(payload),
    );
    print(response.body);

  }

  Future<String> createZip(List<PhotoItem> files) async {
    final tempDir = Directory.systemTemp;
    final zipFile = File('${tempDir.path}/inspection_photos.zip');
    final encoder = ZipFileEncoder();
    encoder.create(zipFile.path);

    for (var file in files) {
      encoder.addFile(file.file);
    }

    encoder.close();
    return zipFile.path;
  }

}