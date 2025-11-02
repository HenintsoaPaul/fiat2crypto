import 'package:flutter_fiat2crypto/features/auth/auth_service.dart';
import 'package:flutter_fiat2crypto/features/auth/dto/login/login_request_dto.dart';
import 'package:flutter_fiat2crypto/features/auth/dto/login/login_response_dto.dart';
import 'package:flutter_fiat2crypto/features/auth/state/auth_state.dart';
import 'package:hooks_riverpod/legacy.dart';

/// Provider
final authProvider = StateNotifierProvider((ref) {
  final service = ref.read(authServiceProvider);
  return AuthNotifier(service);
});

/// Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._service) : super(const AuthState());

  final AuthService _service;

  Future<void> login(LoginRequestDto loginCredentials) async {
    LoginResponseDto response = await _service.login(loginCredentials);

    state = state.copyWith(token: response.token);
  }

  void logout() {
    state = AuthState();
  }
}
