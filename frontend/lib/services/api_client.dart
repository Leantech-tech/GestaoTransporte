import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  // Ajuste conforme o ambiente:
  // - Windows/Linux/Mac desktop: http://localhost:8080/api
  // - Android emulator: http://10.0.2.2:8080/api
  // - Dispositivo físico: http://<IP_DA_MAQUINA>:8080/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get headers {
    final h = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (_token != null && _token!.isNotEmpty) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }

  Future<http.Response> get(String path) async {
    return http.get(
      Uri.parse('$baseUrl$path'),
      headers: headers,
    );
  }

  Future<http.Response> post(String path, dynamic body) async {
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(String path, dynamic body) async {
    return http.put(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> delete(String path) async {
    return http.delete(
      Uri.parse('$baseUrl$path'),
      headers: headers,
    );
  }

  static Map<String, dynamic> decodeBody(http.Response response) {
    if (response.statusCode == 204) return {};
    final body = response.body;
    if (body.isEmpty) return {};
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message';
}
