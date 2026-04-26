import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/module2_analysis.dart';
import '../../core/models/module3_analysis.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (!state.hasOpportunities && !state.hasRisk && !state.hasProfile) {
      return const EmptyState(
        icon: Icons.bar_chart_outlined,
        title: 'No insights yet',
        subtitle: 'Complete the full pipeline (Skills → Risk → Opportunities) to see policy-level insights.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InsightsHeader(countryName: state.countryName),
          const SizedBox(height: AppSpacing.md),

          // Pipeline status
          _PipelineStatus(
            hasProfile: state.hasProfile,
            hasRisk: state.hasRisk,
            hasOpportunities: state.hasOpportunities,
          ),
          const SizedBox(height: AppSpacing.md),

          // Module 2 risk summary
          if (state.hasRisk) ...[
            const SectionHeader('Automation Risk Summary'),
            _RiskSummaryCards(risk: state.risk!),
            const SizedBox(height: AppSpacing.md),
          ],

          // Module 3 economic signals
          if (state.hasOpportunities) ...[
            const SectionHeader(
              'Labor Market Signals',
              subtitle: 'Grounded in ILOSTAT + World Bank WDI 2024',
            ),
            _EconomicSignalsList(
              signals: state.opportunities!.laborMarketContext.keyEconomicSignals.nonNullSignals,
            ),
            const SizedBox(height: AppSpacing.md),

            // Policy view
            const SectionHeader(
              'Policy View',
              subtitle: 'For governments, NGOs, and training providers',
            ),
            _PolicyViewPanel(policyView: state.opportunities!.policyView),
            const SizedBox(height: AppSpacing.md),

            // Explainability
            if (state.opportunities!.keyDrivers.isNotEmpty) ...[
              const SectionHeader('Analysis Drivers'),
              _BulletList(
                items: state.opportunities!.keyDrivers,
                color: AppColors.opportunity,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],

          // Module 2 explainability
          if (state.hasRisk && state.risk!.keyDrivers.isNotEmpty) ...[
            const SectionHeader('Risk Analysis Drivers'),
            _BulletList(
              items: state.risk!.keyDrivers,
              color: AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Data sources footer
          const _SourcesFooter(),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _InsightsHeader extends StatelessWidget {
  const _InsightsHeader({required this.countryName});
  final String countryName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Policy Insights',
            style: AppTextStyles.displaySmall.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            '$countryName · Labor Intelligence Dashboard',
            style: AppTextStyles.body.copyWith(color: Colors.white.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }
}

class _PipelineStatus extends StatelessWidget {
  const _PipelineStatus({
    required this.hasProfile,
    required this.hasRisk,
    required this.hasOpportunities,
  });
  final bool hasProfile;
  final bool hasRisk;
  final bool hasOpportunities;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analysis Pipeline', style: AppTextStyles.title),
            const SizedBox(height: 10),
            _StatusRow(label: 'M01 — Skills Profile', done: hasProfile),
            _StatusRow(label: 'M02 — Risk Analysis', done: hasRisk),
            _StatusRow(label: 'M03 — Opportunity Matching', done: hasOpportunities),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.done});
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: done ? AppColors.stable : AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Text(label, style: AppTextStyles.body.copyWith(
            color: done ? AppColors.textPrimary : AppColors.textMuted,
          )),
        ],
      ),
    );
  }
}

class _RiskSummaryCards extends StatelessWidget {
  const _RiskSummaryCards({required this.risk});
  final Module2Analysis risk;

  @override
  Widget build(BuildContext context) {
    final fp = risk.finalReadinessProfile;
    final aa = risk.automationAnalysis;
    final base = aa.baseAutomationProbability;
    final adj  = aa.adjustedAutomationProbability;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Risk Level',
            value: fp.riskLevel.name.toUpperCase().replaceAll('_', ' '),
            color: _riskColor(fp.riskLevel.name),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'LMIC-Adjusted',
            value: adj != null ? '${(adj * 100).round()}%' : '—',
            sublabel: base != null ? 'Baseline ${(base * 100).round()}%' : null,
            color: AppColors.opportunity,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Resilience',
            value: fp.resilienceLevel.name.toUpperCase(),
            color: _resColor(fp.resilienceLevel.name),
          ),
        ),
      ],
    );
  }

  static Color _riskColor(String s) => switch (s) {
    'low'       => AppColors.stable,
    'medium'    => AppColors.warning,
    'high'      => AppColors.risk,
    'veryHigh'  => AppColors.risk,
    _           => AppColors.neutral,
  };

  static Color _resColor(String s) => switch (s) {
    'high'   => AppColors.stable,
    'medium' => AppColors.warning,
    _        => AppColors.risk,
  };
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.sublabel,
    required this.color,
  });
  final String label;
  final String value;
  final String? sublabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.label, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.title.copyWith(color: color), textAlign: TextAlign.center),
          if (sublabel != null) Text(sublabel!, style: AppTextStyles.mono, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _EconomicSignalsList extends StatelessWidget {
  const _EconomicSignalsList({required this.signals});
  final List<MapEntry<String, EconomicSignal>> signals;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: signals.map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(entry.key, style: AppTextStyles.label),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      entry.value.value,
                      style: AppTextStyles.title,
                      textAlign: TextAlign.end,
                    ),
                    if (entry.value.source != null)
                      Text(
                        entry.value.source!,
                        style: AppTextStyles.mono,
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _PolicyViewPanel extends StatelessWidget {
  const _PolicyViewPanel({required this.policyView});
  final PolicyView policyView;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PolicyRow(
              icon: Icons.search_outlined,
              label: 'Labor gap identified',
              value: policyView.laborGapIdentified,
              color: AppColors.warning,
            ),
            const Divider(height: 20),
            _PolicyRow(
              icon: Icons.factory_outlined,
              label: 'Sector shortage signal',
              value: policyView.sectorShortageSignal,
              color: AppColors.opportunity,
            ),
            const Divider(height: 20),
            _PolicyRow(
              icon: Icons.policy_outlined,
              label: 'Recommendation',
              value: policyView.recommendationForGovernmentOrNgos,
              color: AppColors.stable,
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyRow extends StatelessWidget {
  const _PolicyRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.label.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: AppTextStyles.body),
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items, required this.color});
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6, height: 6,
                  margin: const EdgeInsets.only(top: 7),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(item, style: AppTextStyles.body)),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }
}

class _SourcesFooter extends StatelessWidget {
  const _SourcesFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.neutralLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Data Sources', style: AppTextStyles.label),
          const SizedBox(height: 6),
          ...[
            'ESCO Taxonomy (EU Commission)',
            'ISCO-08 (ILO)',
            'ILOSTAT — Employment by sector & education',
            'World Bank WDI 2024 — GDP, NEET, self-employment',
            'Frey & Osborne (2017) — Automation probabilities',
            'ITU Digital Development Data 2024',
            'Wittgenstein Centre — Education projections',
          ].map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text('· $s', style: AppTextStyles.caption),
          )),
        ],
      ),
    );
  }
}
