import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../inspections/shared/presentation/public_hall_screen.dart';
import '../../domain/model/photo_item.dart';

class TakePictures extends StatelessWidget {
  final List<PhotoItem> images;
  final ValueChanged<PhotoItem> onAddPhoto;
  final ValueChanged<PhotoItem> onRemovePhoto;

  const TakePictures({
    Key? key,
    required this.images,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  }) : super(key: key);

  Future<void> _handlePhoto(BuildContext context) async {
    final ImagePicker _picker = ImagePicker();
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera,
        maxWidth: 1280,   // 1280x720 (HD) ,1920x1080 (Full HD), 1024x768 (XGA)
        maxHeight: 720,
        imageQuality: 70, //(0 = peor calidad, 100 = máxima)
      );

      if (photo == null) return null;

      String? caption = await _askPhotoCaptionOverlay(
        context,
        imageFile: File(photo.path),
      );

      caption = caption?.trim();
      if (caption == null || caption.isEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        caption = 'sin_titulo_$timestamp';
      }

      final safeCaption = caption.replaceAll(RegExp(r'\s+'), '_');
      final ext = photo.path.split('.').last;
      final directory = File(photo.path).parent.path;
      var newPath = '$directory/$safeCaption.$ext';

      // 5️⃣ Si ya existe un archivo con ese nombre, agrega un contador
      int i = 1;
      while (await File(newPath).exists()) {
        newPath = '$directory/${safeCaption}_$i.$ext';
        i++;
      }

      final renamedFile = await File(photo.path).rename(newPath);
      final pi = PhotoItem(file: renamedFile, caption: caption);
      onAddPhoto(pi);
    } catch (e) {
      print('❌ Error en _handlePhoto: \$e');
    }
  }

  Future<String?> _askPhotoCaptionOverlay(
      BuildContext context, {
        required File imageFile,
        String? initialText,
      }) async {
     String? aux=await Navigator.of(context, rootNavigator: true).push<String>(
      PageRouteBuilder(
        opaque: true,
        barrierDismissible: true,
        barrierColor: Colors.black,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (ctx, _, __) => WAfastCaptionOverlay(
          imageFile: imageFile,
          initialText: initialText,
        ),
        transitionsBuilder: (_, __, ___, child) => child,
      ),
    );

     return aux;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.photo_library_outlined,color: Colors.red[800],size: 25,),
                    SizedBox(width: 10,),
                    Text('Registro fotográfico',style: AppTextStyles.titleBoldBlack,)
                  ],
                ),
                Text('',style: AppTextStyles.subTitleGrey),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _handlePhoto(context),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Adjuntar fotos'),
            ),
            const SizedBox(height: 12),
            if (images.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: images.map((img) {
                  return Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          img.file,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => onRemovePhoto(img),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
