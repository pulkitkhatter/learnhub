import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

/// Error surfaced to the UI with a human-readable [message].
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Thin JSON-over-HTTP client that attaches the bearer token and normalises
/// errors into [ApiException].
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _http = client ?? http.Client(),
        _base = baseUrl ?? apiBaseUrl;

  final http.Client _http;
  final String _base;

  String? token;

  /// Called when the server rejects the stored token (expired / revoked).
  void Function()? onUnauthorized;

  Map<String, String> get _headers => {
        'content-type': 'application/json',
        if (token != null) 'authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, [Object? body]) => _send('POST', path, body);
  Future<dynamic> put(String path, [Object? body]) => _send('PUT', path, body);

  Future<dynamic> _send(String method, String path, [Object? body]) async {
    final request = http.Request(method, Uri.parse('$_base$path'))
      ..headers.addAll(_headers);
    if (body != null) request.body = jsonEncode(body);

    http.Response response;
    try {
      response = await http.Response.fromStream(
        await _http.send(request).timeout(const Duration(seconds: 12)),
      );
    } on TimeoutException {
      throw ApiException('The server took too long to respond. Please try again.');
    } catch (_) {
      throw ApiException(
          'Could not reach the server. Check your connection and that the API is running.');
    }

    dynamic data;
    try {
      data = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      throw ApiException('Unexpected response from the server.',
          statusCode: response.statusCode);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return data;

    final message = data is Map && data['error'] is String
        ? data['error'] as String
        : 'Request failed (${response.statusCode}).';
    // A 401 on a request that carried a token means the session is gone.
    if (response.statusCode == 401 && token != null) onUnauthorized?.call();
    throw ApiException(message, statusCode: response.statusCode);
  }
}
