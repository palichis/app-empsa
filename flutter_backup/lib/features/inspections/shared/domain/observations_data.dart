import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_photo.dart';

class ObservationsData {
  final String? eventTime;
  final String? location;
  final String? description;
  final String? consequence;
  final List<InspectionPhoto>?
      photos; // Lista de objetos de tipo InspectionPhoto

  ObservationsData({
    this.eventTime,
    this.location,
    this.description,
    this.consequence,
    this.photos,
  });

  factory ObservationsData.fromJson(Map<String, dynamic> json) =>
      ObservationsData(
        eventTime: json['observations_event_time'],
        location: json['observations_location'],
        description: json['observations_description'],
        consequence: json['observations_consequence'],
        /*photos: (json['observations_photos'] as List<dynamic>?)
            ?.map((e) => InspectionPhoto.fromJson(e))
            .toList(),*/
      );

  Map<String, dynamic> toJson() => {
        'observations_event_time': eventTime,
        'observations_location': location,
        'observations_description': description,
        'observations_consequence': consequence,
        //'observations_photos': photos?.map((e) => e.toJson()).toList(),
      };
}
