import 'package:flutter/material.dart';
import 'package:flutter_fiat2crypto/features/auth/dto/login/login_request_dto.dart';
import 'package:flutter_fiat2crypto/features/auth/state/auth_state_notifier.dart';
import 'package:flutter_fiat2crypto/features/home/home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  static const String path = "/login";
  static const String name = "login";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void authenticate() {
      // Collect form values
      final credentials = LoginRequestDto(login: "login", password: "password");

      // Login + Change authState
      ref.read(authProvider.notifier).login(credentials);

      // Redirect
      GoRouter.of(context).goNamed(HomeScreen.name);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Login screen')),
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: 20,
              child: ElevatedButton(
                onPressed: () => authenticate(),
                child: const Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
