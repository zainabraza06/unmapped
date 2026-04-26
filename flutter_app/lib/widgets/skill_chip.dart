import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

enum SkillType { knowledge, skill, tool, language, local, inferred }

class SkillChip extends StatelessWidget {
  const SkillChip({
    super.key,
    required this.label,
    this.type = SkillType.skill,
    this.small = false,
  });

  final String label;
  final SkillType type;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(type);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.$2),
      ),
      child: Text(
        label,
        style: (small ? AppTextStyles.label : AppTextStyles.caption).copyWith(
          color: colors.$3,
        ),
      ),
    );
  }

  static (Color bg, Color border, Color text) _colorsFor(SkillType type) =>
      switch (type) {
        SkillType.knowledge  => (AppColors.opportunityLight, AppColors.opportunity.withValues(alpha: 0.3), AppColors.opportunity),
        SkillType.skill      => (AppColors.stableLight,      AppColors.stable.withValues(alpha: 0.3),      AppColors.stable),
        SkillType.tool       => (AppColors.warningLight,     AppColors.warning.withValues(alpha: 0.3),     AppColors.warning),
        SkillType.language   => (const Color(0xFFEDE9FE),    const Color(0xFFDDD6FE),                      const Color(0xFF7C3AED)),
        SkillType.local      => (AppColors.neutralLight,     AppColors.border,                             AppColors.neutral),
        SkillType.inferred   => (AppColors.neutralLight,     AppColors.border,                             AppColors.textMuted),
      };

  static SkillType fromString(String? s) => switch (s?.toLowerCase()) {
    'knowledge'  => SkillType.knowledge,
    'skill'      => SkillType.skill,
    'tool'       => SkillType.tool,
    'language'   => SkillType.language,
    'local'      => SkillType.local,
    'inferred'   => SkillType.inferred,
    _            => SkillType.skill,
  };
}
