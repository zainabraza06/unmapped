import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/state/app_state.dart';
import 'widgets/country_picker.dart';
import 'features/intake/intake_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/risk/risk_screen.dart';
import 'features/opportunities/opportunities_screen.dart';
import 'features/insights/insights_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Force portrait orientation on low-end devices
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const UnmappedApp(),
    ),
  );
}

class UnmappedApp extends StatelessWidget {
  const UnmappedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UNMAPPED',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const MainShell(),
    );
  }
}

/// Main scaffold with bottom navigation bar and shared AppBar country switcher.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_outlined,       activeIcon: Icons.home,           label: 'Home'),
    _NavItem(icon: Icons.badge_outlined,      activeIcon: Icons.badge,          label: 'Profile'),
    _NavItem(icon: Icons.show_chart_outlined, activeIcon: Icons.show_chart,     label: 'Risk'),
    _NavItem(icon: Icons.work_outline,        activeIcon: Icons.work,           label: 'Jobs'),
    _NavItem(icon: Icons.bar_chart_outlined,  activeIcon: Icons.bar_chart,      label: 'Insights'),
  ];

  static const List<Widget> _screens = [
    IntakeScreen(),
    ProfileScreen(),
    RiskScreen(),
    OpportunitiesScreen(),
    InsightsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('UNMAPPED', style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              letterSpacing: 0.5,
            )),
            const Spacer(),
            CountryPickerButton(
              countryCode: state.countryCode,
              onChanged: state.switchCountry,
            ),
          ],
        ),
        bottom: _buildProgressIndicator(state),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          destinations: _navItems
              .map((item) => NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.activeIcon),
                    label: item.label,
                  ))
              .toList(),
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildProgressIndicator(AppState state) {
    final steps = [
      ('M01', 'Skills', state.hasProfile),
      ('M02', 'Risk', state.hasRisk),
      ('M03', 'Jobs', state.hasOpportunities),
    ];
    return PreferredSize(
      preferredSize: const Size.fromHeight(36),
      child: Container(
        height: 36,
        color: AppColors.background,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (int i = 0; i < steps.length; i++) ...[
              _StepBadge(code: steps[i].$1, label: steps[i].$2, done: steps[i].$3),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: steps[i].$3 ? AppColors.stable : AppColors.border,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.code, required this.label, required this.done});
  final String code;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18, height: 18,
          decoration: BoxDecoration(
            color: done ? AppColors.stable : AppColors.border,
            shape: BoxShape.circle,
          ),
          child: Icon(
            done ? Icons.check : Icons.circle,
            size: 10,
            color: done ? Colors.white : AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 4),
        Text('$code $label', style: AppTextStyles.label.copyWith(
          color: done ? AppColors.stable : AppColors.textMuted,
        )),
      ],
    );
  }
}


class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
