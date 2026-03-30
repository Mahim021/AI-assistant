import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../models/message.dart';
import '../../services/alarm_service.dart';
import '../../services/openai_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/quick_action_chips.dart';
import '../settings/settings_screen.dart';

class ChatScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const ChatScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _openAI = OpenAIService();
  final _speech = SpeechToText();

  final List<ChatMessage> _messages = [];
  final List<AttachedFile> _pendingFiles = [];

  String _streamingContent = '';
  bool _isStreaming = false;
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _speech.cancel();
    super.dispose();
  }

  // ─── Init ────────────────────────────────────────────────────────────────

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
      onError: (error) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (mounted) setState(() {});
  }

  // ─── Messaging ───────────────────────────────────────────────────────────

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && _pendingFiles.isEmpty) return;

    final userMsg = ChatMessage(
      id: _id(),
      content: trimmed,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
      attachments: List.from(_pendingFiles),
    );

    setState(() {
      _messages.add(userMsg);
      _pendingFiles.clear();
    });
    _inputController.clear();
    _scrollToBottom();

    // Handle alarm requests without going to OpenAI
    final alarmTime = AlarmService.parseAlarmRequest(trimmed);
    if (alarmTime != null) {
      try {
        await AlarmService.setAlarm(alarmTime, label: trimmed);
        if (!mounted) return;
        setState(() {
          _messages.add(ChatMessage(
            id: _id(),
            content: 'Alarm set for ${alarmTime.formatted}.',
            sender: MessageSender.assistant,
            timestamp: DateTime.now(),
          ));
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _messages.add(ChatMessage(
            id: _id(),
            content: 'Sorry, I couldn\'t set the alarm on this device.',
            sender: MessageSender.assistant,
            timestamp: DateTime.now(),
            isError: true,
          ));
        });
      }
      _scrollToBottom();
      return;
    }

    setState(() {
      _isStreaming = true;
      _streamingContent = '';
    });

    try {
      await for (final chunk in _openAI.streamResponse(messages: _messages)) {
        if (!mounted) return;
        setState(() => _streamingContent += chunk);
        _scrollToBottom();
      }

      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          id: _id(),
          content: _streamingContent,
          sender: MessageSender.assistant,
          timestamp: DateTime.now(),
        ));
        _isStreaming = false;
        _streamingContent = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isStreaming = false;
        _streamingContent = '';
        _messages.add(ChatMessage(
          id: _id(),
          content: e.toString().replaceFirst('Exception: ', ''),
          sender: MessageSender.assistant,
          timestamp: DateTime.now(),
          isError: true,
        ));
      });
    }
    _scrollToBottom();
  }

  // ─── Attachment ───────────────────────────────────────────────────────────

  void _showAttachmentSheet() {
    final isDark = widget.isDarkMode;
    final cardColor = isDark ? const Color(0xFF1E1E2A) : AppColors.lightCard;
    final borderColor = isDark ? const Color(0xFF2A2A3A) : AppColors.lightBorder;
    final subColor = isDark ? const Color(0xFF9090A8) : AppColors.lightSubtext;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _AttachOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: const Color(0xFF4CA3FF),
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImages();
                  },
                ),
                const SizedBox(width: 12),
                _AttachOption(
                  icon: Icons.insert_drive_file_rounded,
                  label: 'File',
                  color: const Color(0xFFFF9044),
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    _pickFiles();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Share photos from your gallery or attach any document',
              style: TextStyle(color: subColor, fontSize: 12.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final picked = result.files
          .where((f) => f.bytes != null)
          .map((f) => AttachedFile(
                name: f.name,
                mimeType: _mimeFromName(f.name),
                bytes: f.bytes!,
              ))
          .toList();
      if (picked.isEmpty) return;
      setState(() => _pendingFiles.addAll(picked));
    } catch (e) {
      _showSnack('Could not open gallery.');
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final picked = result.files
          .where((f) => f.bytes != null)
          .map((f) => AttachedFile(
                name: f.name,
                mimeType: _mimeFromName(f.name),
                bytes: f.bytes!,
              ))
          .toList();
      if (picked.isEmpty) return;
      setState(() => _pendingFiles.addAll(picked));
    } catch (e) {
      _showSnack('Could not open file picker.');
    }
  }

  // ─── Voice input ─────────────────────────────────────────────────────────

  Future<void> _toggleVoice() async {
    if (!_speechAvailable) {
      _showSnack('Speech recognition is not available on this device.');
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    setState(() {
      _isListening = true;
      _inputController.clear();
    });

    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _inputController.text = result.recognizedWords;
            _inputController.selection = TextSelection.fromPosition(
              TextPosition(offset: _inputController.text.length),
            );
          });
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      localeId: 'en_US',
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SettingsScreen(
        onToggleTheme: widget.onToggleTheme,
        isDarkMode: widget.isDarkMode,
      ),
    ));
  }

  String _mimeFromName(String name) {
    final ext = name.split('.').last.toLowerCase();
    const map = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'bmp': 'image/bmp',
      'pdf': 'application/pdf',
      'txt': 'text/plain',
      'md': 'text/markdown',
      'json': 'application/json',
      'csv': 'text/csv',
      'html': 'text/html',
      'xml': 'text/xml',
      'dart': 'text/x-dart',
      'py': 'text/x-python',
      'js': 'text/javascript',
      'ts': 'text/typescript',
      'kt': 'text/x-kotlin',
      'swift': 'text/x-swift',
      'java': 'text/x-java',
    };
    return map[ext] ?? 'application/octet-stream';
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          Expanded(child: _buildBody(isDark)),
          if (_pendingFiles.isNotEmpty) _buildPendingFiles(isDark),
          _buildQuickActions(),
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final iconColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      title: Text(
        'AI Assistant',
        style: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _openSettings,
          icon: Icon(Icons.settings_outlined, color: iconColor, size: 24),
          splashRadius: 20,
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: borderColor),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_messages.isEmpty && !_isStreaming) {
      return _buildEmptyState(isDark);
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length + (_isStreaming ? 1 : 0),
      itemBuilder: (context, i) {
        if (i < _messages.length) {
          return MessageBubble(message: _messages[i]);
        }
        return StreamingBubble(content: _streamingContent);
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const FeatureCard(
            icon: Icons.auto_awesome_rounded,
            title: 'Smart Analysis',
            subtitle:
                'Analyze documents, write code, or brainstorm creative ideas with GPT-4o mini.',
            iconColor: AppColors.primaryBlue,
          ),
          const SizedBox(height: 12),
          FeatureCard(
            icon: Icons.lock_rounded,
            title: 'Private & Secure',
            subtitle:
                'Your conversations go directly to OpenAI and are never stored on external servers.',
            iconColor:
                isDark ? const Color(0xFF3D7FFF) : AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingFiles(bool isDark) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bgColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: borderColor),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _pendingFiles.asMap().entries.map((entry) {
              final i = entry.key;
              final file = entry.value;
              return _PendingFileChip(
                file: file,
                isDark: isDark,
                onRemove: () => setState(() => _pendingFiles.removeAt(i)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 6),
      child: QuickActionChips(
        onTap: (label) {
          _inputController.text = label;
          _focusNode.requestFocus();
        },
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inputBg = isDark ? AppColors.darkInputBg : AppColors.lightInputBg;
    final hintColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final iconColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final bgColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Attach button
            _InputIconButton(
              icon: Icons.attach_file_rounded,
              color: iconColor,
              onTap: _showAttachmentSheet,
            ),
            const SizedBox(width: 6),
            // Text field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        focusNode: _focusNode,
                        style: TextStyle(color: textColor, fontSize: 15),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _isStreaming ? null : _sendMessage,
                        decoration: InputDecoration(
                          hintText: _isListening
                              ? 'Listening...'
                              : 'Ask anything...',
                          hintStyle: TextStyle(
                            color: _isListening
                                ? AppColors.primaryBlue
                                : hintColor,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                        ),
                      ),
                    ),
                    // Mic button inside field
                    _InputIconButton(
                      icon: _isListening
                          ? Icons.mic_rounded
                          : Icons.mic_none_rounded,
                      color: _isListening ? AppColors.primaryBlue : iconColor,
                      onTap: _toggleVoice,
                      padding: const EdgeInsets.only(right: 6),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            GestureDetector(
              onTap: _isStreaming
                  ? null
                  : () => _sendMessage(_inputController.text),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _isStreaming
                      ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                      : AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: _isStreaming
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white54),
                        ),
                      )
                    : const Icon(Icons.arrow_upward_rounded,
                        color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Small reusable widgets ──────────────────────────────────────────────────

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF0F0F14) : AppColors.lightSurface;
    final borderColor = isDark ? const Color(0xFF2A2A3A) : AppColors.lightBorder;
    final textColor = isDark ? const Color(0xFFE8E8F0) : AppColors.lightText;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final EdgeInsets padding;

  const _InputIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

class _PendingFileChip extends StatelessWidget {
  final AttachedFile file;
  final bool isDark;
  final VoidCallback onRemove;

  const _PendingFileChip({
    required this.file,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (file.isImage) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              Uint8List.fromList(file.bytes),
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_drive_file_rounded,
            size: 14,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              file.name,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
          ),
        ],
      ),
    );
  }
}
