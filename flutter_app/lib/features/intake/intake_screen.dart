import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/intake_model.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared.dart';

class IntakeScreen extends StatefulWidget {
  const IntakeScreen({super.key});

  @override
  State<IntakeScreen> createState() => _IntakeScreenState();
}

class _IntakeScreenState extends State<IntakeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();

  String? _educationLevel;
  String? _preferredSector;
  final Set<String> _selectedSkills = {};
  final Set<String> _selectedLanguages = {};
  double _experienceYears = 1;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isLoading = state.loadingM1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero header
            _IntakeHeader(countryName: state.countryName),
            const SizedBox(height: AppSpacing.lg),

            // Free text input
            _buildLabel('Describe your work'),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _textController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'e.g. "I repair mobile phones, replace screens and batteries, '
                    'and run a small shop in the market..."',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 10) ? 'Please describe your work in more detail.' : null,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Education level
            _buildLabel('Education level'),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              value: _educationLevel,
              decoration: const InputDecoration(hintText: 'Select your highest level'),
              items: kEducationLevels
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: AppTextStyles.body)))
                  .toList(),
              onChanged: (v) => setState(() => _educationLevel = v),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Experience slider
            _buildLabel('Years of experience: ${_experienceYears.round()}'),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.border,
                thumbColor: AppColors.primary,
              ),
              child: Slider(
                value: _experienceYears,
                min: 0,
                max: 20,
                divisions: 20,
                label: '${_experienceYears.round()} yrs',
                onChanged: (v) => setState(() => _experienceYears = v),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Preferred sector
            _buildLabel('Sector (optional)'),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              value: _preferredSector,
              decoration: const InputDecoration(hintText: 'e.g. Construction & Trades'),
              items: kSectorOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s, style: AppTextStyles.body)))
                  .toList(),
              onChanged: (v) => setState(() => _preferredSector = v),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Informal skills checkboxes
            _buildLabel('Skills you use (select all that apply)'),
            const SizedBox(height: AppSpacing.sm),
            _SkillCheckboxGrid(
              options: kInformalSkillOptions,
              selected: _selectedSkills,
              onToggle: (s) => setState(() =>
                  _selectedSkills.contains(s) ? _selectedSkills.remove(s) : _selectedSkills.add(s)),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Languages
            _buildLabel('Languages spoken'),
            const SizedBox(height: AppSpacing.sm),
            _LanguageSelect(
              options: kLanguageOptions,
              selected: _selectedLanguages,
              onToggle: (l) => setState(() =>
                  _selectedLanguages.contains(l) ? _selectedLanguages.remove(l) : _selectedLanguages.add(l)),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Error from M1
            if (state.errorM1 != null) ...[
              ErrorCard(
                message: state.errorM1!,
                onRetry: _submit,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Generate Skills Profile'),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final intake = IntakeModel(
      freeText: _textController.text.trim(),
      countryCode: context.read<AppState>().countryCode,
      educationLevel: _educationLevel,
      informalSkills: _selectedSkills.toList(),
      languages: _selectedLanguages.toList(),
      experienceYears: _experienceYears.round(),
      preferredSector: _preferredSector,
    );
    final state = context.read<AppState>();
    await state.generateProfile(intake);
    // Auto-chain M2 and M3 after successful M1
    if (state.hasProfile && mounted) {
      await state.analyseRisk();
      if (state.hasRisk && mounted) {
        await state.matchOpportunities();
      }
    }
  }

  Widget _buildLabel(String text) => Text(text, style: AppTextStyles.title);
}

class _IntakeHeader extends StatelessWidget {
  const _IntakeHeader({required this.countryName});
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
            'Build your Skills Profile',
            style: AppTextStyles.displaySmall.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Tell us about the work you do in $countryName. '
            'We will map it to internationally recognised occupations.',
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillCheckboxGrid extends StatelessWidget {
  const _SkillCheckboxGrid({
    required this.options,
    required this.selected,
    required this.onToggle,
  });
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: options.map((skill) {
        final isSelected = selected.contains(skill);
        return FilterChip(
          label: Text(skill, style: AppTextStyles.caption),
          selected: isSelected,
          onSelected: (_) => onToggle(skill),
          selectedColor: AppColors.primary.withValues(alpha: 0.1),
          checkmarkColor: AppColors.primary,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          showCheckmark: true,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
      }).toList(),
    );
  }
}

class _LanguageSelect extends StatelessWidget {
  const _LanguageSelect({
    required this.options,
    required this.selected,
    required this.onToggle,
  });
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: options.map((lang) {
        final isSelected = selected.contains(lang);
        return ChoiceChip(
          label: Text(lang, style: AppTextStyles.caption),
          selected: isSelected,
          onSelected: (_) => onToggle(lang),
          selectedColor: AppColors.opportunityLight,
          side: BorderSide(
            color: isSelected ? AppColors.opportunity : AppColors.border,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          showCheckmark: false,
        );
      }).toList(),
    );
  }
}
