import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class EconomicSignalCard extends StatelessWidget {
  const EconomicSignalCard({
    super.key,
    required this.label,
    required this.value,
    this.source,
    this.note,
    this.icon,
    this.accentColor = AppColors.neutral,
  });

  final String label;
  final String value;
  final String? source;
  final String? note;
  final IconData? icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: accentColor),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: AppTextStyles.label.copyWith(color: accentColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value.isEmpty ? '—' : value,
              style: AppTextStyles.headline.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            if (note != null) ...[
              const SizedBox(height: 4),
              Text(note!, style: AppTextStyles.caption),
            ],
            if (source != null) ...[
              const SizedBox(height: 4),
              Text(
                'Source: $source',
                style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
