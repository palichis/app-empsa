class PenaltyCatalog {
  final int serverId;
  final int? parentId;
  final String name;
  final int active; //bool

  PenaltyCatalog({
    required this.serverId,
    this.parentId,
    required this.name,
    required this.active,
  });

  factory PenaltyCatalog.fromJson(Map<String, dynamic> json) {
    return PenaltyCatalog(
      serverId: json['id'] ?? 0, // Asegurar que `id` no sea null
      name: json['name'] ?? "Sin nombre",
      parentId: json['parent_id'] is int
          ? json['parent_id'] // ✅ Si es `int`, lo dejamos igual
          : null,
      active: json['active'] == true ? 1 : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'server_id': serverId,
      'parent_id': parentId,
      'name': name,
      //'active': active ? 1 : 0,
      'active': active,
    };
  }
}
