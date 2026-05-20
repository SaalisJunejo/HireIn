import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../models/provider_model.dart';
import '../services/agent_service.dart';
import '../services/mock_service.dart';

// Stream of all available providers from database
final availableProvidersStreamProvider = StreamProvider.autoDispose.family<List<ProviderModel>, String?>((ref, category) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamAvailableProviders(category: category);
});

// AI Agent Service Provider
final agentServiceProvider = Provider((ref) => AgentService());

// StateNotifier for current AI query results (Intent -> Discovery -> Ranking -> Proposal)
final aiAgentQueryStateProvider = StateNotifierProvider<AiAgentQueryNotifier, AsyncValue<AgentQueryResult?>>((ref) {
  final agentService = ref.watch(agentServiceProvider);
  return AiAgentQueryNotifier(agentService);
});

class AiAgentQueryNotifier extends StateNotifier<AsyncValue<AgentQueryResult?>> {
  final AgentService _agentService;

  AiAgentQueryNotifier(this._agentService) : super(const AsyncValue.data(null));

  // Run natural language search through multi-agent system
  Future<void> searchServices(String rawQuery, {double lat = 25.3960, double lng = 68.3578}) async {
    state = const AsyncValue.loading();
    try {
      final result = await _agentService.processServiceQuery(rawQuery, lat, lng);
      state = AsyncValue.data(result);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void resetQuery() {
    state = const AsyncValue.data(null);
  }
}

// Local mock providers list (for quick testing/offline fallback)
final mockProvidersProvider = Provider<List<ProviderModel>>((ref) {
  return MockService.generateMockProviders();
});
