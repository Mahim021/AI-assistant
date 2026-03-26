import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QuickActionChips extends StatelessWidget {
  final void Function(String label) onTap;

  const QuickActionChips({super.key, required this.onTap});

  static const _actions = [
    'Generate code',
    'Summarize text',
    'Explain concept',
    'Translate',
    'Write email',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final chipBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _actions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () => onTap(_actions[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: chipBorder, width: 1),
              ),
              child: Text(
                _actions[i],
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
