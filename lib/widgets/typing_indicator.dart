import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _animations = _controllers
        .map((c) => Tween<double>(begin: 0, end: -6).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    _startAnimation();
  }

  void _startAnimation() async {
    while (mounted) {
      for (int i = 0; i < 3; i++) {
        if (!mounted) return;
        _controllers[i].forward();
        await Future.delayed(const Duration(milliseconds: 150));
      }
      await Future.delayed(const Duration(milliseconds: 300));
      for (int i = 0; i < 3; i++) {
        if (!mounted) return;
        _controllers[i].reverse();
        await Future.delayed(const Duration(milliseconds: 100));
      }
      await Future.delayed(const Duration(milliseconds: 200));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isDark
        ? AppColors.darkAssistantBubble
        : AppColors.lightAssistantBubble;
    final dotColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _AssistantAvatar(isDark: isDark),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _animations[i],
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _animations[i].value),
                    child: Container(
                      margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _AssistantAvatar extends StatelessWidget {
  final bool isDark;
  const _AssistantAvatar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
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
      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
    );
  }
}
