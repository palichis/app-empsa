class InspectionPhoto {
  final int? id;
  final int inspectionId;
  final String section;
  final String path;
  final String? caption;
  final DateTime timestamp;
  final bool synced;

  InspectionPhoto({
    this.id,
    required this.inspectionId,
    required this.section,
    required this.path,
    this.caption,
    required this.timestamp,
    this.synced = false,
  });

  factory InspectionPhoto.fromJson(Map<String, dynamic> json) =>
      InspectionPhoto(
        id: json['id'],
        inspectionId: json['inspection_id'],
        section: json['section'],
        path: json['path'],
        caption: json['caption'],
        timestamp: DateTime.parse(json['timestamp']),
        synced: json['synced'] == 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'inspection_id': inspectionId,
        'section': section,
        'path': path,
        'caption': caption,
        'timestamp': timestamp.toIso8601String(),
        'synced': synced ? 1 : 0,
      };
}
