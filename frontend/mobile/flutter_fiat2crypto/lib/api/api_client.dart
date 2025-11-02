import 'package:dio/dio.dart';
import 'package:flutter_fiat2crypto/api/data/joke/joke.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provider
final apiClientProvider = Provider((_) => ApiClient());

/// Class
class ApiClient {
  final dio = Dio();

  Future<Joke> fetchJoke() async {
    const url = "https://official-joke-api.appspot.com/random_joke";
    final jsonResponse = await dio.get<Map<String, Object?>>(url);
    return Joke.fromJson(jsonResponse.data!);
  }
}
