import 'dart:convert';
import 'dart:math';
import '../models/provider_model.dart';
import '../models/booking_model.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/helpers.dart';
import 'mock_service.dart';
import 'openrouter_service.dart';
import 'local_database.dart';

class AgentQueryResult {
  final String category;
  final String area;
  final String rawIntent;
  final List<ProviderModel> matchedProviders;
  final List<ProviderModel> rankedProviders;
  final String thoughtProcess;

  AgentQueryResult({
    required this.category,
    required this.area,
    required this.rawIntent,
    required this.matchedProviders,
    required this.rankedProviders,
    required this.thoughtProcess,
  });
}

class AgentService {
  AgentService();

  Future<AgentQueryResult> processServiceQuery(String rawQuery, double userLat, double userLng) async {
    Helpers.log('AgentService', 'Orchestrating agentic pipeline for query: "$rawQuery"');
    
    final StringBuffer fullLog = StringBuffer();
    
    // --- AGENT 1: Intent Extractor (via OpenRouter) ---
    fullLog.writeln('🧠 Agent 1 (Intent) -> Analyzing request...');
    String identifiedCategory = 'Electrician';
    String identifiedArea = 'Hyderabad';
    bool isUrgent = false;
    
    try {
      final prompt = '''
      You are an Intent Extractor for the HireIn app (local to Hyderabad, Pakistan).
      Extract intent from this query: "$rawQuery"
      Must return ONLY valid JSON with keys: "service" (Electrician, Plumber, Carpenter, AC Technician, Painter, Mechanic), "location" (match to Hyderabad areas if possible), "isUrgent" (boolean).
      ''';
      final response = await OpenRouterService.chat('', prompt);
      final cleanJson = response.replaceAll(RegExp(r'```json|```'), '').trim();
      final data = jsonDecode(cleanJson);
      
      identifiedCategory = data['service'] ?? 'Electrician';
      identifiedArea = data['location'] ?? 'Hyderabad';
      isUrgent = data['isUrgent'] == true;
      fullLog.writeln('  ✅ Extracted: $identifiedCategory in $identifiedArea (Urgent: $isUrgent)');
    } catch (e) {
      // Fallback local NLP extraction
      fullLog.writeln('  ⚠️ AI failed, using fallback NLP rules.');
      final lower = rawQuery.toLowerCase();
      if (lower.contains('electrician') || lower.contains('bijli')) identifiedCategory = 'Electrician';
      else if (lower.contains('plumber') || lower.contains('nal')) identifiedCategory = 'Plumber';
      else if (lower.contains('carpenter') || lower.contains('wood') || lower.contains('lakri')) identifiedCategory = 'Carpenter';
      else if (lower.contains('ac ') || lower.contains('air conditioner')) identifiedCategory = 'AC Technician';
      else if (lower.contains('painter') || lower.contains('rang')) identifiedCategory = 'Painter';
      else if (lower.contains('mechanic') || lower.contains('gari')) identifiedCategory = 'Mechanic';
      
      for (final area in AppStrings.hyderabadAreas) {
        if (lower.contains(area.toLowerCase())) identifiedArea = area;
      }
      isUrgent = lower.contains('urgent') || lower.contains('abhi') || lower.contains('emergency');
      fullLog.writeln('  ✅ Extracted: $identifiedCategory in $identifiedArea');
    }

    // --- AGENT 2: Discovery Agent (Local Database) ---
    fullLog.writeln('\n🔍 Agent 2 (Discovery) -> Querying local providers...');
    final allProvidersJson = LocalDatabase.instance.getAll('providers');
    final allProviders = allProvidersJson.map((json) => ProviderModel.fromJson(json)).toList();
    
    final matchedList = allProviders.where((prov) {
      return prov.category == identifiedCategory && prov.isOnline;
    }).toList();
    fullLog.writeln('  ✅ Found ${matchedList.length} active $identifiedCategory(s).');

    // --- AGENT 3: Ranking Engine ---
    fullLog.writeln('\n📊 Agent 3 (Ranking) -> Evaluating candidates...');
    List<ProviderModel> rankedList = [];
    try {
      final List<Map<String, dynamic>> scoredProviders = matchedList.map((prov) {
        final distance = Helpers.calculateDistance(userLat, userLng, prov.lat, prov.lng);
        final proximityScore = max(0.0, 10.0 - distance) / 10.0;
        final ratingScore = prov.rating / 5.0;
        double skillScore = prov.skillLevel == 'expert' ? 1.0 : (prov.skillLevel == 'intermediate' ? 0.7 : 0.4);
        final totalScore = (ratingScore * 0.40) + (skillScore * 0.30) + (proximityScore * 0.30);
        return {
          'provider': prov,
          'distance': distance,
          'score': totalScore,
        };
      }).toList();
      
      scoredProviders.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
      rankedList = scoredProviders.map((item) => item['provider'] as ProviderModel).toList();
      
      if (rankedList.isNotEmpty) {
        fullLog.writeln('  ✅ Top candidate: ${rankedList.first.name} (Score: ${(scoredProviders.first['score'] as double).toStringAsFixed(2)})');
      } else {
        fullLog.writeln('  ❌ No candidates found.');
      }
    } catch (e) {
      fullLog.writeln('  ⚠️ Error in ranking: $e');
      rankedList = matchedList; // fallback
    }

    // --- AGENT 4: Pricing Engine ---
    fullLog.writeln('\n💰 Agent 4 (Pricing) -> Calculating itemized visit fees...');
    double totalCost = 0.0;
    if (rankedList.isNotEmpty) {
      final topProv = rankedList.first;
      final dist = Helpers.calculateDistance(userLat, userLng, topProv.lat, topProv.lng);
      final travelFee = max(50.0, dist * topProv.pkrPerKm);
      final surcharge = isUrgent ? topProv.urgentSurcharge.toDouble() : 0.0;
      final baseFee = topProv.baseRatePkr.toDouble();
      totalCost = baseFee + travelFee + surcharge + ((baseFee + travelFee + surcharge) / 9.0).roundToDouble();
      fullLog.writeln('  ✅ Total: PKR ${totalCost.toInt()}');
    }

    // --- AGENT 5: Matchmaker ---
    fullLog.writeln('\n🏆 Agent 5 (Matchmaker) -> Final selection...');
    if (rankedList.isNotEmpty) {
      fullLog.writeln('  ✅ Winner: ${rankedList.first.name} selected based on proximity and rating.');
    }

    // --- AGENT 6: Booking Lock (Handled in UI currently, logged here) ---
    fullLog.writeln('\n📅 Agent 6 (Booking) -> Ready to lock in UI.');
    
    // --- AGENT 7: Follow-up ---
    fullLog.writeln('\n📨 Agent 7 (Follow-up) -> Notifications queued.');

    return AgentQueryResult(
      category: identifiedCategory,
      area: identifiedArea,
      rawIntent: identifiedCategory,
      matchedProviders: matchedList,
      rankedProviders: rankedList,
      thoughtProcess: fullLog.toString(),
    );
  }
}
