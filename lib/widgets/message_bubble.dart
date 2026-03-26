import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (message.isUser) return _UserBubble(message: message);
    return _AssistantBubble(message: message, isDark: isDark);
  }
}

/// A bubble that renders streaming text live as chunks arrive.
class StreamingBubble extends StatelessWidget {
  final String content;
  const StreamingBubble({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor =
        isDark ? AppColors.darkAssistantBubble : AppColors.lightAssistantBubble;
    final textColor =
        isDark ? AppColors.darkAssistantText : AppColors.lightAssistantText;
    final subtextColor =
        isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AssistantAvatar(isDark: isDark),
              const SizedBox(width: 8),
              Text(
                'ASSISTANT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: subtextColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
              child: content.isEmpty
                  ? _ThinkingDots(isDark: isDark)
                  : Text(
                      content,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── User bubble ────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  final ChatMessage message;
  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor =
        isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'YOU • ${_formatTime(message.timestamp)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: subtextColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          // Attachment previews
          if (message.attachments.isNotEmpty) ...[
            _AttachmentsRow(attachments: message.attachments, isUser: true),
            const SizedBox(height: 6),
          ],
          if (message.content.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Text(
                      message.content,
                      style: const TextStyle(
                        color: AppColors.userText,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Assistant bubble ────────────────────────────────────────────────────────

class _AssistantBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;
  const _AssistantBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bubbleColor =
        message.isError
            ? Colors.red.withValues(alpha: 0.12)
            : isDark
                ? AppColors.darkAssistantBubble
                : AppColors.lightAssistantBubble;
    final textColor = message.isError
        ? Colors.redAccent
        : isDark
            ? AppColors.darkAssistantText
            : AppColors.lightAssistantText;
    final subtextColor =
        isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AssistantAvatar(isDark: isDark),
              const SizedBox(width: 8),
              Text(
                'ASSISTANT • ${_formatTime(message.timestamp)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: subtextColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isError)
                    const Padding(
                      padding: EdgeInsets.only(right: 8, top: 1),
                      child:
                          Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                    ),
                  Flexible(
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ──────────────────────────────────────────────────────────

class _AttachmentsRow extends StatelessWidget {
  final List<AttachedFile> attachments;
  final bool isUser;
  const _AttachmentsRow({required this.attachments, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: isUser ? WrapAlignment.end : WrapAlignment.start,
      spacing: 8,
      runSpacing: 8,
      children: attachments.map((f) {
        if (f.isImage) return _ImagePreview(file: f);
        return _FileChip(file: f);
      }).toList(),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final AttachedFile file;
  const _ImagePreview({required this.file});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.memory(
        Uint8List.fromList(file.bytes),
        width: 180,
        height: 140,
        fit: BoxFit.cover,
        errorBuilder: (_, e, s) => _FileChip(file: file),
      ),
    );
  }
}

class _FileChip extends StatelessWidget {
  final AttachedFile file;
  const _FileChip({required this.file});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(8),
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
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              file.name,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantAvatar extends StatelessWidget {
  final bool isDark;
  const _AssistantAvatar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF3D7FFF), const Color(0xFF6A3DE8)]
              : [AppColors.primaryBlue, const Color(0xFF5B35E8)],
        ),
        shape: BoxShape.circle,
      ),
      child:
          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  final bool isDark;
  const _ThinkingDots({required this.isDark});

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 500)),
    );
    _anims = _controllers
        .map((c) => Tween<double>(begin: 0, end: -5).animate(
            CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();
    _loop();
  }

  void _loop() async {
    while (mounted) {
      for (int i = 0; i < 3; i++) {
        if (!mounted) return;
        _controllers[i].forward();
        await Future.delayed(const Duration(milliseconds: 140));
      }
      await Future.delayed(const Duration(milliseconds: 260));
      for (final c in _controllers) {
        if (!mounted) return;
        c.reverse();
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor =
        widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    return SizedBox(
      height: 18,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _anims[i],
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _anims[i].value),
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                width: 7,
                height: 7,
                decoration:
                    BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
            ),
          );
        }),
      ),
    );
  }
}

String _formatTime(DateTime dt) {
  final hour = dt.hour;
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:$minute $period';
}
