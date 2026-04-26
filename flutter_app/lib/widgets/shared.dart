/// Shared small widgets used across multiple screens.
library;

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Bold section divider with label.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headline),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(subtitle!, style: AppTextStyles.caption),
            ),
        ],
      ),
    );
  }
}

/// Full-width loading placeholder card.
class LoadingCard extends StatelessWidget {
  const LoadingCard({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 28, width: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 12),
            Text(message, style: AppTextStyles.body, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Error state card with retry button.
class ErrorCard extends StatelessWidget {
  const ErrorCard({
    super.key,
    required this.message,
    this.onRetry,
  });
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.risk, size: 18),
                const SizedBox(width: 8),
                const Text('Error', style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.risk,
                )),
              ],
            ),
            const SizedBox(height: 8),
            Text(message, style: AppTextStyles.body),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text('Retry'),
                  onPressed: onRetry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state — shown when module has no data yet.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.headline, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: AppTextStyles.body, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Thin horizontal divider with optional label.
class LabelDivider extends StatelessWidget {
  const LabelDivider(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label, style: AppTextStyles.label),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

/// Inline key-value row for simple data display.
class DataRow extends StatelessWidget {
  const DataRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: AppTextStyles.caption),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }
}

/// Inline risk level badge (colored pill).
class RiskLevelBadge extends StatelessWidget {
  const RiskLevelBadge(this.level, {super.key});
  final String level; // 'low' | 'medium' | 'high' | 'very high'

  @override
  Widget build(BuildContext context) {
    final (bg, text) = switch (level.toLowerCase()) {
      'low'       => (AppColors.stableLight,  AppColors.stable),
      'medium'    => (AppColors.warningLight, AppColors.warning),
      'high'      => (AppColors.riskLight,    AppColors.risk),
      'very high' => (AppColors.riskLight,    AppColors.risk),
      _           => (AppColors.neutralLight, AppColors.neutral),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        level.toUpperCase(),
        style: AppTextStyles.label.copyWith(color: text),
      ),
    );
  }
}
