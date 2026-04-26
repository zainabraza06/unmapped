import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/occupation_card.dart';
import '../../widgets/shared.dart';
import '../../widgets/skill_chip.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.loadingM1) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: LoadingCard(message: 'Extracting your skills and matching to occupations…\nThis may take up to 30 seconds.'),
        ),
      );
    }

    if (state.errorM1 != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ErrorCard(
            message: state.errorM1!,
            onRetry: () => state.generateProfile(state.lastIntake!),
          ),
        ),
      );
    }

    if (!state.hasProfile) {
      return const EmptyState(
        icon: Icons.badge_outlined,
        title: 'No profile yet',
        subtitle: 'Go to the Home tab and describe your work to generate a skills profile.',
      );
    }

    final profile = state.profile!;
    final occ = profile.primaryOccupation;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Occupation card
          if (occ != null) ...[
            OccupationCard(
              displayTitle: occ.displayTitle,
              iscoCode: occ.iscoCode,
              escoTitle: occ.title != occ.iscoTitle ? occ.title : null,
              confidence: occ.confidence,
              score: occ.score,
              matchReason: occ.matchReason,
              sectors: occ.sectors,
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Extraction method badge
          _ExtractionBadge(
            method: profile.confidence.extractionMethod,
            provider: profile.confidence.extractionProvider,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Human summary
          if (profile.humanSummary != null && profile.humanSummary!.isNotEmpty) ...[
            const SectionHeader('Summary'),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(profile.humanSummary!, style: AppTextStyles.body),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ESCO-mapped skills
          if (profile.skills.mapped.isNotEmpty) ...[
            SectionHeader(
              'Mapped Skills',
              subtitle: '${profile.skills.mapped.length} skills matched to ESCO taxonomy',
            ),
            _SkillGrid(
              skills: profile.skills.mapped
                  .map((s) => (s.label, SkillChip.fromString(s.type)))
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Inferred skills
          if (profile.skills.inferred.isNotEmpty) ...[
            SectionHeader(
              'Inferred Skills',
              subtitle: 'Derived from context — review carefully',
            ),
            _SkillGrid(
              skills: profile.skills.inferred
                  .map((s) => (s, SkillType.inferred))
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Local / informal skills
          if (profile.skills.local.isNotEmpty) ...[
            SectionHeader(
              'Local Skills',
              subtitle: 'Recognised in the local informal economy',
            ),
            _SkillGrid(
              skills: profile.skills.local
                  .map((s) => (s, SkillType.local))
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Education
          if (profile.education != null) ...[
            const SectionHeader('Education Level'),
            _DataPill(
              label: profile.education!.label,
              sublabel: 'ISCED ${profile.education!.isced}',
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Country adjustments
          if (profile.confidence.countryAdjustments.isNotEmpty) ...[
            const SectionHeader('Country Adjustments Applied'),
            ...profile.confidence.countryAdjustments.map(
              (adj) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.tune, size: 14, color: AppColors.opportunity),
                    const SizedBox(width: 8),
                    Expanded(child: Text(adj, style: AppTextStyles.body)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Profile ID / share
          _ShareRow(profileId: profile.id),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _SkillGrid extends StatelessWidget {
  const _SkillGrid({required this.skills});
  final List<(String, SkillType)> skills;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: skills
          .map((s) => SkillChip(label: s.$1, type: s.$2))
          .toList(),
    );
  }
}

class _ExtractionBadge extends StatelessWidget {
  const _ExtractionBadge({required this.method, this.provider});
  final String method;
  final String? provider;

  @override
  Widget build(BuildContext context) {
    final isLlm = method == 'llm';
    final label = isLlm
        ? 'AI extraction${provider != null ? " · $provider" : ""}'
        : 'Keyword extraction (heuristic fallback)';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isLlm ? Icons.auto_awesome : Icons.search,
          size: 13,
          color: isLlm ? AppColors.opportunity : AppColors.textMuted,
        ),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.label),
      ],
    );
  }
}

class _DataPill extends StatelessWidget {
  const _DataPill({required this.label, required this.sublabel});
  final String label;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.body),
          const SizedBox(width: 8),
          Text(sublabel, style: AppTextStyles.mono),
        ],
      ),
    );
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({required this.profileId});
  final String profileId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.fingerprint, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Profile ID: $profileId',
            style: AppTextStyles.mono,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 16),
          tooltip: 'Copy profile ID',
          onPressed: () => Clipboard.setData(ClipboardData(text: profileId)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}
