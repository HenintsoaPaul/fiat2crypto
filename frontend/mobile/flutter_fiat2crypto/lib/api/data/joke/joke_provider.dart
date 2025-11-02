import 'package:flutter_fiat2crypto/api/api_client.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final jokeProvider = FutureProvider((ref) {
  final apiClient = ref.read(apiClientProvider);
  return apiClient.fetchJoke();
});
