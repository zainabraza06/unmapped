import 'package:flutter/foundation.dart';

import '../api/api_service.dart';
import '../models/country_list.dart';
import '../models/intake_model.dart';
import '../models/module1_profile.dart';
import '../models/module2_analysis.dart';
import '../models/module3_analysis.dart';

/// Central application state — provided at the root widget.
/// Manages country selection, intake data, and all three module results.
class AppState extends ChangeNotifier {
  final ApiService _api = const ApiService();

  // ─── Country ───────────────────────────────────────────────────────────────
  String _countryCode = 'GH';
  String get countryCode => _countryCode;

  void switchCountry(String code) {
    if (_countryCode == code) return;
    _countryCode = code;
    // Reset all module outputs when country changes; intake form is preserved.
    _clearResults();
    notifyListeners();
  }

  // ─── Intake ────────────────────────────────────────────────────────────────
  IntakeModel? _lastIntake;
  IntakeModel? get lastIntake => _lastIntake;

  // ─── Module 1 ──────────────────────────────────────────────────────────────
  Module1Profile? _profile;
  bool _loadingM1 = false;
  String? _errorM1;

  Module1Profile? get profile       => _profile;
  bool           get loadingM1      => _loadingM1;
  String?        get errorM1        => _errorM1;
  bool           get hasProfile     => _profile != null;

  Future<void> generateProfile(IntakeModel intake) async {
    _lastIntake = intake;
    _loadingM1 = true;
    _errorM1 = null;
    _profile = null;
    // Clear downstream results when re-generating
    _risk = null;
    _opportunities = null;
    _errorM2 = null;
    _errorM3 = null;
    notifyListeners();

    try {
      _profile = await _api.generateProfile(intake);
    } on ApiException catch (e) {
      _errorM1 = e.message;
    } catch (e) {
      _errorM1 = 'Unexpected error: $e';
    } finally {
      _loadingM1 = false;
      notifyListeners();
    }
  }

  // ─── Module 2 ──────────────────────────────────────────────────────────────
  Module2Analysis? _risk;
  bool _loadingM2 = false;
  String? _errorM2;

  Module2Analysis? get risk         => _risk;
  bool             get loadingM2    => _loadingM2;
  String?          get errorM2      => _errorM2;
  bool             get hasRisk      => _risk != null;

  Future<void> analyseRisk() async {
    if (_profile == null) {
      _errorM2 = 'Generate a skills profile first.';
      notifyListeners();
      return;
    }
    _loadingM2 = true;
    _errorM2 = null;
    _risk = null;
    _opportunities = null;
    _errorM3 = null;
    notifyListeners();

    try {
      _risk = await _api.getRiskAnalysis(
        profile: _profile!,
        countryCode: _countryCode,
      );
    } on ApiException catch (e) {
      _errorM2 = e.message;
    } catch (e) {
      _errorM2 = 'Unexpected error: $e';
    } finally {
      _loadingM2 = false;
      notifyListeners();
    }
  }

  // ─── Module 3 ──────────────────────────────────────────────────────────────
  Module3Analysis? _opportunities;
  bool _loadingM3 = false;
  String? _errorM3;

  Module3Analysis? get opportunities  => _opportunities;
  bool             get loadingM3      => _loadingM3;
  String?          get errorM3        => _errorM3;
  bool             get hasOpportunities => _opportunities != null;

  Future<void> matchOpportunities() async {
    if (_profile == null) {
      _errorM3 = 'Generate a skills profile first.';
      notifyListeners();
      return;
    }
    _loadingM3 = true;
    _errorM3 = null;
    _opportunities = null;
    notifyListeners();

    try {
      _opportunities = await _api.matchOpportunities(
        profile: _profile!,
        module2: _risk,
        countryCode: _countryCode,
      );
    } on ApiException catch (e) {
      _errorM3 = e.message;
    } catch (e) {
      _errorM3 = 'Unexpected error: $e';
    } finally {
      _loadingM3 = false;
      notifyListeners();
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _clearResults() {
    _profile = null;
    _risk = null;
    _opportunities = null;
    _errorM1 = null;
    _errorM2 = null;
    _errorM3 = null;
    _loadingM1 = false;
    _loadingM2 = false;
    _loadingM3 = false;
  }

  /// Reload all completed modules after a country switch.
  /// Runs M1 → M2 → M3 sequentially only if the previous step succeeded.
  Future<void> rerunAll() async {
    if (_lastIntake == null) return;
    await generateProfile(_lastIntake!.copyWith(countryCode: _countryCode));
    if (_profile != null) {
      await analyseRisk();
    }
    if (_risk != null) {
      await matchOpportunities();
    }
  }

  /// Human-readable name of the selected country, resolved from the full ISO list.
  String get countryName => countryByCode(_countryCode)?.name ?? _countryCode;
}

extension on IntakeModel {
  IntakeModel copyWith({String? countryCode}) => IntakeModel(
    freeText: freeText,
    countryCode: countryCode ?? this.countryCode,
    educationLevel: educationLevel,
    informalSkills: informalSkills,
    languages: languages,
    experienceYears: experienceYears,
    preferredSector: preferredSector,
  );
}
