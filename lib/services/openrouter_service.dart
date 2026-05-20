import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/utils/helpers.dart';

class OpenRouterService {
  static const String _apiKey = 'Paste the API here!';
  static const String _url = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _model = 'openai/gpt-oss-120b:free';

  static Future<String> chat(String systemPrompt, String userMessage) async {
    try {
      Helpers.log('OpenRouter', 'Sending request to $_model...');
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            if (systemPrompt.isNotEmpty) {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return content;
      } else {
        Helpers.log('OpenRouter', 'Error ${response.statusCode}: ${response.body}', isError: true);
        throw Exception('OpenRouter API Error: ${response.statusCode}');
      }
    } catch (e) {
      Helpers.log('OpenRouter', 'Exception: $e', isError: true);
      rethrow;
    }
  }
}
