// Minimal, fast check of the evaluations repository against the real
// running backend — no widgets, no router, no Firebase — to isolate
// whether the data layer itself works before blaming the UI.
//
//   flutter test test/integration/repository_smoke_test.dart \
//     --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
import 'package:flutter_test/flutter_test.dart';
import 'package:ist_trainer_evaluation/core/api/api_client.dart';
import 'package:ist_trainer_evaluation/core/storage/secure_storage.dart';
import 'package:ist_trainer_evaluation/features/evaluations/data/evaluations_repository.dart';

class _FakeSecureStorage implements SecureStorage {
  String? _token;
  @override
  Future<void> saveToken(String token) async => _token = token;
  @override
  Future<String?> readToken() async => _token;
  @override
  Future<void> clearToken() async => _token = null;
}

void main() {
  test('evaluations repository returns real data from the running backend', () async {
    final storage = _FakeSecureStorage();
    final api = ApiClient(storage);

    final loginResponse = await api.post('/auth/login', data: {
      'login': 'IST/2026/001',
      'password': 'Password123!',
      'device_name': 'repo-smoke-test',
    });
    final token = (loginResponse['data'] as Map)['token'] as String;
    await storage.saveToken(token);
    // ignore: avoid_print
    print('Logged in OK, token starts with ${token.substring(0, 6)}');

    final repo = EvaluationsRepository(api);
    final list = await repo.list();

    // ignore: avoid_print
    print('list() returned ${list.length} items:');
    for (final item in list) {
      // ignore: avoid_print
      print('  status=${item.status} trainer=${item.trainer.name} unit=${item.unit.name}');
    }

    expect(list, isNotEmpty);
    expect(list.any((i) => i.isPending), isTrue, reason: 'expected at least one pending evaluation for the seeded demo student');
  });
}
