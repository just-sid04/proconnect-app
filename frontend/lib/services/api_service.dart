import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.tokenKey);
    return _token;
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Map<String, String>> get _authHeaders async {
    final token = await getToken();
    return {
      ..._headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GET request
  Future<ApiResponse> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      var uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())));
      }

      final response = await http.get(
        uri,
        headers: await _authHeaders,
      ).timeout(const Duration(milliseconds: AppConstants.connectionTimeout));

      return _handleResponse(response);
    } on SocketException {
      return ApiResponse.error(ErrorMessages.networkError);
    } on FormatException {
      return ApiResponse.error('Invalid response format');
    } catch (e) {
      return ApiResponse.error(ErrorMessages.genericError);
    }
  }

  // POST request
  Future<ApiResponse> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: await _authHeaders,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(milliseconds: AppConstants.connectionTimeout));

      return _handleResponse(response);
    } on SocketException {
      return ApiResponse.error(ErrorMessages.networkError);
    } catch (e) {
      return ApiResponse.error(ErrorMessages.genericError);
    }
  }

  // PUT request
  Future<ApiResponse> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: await _authHeaders,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(milliseconds: AppConstants.connectionTimeout));

      return _handleResponse(response);
    } on SocketException {
      return ApiResponse.error(ErrorMessages.networkError);
    } catch (e) {
      return ApiResponse.error(ErrorMessages.genericError);
    }
  }

  // DELETE request
  Future<ApiResponse> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: await _authHeaders,
      ).timeout(const Duration(milliseconds: AppConstants.connectionTimeout));

      return _handleResponse(response);
    } on SocketException {
      return ApiResponse.error(ErrorMessages.networkError);
    } catch (e) {
      return ApiResponse.error(ErrorMessages.genericError);
    }
  }

  // Handle HTTP response
  ApiResponse _handleResponse(http.Response response) {
    dynamic body = {};
    try {
      body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    } catch (_) {
      body = {};
    }
    final message = body is Map<String, dynamic> ? (body['message']?.toString() ?? '') : '';
    final data = body is Map<String, dynamic> ? body['data'] : null;

    switch (response.statusCode) {
      case 200:
      case 201:
        return ApiResponse.success(data, message: message);
      case 400:
        return ApiResponse.error(message.isNotEmpty ? message : ErrorMessages.validationError);
      case 401:
        return ApiResponse.unauthorized(message.isNotEmpty ? message : ErrorMessages.unauthorized);
      case 403:
        return ApiResponse.error(message.isNotEmpty ? message : 'Access denied');
      case 404:
        return ApiResponse.error(message.isNotEmpty ? message : ErrorMessages.notFound);
      case 409:
        return ApiResponse.error(message.isNotEmpty ? message : 'Conflict occurred');
      case 500:
        return ApiResponse.error(ErrorMessages.serverError);
      default:
        return ApiResponse.error(ErrorMessages.genericError);
    }
  }
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String message;
  final bool isUnauthorized;

  ApiResponse({
    required this.success,
    this.data,
    this.message = '',
    this.isUnauthorized = false,
  });

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message ?? '',
    );
  }

  factory ApiResponse.error(String message) {
    return ApiResponse(
      success: false,
      message: message,
    );
  }

  factory ApiResponse.unauthorized(String message) {
    return ApiResponse(
      success: false,
      message: message,
      isUnauthorized: true,
    );
  }
}
