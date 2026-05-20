import 'dart:io';

import 'package:epmsa_mobile/core/helpers/photo_helpers.dart';
import 'package:epmsa_mobile/features/inspections/header/providers/inspections_providers.dart';
import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  final int inspectionId;
  const GalleryScreen({super.key, required this.inspectionId});

  @override
  GalleryScreenState createState() => GalleryScreenState();
}

class GalleryScreenState extends ConsumerState<GalleryScreen> {
  List<File> _photos = [];

  @override
  void initState() {
    super.initState();
    _loadCargoPhotos();
  }

  Future<void> _loadCargoPhotos() async {
    final photos = await ref
        .read(photoServiceProvider)
        .getPhotosBySection(widget.inspectionId, 'cargo');

    if (photos.isNotEmpty) {
      setState(() {
        _photos = photos.map((p) => File(p.path)).toList();
      });
      print(
          "✅ \${_photos.length} fotos cargadas en GalleryScreen para la sección 'cargo'");
    } else {
      print("⚠️ No hay fotos guardadas para la sección 'cargo'");
    }
  }

  Future<void> _handlePhoto() async {
    var photoPath = await PhotoHelper.takeAndSavePhoto(context: context);
    if (photoPath != null) {
      setState(() {
        _photos.add(File(photoPath));
      });

      final photo = InspectionPhoto(
        inspectionId: widget.inspectionId,
        path: photoPath,
        timestamp: DateTime.now(),
        section: 'cargo',
      );

      ref.read(photoServiceProvider).savePhoto(photo);

      print('💾 Foto guardada: \${photo.path}');
    }
  }

  Widget _buildPhotoGrid() {
    if (_photos.isEmpty) return const SizedBox();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _photos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        return Image.file(
          _photos[index],
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        );
      },
    );
  }

  Map<String, dynamic> getData() => {};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fotos de inspección de carga',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildPhotoGrid(),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _handlePhoto,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Agregar foto'),
          )
        ],
      ),
    );
  }
}
