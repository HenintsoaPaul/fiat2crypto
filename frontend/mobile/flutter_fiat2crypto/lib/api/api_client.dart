// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provider
final apiClientProvider = Provider((_) => ApiClient());

/// Class
class ApiClient {
  final Dio _dio;

  ApiClient()
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        ),
      );

  // Future<Map<String, dynamic>?> get(String path, {Map<String, dynamic>? queryParameters}) async {
  //   try {
  //     final response = await _dio.get(path, queryParameters: queryParameters);
  //     return response.data as Map<String, dynamic>;
  //   } catch (e) {
  //     print('Read Error: $e');
  //     return null;
  //   }
  // }

  Future<Map<String, dynamic>?> post({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('POST Error: $e');
      return null;
    }
  }

  // Future<Response?> put(String path, Map<String, dynamic> data) async {
  //   try {
  //     final response = await _dio.put(path, data: data);
  //     return response;
  //   } catch (e) {
  //     print('Update Error: $e');
  //     return null;
  //   }
  // }

  // Future<Response?> delete(String path) async {
  //   try {
  //     final response = await _dio.delete(path);
  //     return response;
  //   } catch (e) {
  //     print('Delete Error: $e');
  //     return null;
  //   }
  // }
}
