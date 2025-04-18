class UserAuth {
  final String? userId;
  final String? fullName;
  final String? email;
  final String? accessToken;
  final String? refreshToken;
  final String? photoUrl; // ✅ Nuevo campo para la imagen

  UserAuth({
    this.userId,
    this.fullName,
    this.email,
    this.accessToken,
    this.refreshToken,
    this.photoUrl, // ✅ Incluido en constructor
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'photoUrl': photoUrl, // ✅ Guardar también la imagen
    };
  }

  factory UserAuth.fromJson(Map<String, dynamic> json) {
    return UserAuth(
      userId: json['userId'] as String?,
      fullName: json['fullName'] as String?,
      email: json['email'] as String?,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      photoUrl: json['photoUrl'] as String?, // ✅ Leer la imagen guardada
    );
  }
}
