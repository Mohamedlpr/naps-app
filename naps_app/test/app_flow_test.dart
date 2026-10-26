import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:naps_app/api_client.dart';
import 'package:naps_app/main.dart';

void main() {
  testWidgets('a staff member can sign in and move between shared work areas', (
    tester,
  ) async {
    final client = createClient((request) async => responseFor(request));
    await tester.pumpWidget(NapsApp(apiClient: client));
    await tester.pumpAndSettle();
    expect(find.text('تسجيل الدخول'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      'mona@example.com',
    );
    await tester.enterText(
      find.byType(TextFormField).last,
      'long-test-password',
    );
    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();

    expect(find.text('مساحة العمل'), findsOneWidget);
    await tester.tap(find.text('المهام'));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد مهام بعد. أضف أول مهمة للفريق.'), findsOneWidget);
    await tester.tap(find.text('الطلبات'));
    await tester.pumpAndSettle();
    expect(
      find.text('لا توجد طلبات مسجلة. أرسل طلباً جديداً عند الحاجة.'),
      findsOneWidget,
    );
  });

  testWidgets('a supervisor can create a task shared through the API', (
    tester,
  ) async {
    final tasks = <Map<String, dynamic>>[];
    final client = createClient((request) async {
      if (request.method == 'POST' && request.url.path == '/api/tasks') {
        final values = jsonDecode(request.body) as Map<String, dynamic>;
        tasks.add({
          '_id': 'task-1',
          ...values,
          'status': 'open',
          'assignedTo': {'_id': 'user-1', 'name': 'منى سمير'},
          'createdBy': {'_id': 'user-1', 'name': 'منى سمير'},
          'branch': 'القاهرة',
        });
        return jsonResponse(tasks.first, 201);
      }
      if (request.method == 'GET' && request.url.path == '/api/tasks')
        return jsonResponse(tasks, 200);
      return responseFor(request);
    });

    await tester.pumpWidget(NapsApp(apiClient: client));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'mona@example.com',
    );
    await tester.enterText(
      find.byType(TextFormField).last,
      'long-test-password',
    );
    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المهام'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'مراجعة تقرير اليوم',
    );
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();

    expect(find.text('مراجعة تقرير اليوم'), findsOneWidget);
    expect(tasks, hasLength(1));
  });
}

ApiClient createClient(Future<http.Response> Function(http.Request) handler) =>
    ApiClient(
      baseUrl: 'https://api.test/api',
      httpClient: MockClient(handler),
      tokenStorage: _MemoryTokenStorage(),
    );

Future<http.Response> responseFor(http.Request request) async {
  if (request.method == 'POST' && request.url.path == '/api/auth/login') {
    return jsonResponse({
      'token': 'test-token',
      'user': {
        'id': 'user-1',
        'name': 'منى سمير',
        'email': 'mona@example.com',
        'role': 'supervisor',
        'branch': 'القاهرة',
        'phone': '',
        'organizationId': 'org-1',
      },
    }, 200);
  }
  if (request.url.path == '/api/tasks' ||
      request.url.path == '/api/tickets' ||
      request.url.path == '/api/announcements' ||
      request.url.path == '/api/users')
    return jsonResponse([], 200);
  return jsonResponse({'message': 'not found'}, 404);
}

http.Response jsonResponse(Object body, int statusCode) => http.Response(
  jsonEncode(body),
  statusCode,
  headers: {'content-type': 'application/json'},
);

class _MemoryTokenStorage implements TokenStorage {
  String? token;
  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String value) async => token = value;
  @override
  Future<void> clear() async => token = null;
}
