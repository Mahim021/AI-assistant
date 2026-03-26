import 'dart:typed_data';

enum MessageSender { user, assistant }

class AttachedFile {
  final String name;
  final String mimeType;
  final Uint8List bytes;

  const AttachedFile({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  bool get isImage =>
      mimeType.startsWith('image/') ||
      name.endsWith('.jpg') ||
      name.endsWith('.jpeg') ||
      name.endsWith('.png') ||
      name.endsWith('.gif') ||
      name.endsWith('.webp');

  bool get isText =>
      mimeType.startsWith('text/') ||
      name.endsWith('.txt') ||
      name.endsWith('.md') ||
      name.endsWith('.dart') ||
      name.endsWith('.py') ||
      name.endsWith('.js') ||
      name.endsWith('.ts') ||
      name.endsWith('.json') ||
      name.endsWith('.yaml') ||
      name.endsWith('.yml') ||
      name.endsWith('.xml') ||
      name.endsWith('.html') ||
      name.endsWith('.css') ||
      name.endsWith('.kt') ||
      name.endsWith('.swift') ||
      name.endsWith('.java') ||
      name.endsWith('.cpp') ||
      name.endsWith('.c') ||
      name.endsWith('.h');
}

class ChatMessage {
  final String id;
  final String content;
  final MessageSender sender;
  final DateTime timestamp;
  final List<AttachedFile> attachments;
  final bool isError;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    this.attachments = const [],
    this.isError = false,
  });

  bool get isUser => sender == MessageSender.user;
  bool get isAssistant => sender == MessageSender.assistant;
}
