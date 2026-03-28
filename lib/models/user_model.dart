class UserModel {
  final String uid;
  final String name;
  final String mobile;
  final String password;
  final String role;
  final String? busId;
  final String? routeId;
  final String? stopId;

  UserModel({
    required this.uid,
    required this.name,
    required this.mobile,
    required this.password,
    required this.role,
    this.busId,
    this.routeId,
    this.stopId,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? '',
      mobile: data['mobile'] ?? '',
      password: data['password'] ?? '',
      role: data['role'] ?? 'guest',
      busId: data['busId'],
      routeId: data['routeId'],
      stopId: data['stopId'],
    );
  }
}
