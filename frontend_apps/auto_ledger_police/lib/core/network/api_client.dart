import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    http.Client? client,
    TokenStorage? tokenStorage,
  })  : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage ?? const TokenStorage();

  final http.Client _client;
  final TokenStorage _tokenStorage;

  Future<dynamic> get(
      String path, {
        bool requiresAuth = true,
      }) async {
    final response = await _client.get(
      _buildUri(path),
      headers: await _buildHeaders(requiresAuth: requiresAuth),
    );

    return _handleResponse(response);
  }

  Future<dynamic> post(
      String path, {
        Map<String, dynamic>? body,
        bool requiresAuth = true,
      }) async {
    final response = await _client.post(
      _buildUri(path),
      headers: await _buildHeaders(requiresAuth: requiresAuth),
      body: jsonEncode(body ?? {}),
    );

    return _handleResponse(response);
  }

  Future<dynamic> patch(
      String path, {
        Map<String, dynamic>? body,
        bool requiresAuth = true,
      }) async {
    final response = await _client.patch(
      _buildUri(path),
      headers: await _buildHeaders(requiresAuth: requiresAuth),
      body: jsonEncode(body ?? {}),
    );

    return _handleResponse(response);
  }

  Uri _buildUri(String path) {
    return Uri.parse('${ApiConstants.baseUrl}$path');
  }

  Future<Map<String, String>> _buildHeaders({
    required bool requiresAuth,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _tokenStorage.getAccessToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    final decodedBody = _decodeBody(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodedBody;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: _extractMessage(decodedBody, response.statusCode),
    );
  }

  dynamic _decodeBody(String body) {
    if (body.trim().isEmpty) return null;

    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  String _extractMessage(dynamic decodedBody, int statusCode) {
    if (decodedBody is Map<String, dynamic>) {
      final message = decodedBody['message'];

      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      if (message is List && message.isNotEmpty) {
        return message.join(', ');
      }

      final error = decodedBody['error'];

      if (error is String && error.trim().isNotEmpty) {
        return error;
      }
    }

    if (statusCode == 401) {
      return 'Unauthorized access. Please login again.';
    }

    if (statusCode == 404) {
      return 'Requested data was not found.';
    }

    if (statusCode >= 500) {
      return 'Server error. Please try again later.';
    }

    return 'Something went wrong. Please try again.';
  }
}