import 'package:epmsa_mobile/features/inspections/shared/domain/inspection_photo.dart';

class PublicHallData {
  final String? time;
  final int? paxWaiting;
  final String? ndsArea;
  final String? ndsTime;
  final InspectionPhoto? photo;

  PublicHallData({
    required this.time,
    required this.paxWaiting,
    required this.ndsArea,
    required this.ndsTime,
    this.photo,
  });

  factory PublicHallData.fromJson(Map<String, dynamic> json) => PublicHallData(
        time: json['public_hall_time'],
        paxWaiting:
            int.tryParse('${json['public_hall_pax_waiting_area']}') ?? 0,
        ndsArea: json['public_hall_nds_area'],
        ndsTime: json['public_hall_nds_time'],
        /*photo: json['public_hall_photo'] != null
            ? InspectionPhoto.fromJson(json['photo'])
            : null,*/
      );

  Map<String, dynamic> toJson() => {
        'public_hall_time': time,
        'public_hall_pax_waiting_area': paxWaiting ?? 0,
        'public_hall_nds_area': ndsArea,
        'public_hall_nds_time': ndsTime,
        //'public_hall_photo': photo?.toJson(),
      };
}
