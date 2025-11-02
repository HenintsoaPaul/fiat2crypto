import 'package:flutter/foundation.dart';

@immutable
class LoginRequestDto {
  final String login;
  final String password;

  const LoginRequestDto({required this.login, required this.password});

  Map<String, Object> toJson() => {"login": login, "password": password};
}
