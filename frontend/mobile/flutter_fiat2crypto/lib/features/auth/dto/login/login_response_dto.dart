import 'package:flutter/foundation.dart';

@immutable
class LoginResponseDto {
  final String token;
  final String blabla;

  const LoginResponseDto({required this.token, required this.blabla});

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) =>
      LoginResponseDto(token: json["token"] as String, blabla: json["blabla"]);
}
