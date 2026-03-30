import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4o-mini';
  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static const String _systemPrompt =
      'You are a helpful, concise, and intelligent AI assistant. '
      'Respond clearly and accurately to user queries. '
      'When sharing code, use proper markdown code blocks with language identifiers. '
      'Keep responses focused and avoid unnecessary padding.';

  /// Streams text chunks from GPT-4o-mini. Throws [Exception] on API errors.
  Stream<String> streamResponse({
    required List<ChatMessage> messages,
  }) async* {
    final apiMessages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _systemPrompt},
      ...messages.map(_toApiMessage),
    ];

    final request = http.Request('POST', Uri.parse(_baseUrl));
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    });
    request.body = jsonEncode({
      'model': _model,
      'messages': apiMessages,
      'stream': true,
      'max_tokens': 2048,
      'temperature': 0.7,
    });

    final client = http.Client();
    try {
      final response = await client.send(request);

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        String errorMessage = 'API Error ${response.statusCode}';
        try {
          final decoded = jsonDecode(body) as Map<String, dynamic>;
          final err = decoded['error'] as Map<String, dynamic>?;
          errorMessage = err?['message'] as String? ?? errorMessage;
        } catch (_) {}
        throw Exception(errorMessage);
      }

      // Parse SSE stream
      String buffer = '';
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        final lines = buffer.split('\n');
        // Keep the last (potentially incomplete) line in the buffer
        buffer = lines.removeLast();

        for (final line in lines) {
          final trimmed = line.trim();
          if (!trimmed.startsWith('data: ')) continue;
          final data = trimmed.substring(6);
          if (data == '[DONE]') return;
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List<dynamic>;
            if (choices.isEmpty) continue;
            final delta = choices[0]['delta'] as Map<String, dynamic>?;
            final content = delta?['content'] as String?;
            if (content != null && content.isNotEmpty) yield content;
          } catch (_) {}
        }
      }
    } finally {
      client.close();
    }
  }

  Map<String, dynamic> _toApiMessage(ChatMessage message) {
    final role = message.isUser ? 'user' : 'assistant';

    if (message.attachments.isEmpty) {
      return {'role': role, 'content': message.content};
    }

    // Build multipart content for messages with attachments
    final parts = <Map<String, dynamic>>[];

    if (message.content.isNotEmpty) {
      parts.add({'type': 'text', 'text': message.content});
    }

    for (final file in message.attachments) {
      if (file.isImage) {
        final base64Data = base64Encode(file.bytes);
        parts.add({
          'type': 'image_url',
          'image_url': {
            'url': 'data:${file.mimeType};base64,$base64Data',
            'detail': 'auto',
          },
        });
      } else if (file.isText) {
        final textContent = _tryDecodeText(file.bytes);
        parts.add({
          'type': 'text',
          'text': '\n\n[File: ${file.name}]\n```\n$textContent\n```',
        });
      } else {
        parts.add({
          'type': 'text',
          'text': '\n\n[Attached binary file: ${file.name} — content not shown]',
        });
      }
    }

    if (parts.isEmpty) {
      return {'role': role, 'content': message.content};
    }

    return {'role': role, 'content': parts};
  }

  String _tryDecodeText(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return '(could not decode file content)';
    }
  }
}
