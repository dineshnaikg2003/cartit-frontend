class SendOtpRequest {
  final String phone;

  SendOtpRequest({required this.phone});

  Map<String, dynamic> toJson() => {'phone': phone};
}

class VerifyOtpRequest {
  final String phone;
  final String otp;
  final String? name;
  final String? email;

  VerifyOtpRequest({
    required this.phone,
    required this.otp,
    this.name,
    this.email,
  });

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'otp': otp,
        if (name != null && name!.isNotEmpty) 'name': name,
        if (email != null && email!.isNotEmpty) 'email': email,
      };
}

class AuthResponse {
  final String token;
  final bool isNewUser;
  final LongIdUser? user;

  AuthResponse({
    required this.token,
    this.isNewUser = false,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? json['accessToken'] ?? '',
      isNewUser: json['newUser'] ?? false,
      user: json['user'] != null
          ? LongIdUser.fromJson(json['user'])
          : json['userResponse'] != null
              ? LongIdUser.fromJson(json['userResponse'])
              : null,
    );
  }
}

class LongIdUser {
  final dynamic id;
  final String phone;
  final String? name;
  final String? email;
  final String? role;

  LongIdUser({
    required this.id,
    required this.phone,
    this.name,
    this.email,
    this.role,
  });

  factory LongIdUser.fromJson(Map<String, dynamic> json) {
    return LongIdUser(
      id: json['id'],
      phone: json['phone'] ?? '',
      name: json['name'],
      email: json['email'],
      role: json['role'],
    );
  }
}
