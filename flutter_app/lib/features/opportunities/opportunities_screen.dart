import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/module3_analysis.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/economic_signal_card.dart';
import '../../widgets/opportunity_card.dart';
import '../../widgets/shared.dart';

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.loadingM3) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: LoadingCard(message: 'Matching opportunities to your local labor market…'),
        ),
      );
    }

    if (state.errorM3 != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ErrorCard(
            message: state.errorM3!,
            onRetry: state.matchOpportunities,
          ),
        ),
      );
    }

    if (!state.hasOpportunities) {
      return EmptyState(
        icon: Icons.work_outline,
        title: 'No opportunities yet',
        subtitle: 'Generate your skills profile first. Opportunity matching runs automatically.',
        action: state.hasProfile
            ? ElevatedButton(
                onPressed: state.matchOpportunities,
                child: const Text('Find Opportunities'),
              )
            : null,
      );
    }

    final opp = state.opportunities!;
    final ctx  = opp.laborMarketContext;
    final signals = ctx.keyEconomicSignals.nonNullSignals;

    return NestedScrollView(
      headerSliverBuilder: (context, innerScrolled) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Context header
                _ContextHeader(
                  country: ctx.country,
                  informality: ctx.informalityLevel,
                  occupation: opp.occupationTitle,
                ),
                const SizedBox(height: AppSpacing.md),

                // Economic signals grid
                if (signals.isNotEmpty) ...[
                  const SectionHeader(
                    'Economic Signals',
                    subtitle: 'Real data powering this analysis',
                  ),
                  _SignalsGrid(signals: signals),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Ranked summary
                if (opp.ranking.isNotEmpty) ...[
                  const SectionHeader('Top Recommendations'),
                  _RankingList(ranking: opp.ranking),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Tab bar header
                const SectionHeader('All Opportunities'),
              ],
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _SliverTabBarDelegate(
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Direct (${opp.opportunities.direct.length})'),
                Tab(text: 'Adjacent (${opp.opportunities.adjacent.length})'),
                Tab(text: 'Micro (${opp.opportunities.microEnterprise.length})'),
              ],
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _OpportunityList(
            items: opp.opportunities.direct
                .map((o) => _DirectItem(o))
                .toList(),
          ),
          _OpportunityList(
            items: opp.opportunities.adjacent
                .map((o) => _AdjacentItem(o))
                .toList(),
          ),
          _OpportunityList(
            items: opp.opportunities.microEnterprise
                .map((o) => _MicroItem(o))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ───────────────────────────────────────────────────────────────

class _ContextHeader extends StatelessWidget {
  const _ContextHeader({
    required this.country,
    required this.informality,
    required this.occupation,
  });
  final String country;
  final String informality;
  final String occupation;

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
            'Opportunities in $country',
            style: AppTextStyles.displaySmall.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            occupation,
            style: AppTextStyles.body.copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Informality: $informality',
              style: AppTextStyles.label.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalsGrid extends StatelessWidget {
  const _SignalsGrid({required this.signals});
  final List<MapEntry<String, EconomicSignal>> signals;

  static IconData _iconFor(String label) => switch (label.toLowerCase()) {
    String s when s.contains('wage')         => Icons.payments_outlined,
    String s when s.contains('unemployment') => Icons.person_off_outlined,
    String s when s.contains('neet')         => Icons.school_outlined,
    String s when s.contains('gdp')          => Icons.account_balance_outlined,
    String s when s.contains('self')         => Icons.store_outlined,
    String s when s.contains('digital')      => Icons.wifi_outlined,
    String s when s.contains('sector')       => Icons.factory_outlined,
    _                                         => Icons.analytics_outlined,
  };

  static Color _colorFor(String label) => switch (label.toLowerCase()) {
    String s when s.contains('wage')         => AppColors.stable,
    String s when s.contains('unemployment') => AppColors.risk,
    String s when s.contains('neet')         => AppColors.warning,
    String s when s.contains('gdp')          => AppColors.opportunity,
    String s when s.contains('self')         => AppColors.stable,
    String s when s.contains('digital')      => AppColors.opportunity,
    _                                         => AppColors.neutral,
  };

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: signals.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (_, i) {
        final entry = signals[i];
        return EconomicSignalCard(
          label: entry.key,
          value: entry.value.value,
          source: entry.value.source,
          note: entry.value.note,
          icon: _iconFor(entry.key),
          accentColor: _colorFor(entry.key),
        );
      },
    );
  }
}

class _RankingList extends StatelessWidget {
  const _RankingList({required this.ranking});
  final List<RankedOpportunity> ranking;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ranking.take(5).toList().asMap().entries.map((entry) {
        final rank = entry.key + 1;
        final item = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Rank number
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: rank == 1 ? AppColors.stable : AppColors.neutralLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: AppTextStyles.label.copyWith(
                      color: rank == 1 ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.opportunity, style: AppTextStyles.title),
                    Text(item.reason, style: AppTextStyles.caption),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(item.score * 100).round()}',
                style: AppTextStyles.headline.copyWith(
                  color: AppColors.stable,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _OpportunityList extends StatelessWidget {
  const _OpportunityList({required this.items});
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Text('No opportunities in this category.', style: AppTextStyles.body),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => items[i],
    );
  }
}

/// Adapter widgets to convert typed model objects into OpportunityCard calls.
class _DirectItem extends StatelessWidget {
  const _DirectItem(this.o);
  final DirectOpportunity o;

  @override
  Widget build(BuildContext context) => OpportunityCard(
    title: o.title,
    incomeRange: o.incomeRange,
    demandStrength: o.demandStrength,
    entryBarrier: o.entryBarrier,
    stability: o.stability,
    reason: o.reason,
    iscoCode: o.iscoCode,
    type: OpportunityCardType.direct,
  );
}

class _AdjacentItem extends StatelessWidget {
  const _AdjacentItem(this.o);
  final AdjacentOpportunity o;

  @override
  Widget build(BuildContext context) => OpportunityCard(
    title: o.title,
    incomeRange: o.incomeRange,
    demandStrength: o.demandStrength,
    entryBarrier: o.entryBarrier,
    stability: o.stability,
    reason: o.reason,
    iscoCode: o.iscoCode,
    requiredUpskilling: o.requiredUpskilling,
    type: OpportunityCardType.adjacent,
  );
}

class _MicroItem extends StatelessWidget {
  const _MicroItem(this.o);
  final MicroEnterpriseOpportunity o;

  @override
  Widget build(BuildContext context) => OpportunityCard(
    title: o.title,
    incomeRange: o.incomeRange,
    demandStrength: '',
    entryBarrier: o.entryBarrier,
    stability: o.stability,
    reason: o.reason,
    type: OpportunityCardType.micro,
  );
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_SliverTabBarDelegate old) => false;
}
