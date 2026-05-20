class Penalty {
  final int? id;
  final String? name;
  final int partnerId;
  final int parentId;
  final int penaltyId;
  final String date;
  final double amount;
  final String status;
  final String? observations;
  final int synced; // 0 = No sincronizado, 1 = Sincronizado

  Penalty({
    this.id,
    this.name,
    required this.partnerId,
    required this.parentId,
    required this.penaltyId,
    required this.date,
    required this.amount,
    required this.status,
    this.observations,
    this.synced = 0,
  });

  factory Penalty.fromJson(Map<String, dynamic> json) {
    return Penalty(
      id: json['id'],
      name: json['name'],
      partnerId: json['partner_id'],
      parentId: json['parent_id'],
      penaltyId: json['penalty_id'],
      date: json['date'],
      amount: (json['amount'] as num).toDouble(),
      status: json['status'],
      observations: json['observations'],
      synced: json['synced'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'partner_id': partnerId,
      'parent_id': parentId,
      'penalty_id': penaltyId,
      'date': date,
      'amount': amount,
      'status': status,
      'observations': observations,
      'synced': synced,
    };
  }
}
