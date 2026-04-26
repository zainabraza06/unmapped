import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Universal opportunity card covering direct, adjacent, and micro-enterprise types.
class OpportunityCard extends StatelessWidget {
  const OpportunityCard({
    super.key,
    required this.title,
    required this.incomeRange,
    required this.demandStrength,
    required this.entryBarrier,
    required this.stability,
    required this.reason,
    this.iscoCode,
    this.requiredUpskilling = const [],
    this.type = OpportunityCardType.direct,
  });

  final String title;
  final String incomeRange;
  final String demandStrength;
  final String entryBarrier;
  final String stability;
  final String reason;
  final String? iscoCode;
  final List<String> requiredUpskilling;
  final OpportunityCardType type;

  @override
  Widget build(BuildContext context) {
    final accentColor = _accentFor(type);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_iconFor(type), size: 18, color: accentColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.title),
                      if (iscoCode != null && iscoCode!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'ISCO $iscoCode',
                            style: AppTextStyles.mono,
                          ),
                        ),
                    ],
                  ),
                ),
                _StabilityBadge(stability: stability),
              ],
            ),
            const SizedBox(height: 12),
            // Metrics row
            _MetricsRow(
              incomeRange: incomeRange,
              demandStrength: demandStrength,
              entryBarrier: entryBarrier,
            ),
            // Upskilling (adjacent only)
            if (requiredUpskilling.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Required upskilling', style: AppTextStyles.label),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: requiredUpskilling
                    .map((s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(s, style: AppTextStyles.caption.copyWith(
                            color: AppColors.warning,
                          )),
                        ))
                    .toList(),
              ),
            ],
            // Reason
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
                  const Icon(Icons.lightbulb_outline, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(child: Text(reason, style: AppTextStyles.caption)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _accentFor(OpportunityCardType t) => switch (t) {
    OpportunityCardType.direct      => AppColors.opportunity,
    OpportunityCardType.adjacent    => AppColors.warning,
    OpportunityCardType.micro       => AppColors.stable,
  };

  static IconData _iconFor(OpportunityCardType t) => switch (t) {
    OpportunityCardType.direct   => Icons.work_outline,
    OpportunityCardType.adjacent => Icons.trending_up,
    OpportunityCardType.micro    => Icons.store_outlined,
  };
}

enum OpportunityCardType { direct, adjacent, micro }

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
    required this.incomeRange,
    required this.demandStrength,
    required this.entryBarrier,
  });
  final String incomeRange;
  final String demandStrength;
  final String entryBarrier;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Metric(label: 'Income', value: incomeRange, icon: Icons.payments_outlined),
        const SizedBox(width: 8),
        _Metric(label: 'Demand', value: demandStrength, icon: Icons.bar_chart),
        const SizedBox(width: 8),
        _Metric(label: 'Entry', value: entryBarrier, icon: Icons.door_front_door_outlined),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.label),
            const SizedBox(height: 2),
            Text(
              value.isEmpty ? '—' : value,
              style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StabilityBadge extends StatelessWidget {
  const _StabilityBadge({required this.stability});
  final String stability;

  @override
  Widget build(BuildContext context) {
    final (bg, text) = switch (stability.toLowerCase()) {
      'stable'   => (AppColors.stableLight,  AppColors.stable),
      'moderate' => (AppColors.warningLight, AppColors.warning),
      _          => (AppColors.riskLight,    AppColors.risk),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(stability, style: AppTextStyles.label.copyWith(color: text)),
    );
  }
}
