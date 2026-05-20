
class AgentLogModel {
  final String id;
  final String userId;
  final String agentName; // 'IntentAgent', 'DiscoveryAgent', 'RankingAgent', 'BookingAgent'
  final String thoughtProcess; // Gemini reasoning trails (transparency)
  final String userInput; // User raw prompt (in Roman Urdu or English)
  final String agentOutput; // System outcome
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  AgentLogModel({
    required this.id,
    required this.userId,
    required this.agentName,
    required this.thoughtProcess,
    required this.userInput,
    required this.agentOutput,
    required this.timestamp,
    this.metadata,
  });

  factory AgentLogModel.fromMap(Map<String, dynamic> map) {
    return AgentLogModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      agentName: map['agentName'] ?? '',
      thoughtProcess: map['thoughtProcess'] ?? '',
      userInput: map['userInput'] ?? '',
      agentOutput: map['agentOutput'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'agentName': agentName,
      'thoughtProcess': thoughtProcess,
      'userInput': userInput,
      'agentOutput': agentOutput,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}
