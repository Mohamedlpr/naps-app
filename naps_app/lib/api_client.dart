import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'app_models.dart';

abstract class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage();
  static const channel = MethodChannel('com.naps/session');

  @override
  Future<String?> read() => channel.invokeMethod<String>('read');

  @override
  Future<void> write(String token) =>
      channel.invokeMethod<void>('write', {'value': token});

  @override
  Future<void> clear() => channel.invokeMethod<void>('clear');
}

class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
    TokenStorage? tokenStorage,
  }) : _httpClient = httpClient ?? http.Client(),
       _tokenStorage = tokenStorage ?? const SecureTokenStorage();

  static const defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000/api',
  );
  static const _baseUrlKey = 'naps.api-base-url';
  final http.Client _httpClient;
  final TokenStorage _tokenStorage;
  String baseUrl;
  String? _token;

  static Future<ApiClient> create({
    http.Client? httpClient,
    TokenStorage? tokenStorage,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final savedBaseUrl = preferences.getString(_baseUrlKey);
    return ApiClient(
      baseUrl: savedBaseUrl ?? defaultBaseUrl,
      httpClient: httpClient,
      tokenStorage: tokenStorage,
    );
  }

  Future<void> setBaseUrl(String value) async {
    final parsed = Uri.tryParse(value.trim());
    if (parsed == null ||
        !parsed.hasAuthority ||
        !['http', 'https'].contains(parsed.scheme)) {
      throw const ApiException('أدخل عنوان API صحيحاً يبدأ بـ http أو https.');
    }
    baseUrl = value.trim().replaceFirst(RegExp(r'/+$'), '');
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_baseUrlKey, baseUrl);
  }

  Future<AppUser?> restoreSession() async {
    try {
      _token = await _tokenStorage.read();
    } catch (_) {
      throw const ApiException(
        'تعذّر فتح جلسة الدخول المحفوظة على هذا الجهاز.',
      );
    }
    if (_token == null) return null;
    try {
      final result = await _send('GET', '/auth/me');
      return AppUser.fromJson(result as Map<String, dynamic>);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await logout();
        return null;
      }
      rethrow;
    }
  }

  Future<AppUser> login(String email, String password) async => _authenticate(
    '/auth/login',
    {'email': email.trim(), 'password': password},
  );

  Future<AppUser> bootstrapOrganization(Map<String, dynamic> values) async =>
      _authenticate('/auth/bootstrap', values);

  Future<AppUser> _authenticate(
    String path,
    Map<String, dynamic> values,
  ) async {
    final result =
        await _send('POST', path, body: values, authenticated: false)
            as Map<String, dynamic>;
    final token = result['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const ApiException('استجاب الخادم دون إصدار جلسة دخول.');
    }
    try {
      await _tokenStorage.write(token);
      _token = token;
    } catch (_) {
      throw const ApiException('تعذّر حفظ جلسة الدخول على هذا الجهاز.');
    }
    return AppUser.fromJson(Map<String, dynamic>.from(result['user'] as Map));
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await _send(
      'POST',
      '/auth/password',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  Future<void> logout() async {
    _token = null;
    await _tokenStorage.clear();
  }

  Future<List<WorkTask>> getTasks() async =>
      _list('/tasks').then((items) => items.map(WorkTask.fromJson).toList());
  Future<WorkTask> createTask(Map<String, dynamic> values) async =>
      WorkTask.fromJson(
        await _send('POST', '/tasks', body: values) as Map<String, dynamic>,
      );
  Future<WorkTask> updateTask(String id, Map<String, dynamic> values) async =>
      WorkTask.fromJson(
        await _send('PATCH', '/tasks/$id', body: values)
            as Map<String, dynamic>,
      );
  Future<void> deleteTask(String id) async {
    await _send('DELETE', '/tasks/$id');
  }

  Future<List<SupportTicket>> getTickets() async => _list(
    '/tickets',
  ).then((items) => items.map(SupportTicket.fromJson).toList());
  Future<SupportTicket> createTicket(Map<String, dynamic> values) async =>
      SupportTicket.fromJson(
        await _send('POST', '/tickets', body: values) as Map<String, dynamic>,
      );
  Future<SupportTicket> updateTicket(
    String id,
    Map<String, dynamic> values,
  ) async => SupportTicket.fromJson(
    await _send('PATCH', '/tickets/$id', body: values) as Map<String, dynamic>,
  );
  Future<void> deleteTicket(String id) async {
    await _send('DELETE', '/tickets/$id');
  }

  Future<List<TeamAnnouncement>> getAnnouncements() async => _list(
    '/announcements',
  ).then((items) => items.map(TeamAnnouncement.fromJson).toList());
  Future<TeamAnnouncement> createAnnouncement(
    Map<String, dynamic> values,
  ) async => TeamAnnouncement.fromJson(
    await _send('POST', '/announcements', body: values) as Map<String, dynamic>,
  );
  Future<TeamAnnouncement> acknowledgeAnnouncement(String id) async =>
      TeamAnnouncement.fromJson(
        await _send('POST', '/announcements/$id/acknowledge')
            as Map<String, dynamic>,
      );
  Future<void> deleteAnnouncement(String id) async {
    await _send('DELETE', '/announcements/$id');
  }

  Future<List<TeamMember>> getUsers() async =>
      _list('/users').then((items) => items.map(TeamMember.fromJson).toList());
  Future<TeamMember> createUser(Map<String, dynamic> values) async =>
      TeamMember.fromJson(
        await _send('POST', '/users', body: values) as Map<String, dynamic>,
      );
  Future<TeamMember> updateUser(String id, Map<String, dynamic> values) async =>
      TeamMember.fromJson(
        await _send('PATCH', '/users/$id', body: values)
            as Map<String, dynamic>,
      );

  Future<List<Map<String, dynamic>>> _list(String path) async =>
      (await _send('GET', path) as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authenticated && _token != null)
      headers['Authorization'] = 'Bearer $_token';
    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    try {
      final response = await http.Response.fromStream(
        await _httpClient.send(request).timeout(const Duration(seconds: 20)),
      );
      final data = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = data is Map ? data['message'] as String? : null;
        if (response.statusCode == 401 && authenticated) await logout();
        throw ApiException(
          message ?? 'تعذّر إكمال الطلب. حاول مرة أخرى.',
          statusCode: response.statusCode,
        );
      }
      return data;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'تعذّر الاتصال بالخادم. تحقّق من العنوان واتصال الشبكة.',
      );
    }
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}
