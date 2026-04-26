import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class RiskTaskCard extends StatelessWidget {
  const RiskTaskCard({
    super.key,
    required this.task,
    required this.riskScore,
    required this.isHighRisk,
  });

  final String task;
  final double riskScore;
  final bool isHighRisk;

  @override
  Widget build(BuildContext context) {
    final color = isHighRisk ? AppColors.risk : AppColors.stable;
    final bgColor = isHighRisk ? AppColors.riskLight : AppColors.stableLight;
    final scoreLabel = '${(riskScore * 100).round()}%';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isHighRisk ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(task, style: AppTextStyles.body),
          ),
          const SizedBox(width: 8),
          Text(
            scoreLabel,
            style: AppTextStyles.label.copyWith(color: color),
          ),
          const SizedBox(width: 8),
          // Inline bar
          SizedBox(
            width: 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: riskScore,
                minHeight: 4,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
