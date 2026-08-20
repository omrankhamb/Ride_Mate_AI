part of ridemate_ai;

class AppUser {
  AppUser({
    required this.id,
    required this.fullName,
    required this.mobileNumber,
    required this.email,
    required this.role,
  });

  final String id;
  final String fullName;
  final String mobileNumber;
  final String email;
  final String role;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'].toString(),
      fullName: json['fullName'].toString(),
      mobileNumber: json['mobileNumber'].toString(),
      email: json['email'].toString(),
      role: json['role'].toString(),
    );
  }
}
