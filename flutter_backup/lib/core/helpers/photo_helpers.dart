import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

class PhotoHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> takeAndSavePhoto({
    required BuildContext context,
  }) async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera,
        maxWidth: 1280,   // 1280x720 (HD) ,1920x1080 (Full HD), 1024x768 (XGA)
        maxHeight: 720,
        imageQuality: 70, //(0 = peor calidad, 100 = máxima)
      );
      if (photo == null) return null;

      // Solicita permisos solo si es necesario
      final hasPermission = await ensurePermissions();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Permiso denegado para guardar imagen.')),
        );
        return null;
      }

      final Uint8List bytes = await File(photo.path).readAsBytes();

      await FlutterImageGallerySaver.saveImage(bytes);

      print('✅ Imagen guardada en galería');
      return photo.path;
    } catch (e) {
      print('❌ Error en takeAndSavePhoto: \$e');
    }
    return null;
  }

  static Future<bool> ensurePermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.photos.status;
      if (status.isGranted) return true;
      final result = await Permission.photos.request();
      return result.isGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.photos.status;
      if (status.isGranted) return true;
      final result = await Permission.photos.request();
      return result.isGranted;
    }
    return false;
  }
}
