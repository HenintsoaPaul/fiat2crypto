import 'package:flutter/material.dart';
import 'package:flutter_fiat2crypto/api/data/joke/joke_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRandomJoke = ref.watch(jokeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Random Joke Generator')),
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            asyncRandomJoke.when(
              data: (joke) {
                return SelectableText(
                  '${joke.setup}\n\n${joke.punchline}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24),
                );
              },
              error: (err, stackTrace) =>
                  Text('Error: ${asyncRandomJoke.error}'),
              loading: () => const CircularProgressIndicator(),
            ),

            Positioned(
              bottom: 20,
              child: ElevatedButton(
                onPressed: () => ref.invalidate(jokeProvider),
                child: const Text('Get another joke'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
