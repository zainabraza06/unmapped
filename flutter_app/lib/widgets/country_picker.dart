import 'package:flutter/material.dart';

import '../core/models/country_list.dart';
import '../core/theme/app_theme.dart';

/// Shows a full-screen searchable country picker dialog.
/// Returns the selected [Country] or null if dismissed.
Future<Country?> showCountryPicker(BuildContext context, String currentCode) {
  return showDialog<Country>(
    context: context,
    builder: (_) => _CountryPickerDialog(currentCode: currentCode),
  );
}

class _CountryPickerDialog extends StatefulWidget {
  const _CountryPickerDialog({required this.currentCode});
  final String currentCode;

  @override
  State<_CountryPickerDialog> createState() => _CountryPickerDialogState();
}

class _CountryPickerDialogState extends State<_CountryPickerDialog> {
  final _searchController = TextEditingController();
  List<Country> _filtered = kAllCountries;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? kAllCountries
          : kAllCountries
              .where((c) =>
                  c.name.toLowerCase().contains(q) ||
                  c.code.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Select Country'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search country…',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: _filtered.isEmpty
            ? Center(
                child: Text('No country found', style: AppTextStyles.body),
              )
            : ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final country = _filtered[i];
                  final isSelected = country.code == widget.currentCode;
                  return ListTile(
                    dense: true,
                    leading: Text(
                      country.flag,
                      style: const TextStyle(fontSize: 22),
                    ),
                    title: Text(country.name, style: AppTextStyles.body),
                    trailing: Text(
                      country.code,
                      style: AppTextStyles.mono.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.textMuted,
                      ),
                    ),
                    tileColor: isSelected
                        ? AppColors.primary.withValues(alpha: 0.06)
                        : null,
                    onTap: () => Navigator.of(context).pop(country),
                  );
                },
              ),
      ),
    );
  }
}

/// Compact button displayed in the AppBar that shows the current country
/// and opens the picker on tap.
class CountryPickerButton extends StatelessWidget {
  const CountryPickerButton({
    super.key,
    required this.countryCode,
    required this.onChanged,
  });

  final String countryCode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final country = countryByCode(countryCode);
    final flag = country?.flag ?? '🌍';
    final code = country?.code ?? countryCode;

    return GestureDetector(
      onTap: () async {
        final selected = await showCountryPicker(context, countryCode);
        if (selected != null) onChanged(selected.code);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.background,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 5),
            Text(code, style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
            const SizedBox(width: 3),
            const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
