import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:ryvo/configs/env.dart';
import 'package:ryvo/configs/http.dart';

/// When true, [apiRequest] fails immediately (widget tests).
bool apiClientTestMode = false;

class RequestOptions {
  const RequestOptions({
    this.method = 'GET',
    this.token,
    this.body,
    this.headers = const {},
  });

  final String method;
  final String? token;
  final Object? body;
  final Map<String, String> headers;
}

Future<T> apiRequest<T>(
  String service,
  String path, {
  RequestOptions options = const RequestOptions(),
}) async {
  if (apiClientTestMode) {
    throw Exception('API disabled in test mode');
  }
  final base = Env.functionsBaseUrl.replaceAll(RegExp(r'/$'), '');
  final url = Uri.parse('$base/$service$path');
  final headers = <String, String>{
    'Content-Type': 'application/json',
    'apikey': Env.supabaseAnonKey,
    ...options.headers,
  };
  if (options.token != null && options.token!.isNotEmpty) {
    headers['Authorization'] = 'Bearer ${options.token}';
  }

  final client = http.Client();
  try {
    final res = await client
        .send(
          http.Request(options.method, url)
            ..headers.addAll(headers)
            ..body = options.body != null ? jsonEncode(options.body) : '',
        )
        .timeout(const Duration(seconds: 20));
    final body = await res.stream.bytesToString().timeout(const Duration(seconds: 20));
    dynamic json;
    try {
      json = body.isEmpty ? {} : jsonDecode(body);
    } catch (_) {
      json = {};
    }

    if (res.statusCode >= 400) {
      throw apiErrorFromResponse(res.statusCode, json, res.reasonPhrase ?? 'HTTP ${res.statusCode}');
    }
    return unwrapApiData<T>(json);
  } finally {
    client.close();
  }
}
