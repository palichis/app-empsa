class User {
  final int serverId;
  final String name;
  final int active; 

  User({required this.serverId, required this.name,required this.active  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(serverId: json['id'], name: json['name'], active: json['active'] == true ? 1 : 0,);
  }
   Map<String, dynamic> toJson() {
    return {
      'serverId': serverId,
      'name': name,
      'active': 1,
    };
  }
}