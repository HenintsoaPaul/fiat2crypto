import 'package:flutter/material.dart';
import 'package:flutter_fiat2crypto/features/auth/state/auth_state_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const String path = "/";
  static const String name = "home";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void logout() {
      ref.read(authProvider.notifier).logout();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Home screen')),
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: 20,
              child: ElevatedButton(
                onPressed: () => logout(),
                child: const Text('Sign out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
