import 'package:flutter/foundation.dart';

@immutable
class AuthState {
  final String? token;

  const AuthState({this.token});

  bool get isLoggedIn => token != null;

  AuthState copyWith({required String token}) => AuthState(token: token);
}
