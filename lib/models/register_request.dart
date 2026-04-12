class RegisterRequest {
  final String username;
  final String? firstName;
  final String? lastName;
  final String email;
  final String password;
  final String repeatedPassword;
  final String? role;
  final int? sectionId;

  RegisterRequest({
    required this.username,
    this.firstName,
    this.lastName,
    required this.email,
    required this.password,
    required this.repeatedPassword,
    this.role,
    this.sectionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'repeatedPassword': repeatedPassword,
      'role': role,
      'sectionId': sectionId,
    };
  }
}
