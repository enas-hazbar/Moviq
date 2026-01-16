import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class OllamaService {
  final String baseUrl;

  OllamaService({String? baseUrl})
      : baseUrl = baseUrl ?? _defaultBaseUrl();

  static String _defaultBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:11434';
    }
    return 'http://127.0.0.1:11434';
  }

  Stream<String> streamResponse(String prompt) async* {
    final url = Uri.parse('$baseUrl/api/generate');

    final request = http.Request('POST', url);
    request.headers['Content-Type'] = 'application/json';

    request.body = jsonEncode({
      'model': 'llama3',
      'prompt': prompt,
      'stream': true,
      'options': {
        'temperature': 0.7,
        'top_p': 0.9,
        'num_predict': 220,
      }
    });

    final response = await request.send();

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception('Ollama error ${response.statusCode}: $body');
    }

    await for (final chunk in response.stream.transform(utf8.decoder)) {
      for (final line in chunk.split('\n')) {
        if (line.trim().isEmpty) continue;

        final data = jsonDecode(line);
        if (data is Map && data['done'] == true) return;

        final token = (data['response'] ?? '').toString();
        if (token.isNotEmpty) yield token;
      }
    }
  }
}
