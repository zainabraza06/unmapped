import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class OccupationCard extends StatelessWidget {
  const OccupationCard({
    super.key,
    required this.displayTitle,
    required this.iscoCode,
    this.escoTitle,
    required this.confidence,
    required this.score,
    this.matchReason,
    this.sectors = const [],
  });

  final String displayTitle;
  final String iscoCode;
  final String? escoTitle;
  final String confidence;
  final double score;
  final String? matchReason;
  final List<String> sectors;

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
                Expanded(
                  child: Text(displayTitle, style: AppTextStyles.displaySmall),
                ),
                _ConfidenceBadge(confidence: confidence, score: score),
              ],
            ),
            if (escoTitle != null && escoTitle != displayTitle) ...[
              const SizedBox(height: 4),
              Text('ESCO: $escoTitle', style: AppTextStyles.caption),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _PillTag(label: 'ISCO $iscoCode', color: AppColors.opportunity),
                if (sectors.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sectors.take(2).join(' · '),
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            if (matchReason != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(matchReason!, style: AppTextStyles.caption),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence, required this.score});
  final String confidence;
  final double score;

  @override
  Widget build(BuildContext context) {
    final (bg, text) = switch (confidence.toLowerCase()) {
      'high'   => (AppColors.stableLight,   AppColors.stable),
      'medium' => (AppColors.warningLight,  AppColors.warning),
      _        => (AppColors.neutralLight,  AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${(score * 100).round()}% match',
        style: AppTextStyles.label.copyWith(color: text),
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  const _PillTag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: AppTextStyles.mono.copyWith(color: color),
      ),
    );
  }
}
