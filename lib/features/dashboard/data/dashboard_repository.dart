import '../../../core/api/api_client.dart';
import '../domain/dashboard_summary.dart';

class DashboardRepository {
  DashboardRepository(this._api);

  final ApiClient _api;

  Future<DashboardSummary> load() async {
    final response = await _api.get('/student/dashboard');
    return DashboardSummary.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }
}
