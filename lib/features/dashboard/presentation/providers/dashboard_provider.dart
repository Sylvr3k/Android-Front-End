import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../data/dashboard_repository.dart';
import '../../domain/dashboard_summary.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(apiClientProvider));
});

final dashboardProvider = FutureProvider.autoDispose<DashboardSummary>((ref) {
  return ref.read(dashboardRepositoryProvider).load();
});
