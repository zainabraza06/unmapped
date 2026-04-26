import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/module2_analysis.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/risk_task_card.dart';
import '../../widgets/shared.dart';

class RiskScreen extends StatelessWidget {
  const RiskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.loadingM2) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: LoadingCard(message: 'Analysing automation risk and LMIC calibration…'),
        ),
      );
    }

    if (state.errorM2 != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ErrorCard(
            message: state.errorM2!,
            onRetry: state.analyseRisk,
          ),
        ),
      );
    }

    if (!state.hasRisk) {
      return EmptyState(
        icon: Icons.show_chart_outlined,
        title: 'No risk analysis yet',
        subtitle: 'Generate your skills profile first. Risk analysis runs automatically.',
        action: state.hasProfile
            ? ElevatedButton(
                onPressed: state.analyseRisk,
                child: const Text('Run Risk Analysis'),
              )
            : null,
      );
    }

    final risk = state.risk!;
    final aa = risk.automationAnalysis;
    final fp = risk.finalReadinessProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Readiness summary card
          _ReadinessSummaryCard(profile: fp, occupation: risk.occupationTitle),
          const SizedBox(height: AppSpacing.md),

          // Probability comparison
          _ProbabilityCard(analysis: aa),
          const SizedBox(height: AppSpacing.md),

          // LMIC adjustment explanation
          if (aa.lmicAdjustmentExplanation.isNotEmpty) ...[
            const SectionHeader(
              'LMIC Calibration',
              subtitle: 'Why automation risk was adjusted for this country',
            ),
            _AdjustmentBox(explanations: aa.lmicAdjustmentExplanation),
            const SizedBox(height: AppSpacing.md),
          ],

          // Task breakdown
          const SectionHeader('Task Breakdown'),
          _TaskBreakdownSection(breakdown: risk.taskBreakdown),
          const SizedBox(height: AppSpacing.md),

          // Skill resilience
          const SectionHeader(
            'Skill Resilience',
            subtitle: 'How your skills hold up against automation',
          ),
          _SkillResilienceSection(analysis: risk.skillResilienceAnalysis),
          const SizedBox(height: AppSpacing.md),

          // Economic context
          _EconomicContextCard(context: risk.economicContext),
          const SizedBox(height: AppSpacing.md),

          // Macro signals
          _MacroSignalsCard(signals: risk.macroSignals),
          const SizedBox(height: AppSpacing.md),

          // Key drivers
          if (risk.keyDrivers.isNotEmpty) ...[
            const SectionHeader('Key Risk Drivers'),
            _KeyDriversList(drivers: risk.keyDrivers),
          ],
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ───────────────────────────────────────────────────────────────

class _ReadinessSummaryCard extends StatelessWidget {
  const _ReadinessSummaryCard({
    required this.profile,
    required this.occupation,
  });
  final FinalReadinessProfile profile;
  final String occupation;

  @override
  Widget build(BuildContext context) {
    final riskLabel = profile.riskLevel.name.replaceAll('_', ' ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(occupation, style: AppTextStyles.headline),
                ),
                RiskLevelBadge(riskLabel),
              ],
            ),
            const SizedBox(height: 10),
            Text(profile.summary, style: AppTextStyles.body),
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniChip(
                  label: 'Resilience: ${profile.resilienceLevel.name}',
                  color: _resilienceColor(profile.resilienceLevel),
                ),
                const SizedBox(width: 8),
                _MiniChip(
                  label: profile.opportunityType.name.replaceAll('_', ' '),
                  color: AppColors.opportunity,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Color _resilienceColor(ResilienceLevel l) => switch (l) {
    ResilienceLevel.high   => AppColors.stable,
    ResilienceLevel.medium => AppColors.warning,
    ResilienceLevel.low    => AppColors.risk,
  };
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: AppTextStyles.label.copyWith(color: color)),
    );
  }
}

class _ProbabilityCard extends StatelessWidget {
  const _ProbabilityCard({required this.analysis});
  final AutomationAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final base = analysis.baseAutomationProbability;
    final adj  = analysis.adjustedAutomationProbability;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Automation Probability', style: AppTextStyles.title),
            const SizedBox(height: 4),
            Text(analysis.sourceModel, style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _ProbColumn(
                  label: 'OECD Baseline',
                  value: base,
                  color: AppColors.neutral,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const Icon(Icons.arrow_forward, color: AppColors.textMuted, size: 18),
                      const SizedBox(height: 2),
                      Text('×${analysis.adjustmentFactor.toStringAsFixed(2)}',
                          style: AppTextStyles.mono),
                    ],
                  ),
                ),
                _ProbColumn(
                  label: 'LMIC-Adjusted',
                  value: adj,
                  color: _riskColor(adj),
                ),
              ],
            ),
            if (analysis.uncertaintyBand != null) ...[
              const SizedBox(height: 8),
              Text(
                '±${_pct(analysis.uncertaintyBand)} uncertainty band',
                style: AppTextStyles.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Color _riskColor(double? v) {
    if (v == null) return AppColors.neutral;
    if (v < 0.35) return AppColors.stable;
    if (v < 0.65) return AppColors.warning;
    return AppColors.risk;
  }

  static String _pct(double? v) =>
      v == null ? '—' : '${(v * 100).round()}%';
}

class _ProbColumn extends StatelessWidget {
  const _ProbColumn({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = value == null ? '—' : '${(value! * 100).round()}%';
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(pct,
              style: AppTextStyles.displaySmall.copyWith(color: color, fontSize: 32),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value ?? 0,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdjustmentBox extends StatelessWidget {
  const _AdjustmentBox({required this.explanations});
  final List<String> explanations;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.opportunityLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.opportunity.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: explanations
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, size: 6, color: AppColors.opportunity),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e, style: AppTextStyles.body)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TaskBreakdownSection extends StatelessWidget {
  const _TaskBreakdownSection({required this.breakdown});
  final TaskBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (breakdown.highRiskTasks.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.risk),
              const SizedBox(width: 6),
              Text('High-Risk Tasks', style: AppTextStyles.label.copyWith(color: AppColors.risk)),
            ],
          ),
          const SizedBox(height: 8),
          ...breakdown.highRiskTasks.map(
            (t) => RiskTaskCard(task: t.task, riskScore: t.riskScore, isHighRisk: true),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (breakdown.lowRiskTasks.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 14, color: AppColors.stable),
              const SizedBox(width: 6),
              Text('Low-Risk Tasks', style: AppTextStyles.label.copyWith(color: AppColors.stable)),
            ],
          ),
          const SizedBox(height: 8),
          ...breakdown.lowRiskTasks.map(
            (t) => RiskTaskCard(task: t.task, riskScore: t.riskScore, isHighRisk: false),
          ),
        ],
      ],
    );
  }
}

class _SkillResilienceSection extends StatelessWidget {
  const _SkillResilienceSection({required this.analysis});
  final SkillResilienceAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (analysis.atRiskSkills.isNotEmpty) _ResilienceRow(
          label: 'At Risk',
          skills: analysis.atRiskSkills,
          color: AppColors.risk,
          icon: Icons.warning_amber_rounded,
        ),
        if (analysis.durableSkills.isNotEmpty) _ResilienceRow(
          label: 'Durable',
          skills: analysis.durableSkills,
          color: AppColors.stable,
          icon: Icons.shield_outlined,
        ),
        if (analysis.adjacentSkills.isNotEmpty) _ResilienceRow(
          label: 'Adjacent (upskilling path)',
          skills: analysis.adjacentSkills,
          color: AppColors.opportunity,
          icon: Icons.trending_up,
        ),
      ],
    );
  }
}

class _ResilienceRow extends StatelessWidget {
  const _ResilienceRow({
    required this.label,
    required this.skills,
    required this.color,
    required this.icon,
  });
  final String label;
  final List<String> skills;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.label.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: skills.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Text(s, style: AppTextStyles.caption.copyWith(color: color)),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _EconomicContextCard extends StatelessWidget {
  const _EconomicContextCard({required this.context});
  final EconomicContext context;

  @override
  Widget build(BuildContext context_) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Economic Context', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            DataRow(label: 'Country', value: context.country),
            DataRow(label: 'Informality level', value: context.informalityLevel),
            const SizedBox(height: 8),
            Text(context.interpretation, style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}

class _MacroSignalsCard extends StatelessWidget {
  const _MacroSignalsCard({required this.signals});
  final MacroSignals signals;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Macro Trends', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            _SignalRow(
              icon: Icons.school_outlined,
              label: 'Education',
              value: signals.educationProjection,
            ),
            const SizedBox(height: 8),
            _SignalRow(
              icon: Icons.factory_outlined,
              label: 'Labor shift',
              value: signals.laborShiftTrend,
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalRow extends StatelessWidget {
  const _SignalRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.label),
            const SizedBox(height: 2),
            SizedBox(
              width: MediaQuery.of(context).size.width - 100,
              child: Text(value, style: AppTextStyles.body),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeyDriversList extends StatelessWidget {
  const _KeyDriversList({required this.drivers});
  final List<String> drivers;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: drivers.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${entry.key + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(entry.value, style: AppTextStyles.body)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
