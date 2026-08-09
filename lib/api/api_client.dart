import 'dart:convert';

import 'package:http/http.dart' as http;

const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class AuthResult {
  final String userId;
  final String userType;
  final String fullName;
  final String token;
  final String organizationId;

  AuthResult({
    required this.userId,
    required this.userType,
    required this.fullName,
    required this.token,
    required this.organizationId,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    userId: json['userId'] as String,
    userType: json['userType'] as String,
    fullName: json['fullName'] as String,
    token: json['token'] as String,
    organizationId: json['organizationId'] as String,
  );
}

class WorkspaceInfo {
  final String organizationId;
  final String businessName;
  final String? address;

  WorkspaceInfo({
    required this.organizationId,
    required this.businessName,
    this.address,
  });

  factory WorkspaceInfo.fromJson(Map<String, dynamic> json) => WorkspaceInfo(
    organizationId: json['organizationId'] as String,
    businessName: json['businessName'] as String,
    address: json['address'] as String?,
  );
}

class ApiClient {
  static Map<String, dynamic> _decode(http.Response res) {
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static Never _throwFromError(http.Response res, String fallback) {
    try {
      final data = _decode(res);
      throw ApiException((data['message'] ?? fallback).toString());
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(fallback);
    }
  }

  static Future<AuthResult> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode != 200) {
      _throwFromError(res, 'Нэвтрэх амжилтгүй боллоо');
    }
    return AuthResult.fromJson(_decode(res));
  }

  static Future<AuthResult> registerEmployee({
    required String fullName,
    required String email,
    required String password,
    required String organizationId,
  }) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'username': email,
        'password': password,
        'organizationId': organizationId,
      }),
    );
    if (res.statusCode != 201) {
      _throwFromError(res, 'Бүртгэл амжилтгүй боллоо');
    }
    return AuthResult.fromJson(_decode(res));
  }

  static Future<AuthResult> createWorkspace({
    required String businessName,
    required String abn,
    required String industry,
    required String address,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/api/workspaces'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'businessName': businessName,
        'abn': abn,
        'industry': industry,
        'address': address,
        'adminName': adminName,
        'adminEmail': adminEmail,
        'adminPassword': adminPassword,
      }),
    );
    if (res.statusCode != 201) {
      _throwFromError(res, 'Байгууллага үүсгэхэд алдаа гарлаа');
    }
    return AuthResult.fromJson(_decode(res));
  }

  static Future<WorkspaceInfo?> lookupWorkspace(String organizationId) async {
    if (organizationId.trim().isEmpty) return null;
    final res = await http.get(
      Uri.parse('$apiBaseUrl/api/workspaces/${Uri.encodeComponent(organizationId.trim())}'),
    );
    if (res.statusCode != 200) return null;
    return WorkspaceInfo.fromJson(_decode(res));
  }
}
