import 'package:flutter_fiat2crypto/api/api_client.dart';
import 'package:flutter_fiat2crypto/features/auth/dto/login/login_request_dto.dart';
import 'package:flutter_fiat2crypto/features/auth/dto/login/login_response_dto.dart';
// import 'package:flutter_fiat2crypto/features/auth/data/registration/registration_request_dto.dart';
// import 'package:flutter_fiat2crypto/features/auth/data/registration/registration_response_dto.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provider
final authServiceProvider = Provider(
  (ref) => AuthService(apiClient: ref.watch(apiClientProvider)),
);

/// Service responsible of making API calls to spring-boot API gateway
class AuthService {
  final ApiClient _apiClient;
  static const _loginUrl = "login_url";
  // static const _registrationUrl = "registration_url";

  AuthService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<LoginResponseDto> login(LoginRequestDto loginCredentials) async {
    // final json = await _apiClient.post(
    //   path: _loginUrl,
    //   data: loginCredentials.toJson(),
    // );

    // TODO: API call
    Map<String, dynamic> response = {"token": "fake-token", "blabla": "2"};

    final json = Future.value(response);

    return LoginResponseDto.fromJson(await json);
  }

  //   Future<RegistrationResponseDto> login(
  //   RegistrationRequestDto registrationCredentials,
  // ) async {
  //   final jsonResponse = await _apiClient.get(_registrationUrl);
  //   return RegistrationResponseDto.fromJson(jsonResponse.data!);
  // }
}
