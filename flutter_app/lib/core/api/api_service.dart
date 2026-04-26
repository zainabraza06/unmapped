import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/intake_model.dart';
import '../models/module1_profile.dart';
import '../models/module2_analysis.dart';
import '../models/module3_analysis.dart';

/// API base URL — change this for production deployment.
/// For Android emulator connecting to a host machine, use 10.0.2.2
/// For real devices on local network, use the host machine's LAN IP.
const String _kBaseUrl = 'http://10.0.2.2:4000';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => statusCode != null
      ? 'ApiException [$statusCode]: $message'
      : 'ApiException: $message';
}

class ApiService {
  final String baseUrl;
  final Duration timeout;

  const ApiService({
    this.baseUrl = _kBaseUrl,
    this.timeout = const Duration(seconds: 90),
  });

  // ─── Module 1 ──────────────────────────────────────────────────────────────

  Future<Module1Profile> generateProfile(IntakeModel intake) async {
    final body = jsonEncode(intake.toJson());
    final response = await _post('/api/module1/profile', body);
    final data = _parseResponse(response);
    return Module1Profile.fromJson(data['profile'] as Map<String, dynamic>);
  }

  // ─── Module 2 ──────────────────────────────────────────────────────────────

  Future<Module2Analysis> getRiskAnalysis({
    required Module1Profile profile,
    required String countryCode,
  }) async {
    final body = jsonEncode({
      'profile': _profileToJson(profile),
      'country_code': countryCode,
    });
    final response = await _post('/api/module2/risk-analysis', body);
    final data = _parseResponse(response);
    return Module2Analysis.fromJson(data['analysis'] as Map<String, dynamic>);
  }

  // ─── Module 3 ──────────────────────────────────────────────────────────────

  Future<Module3Analysis> matchOpportunities({
    required Module1Profile profile,
    Module2Analysis? module2,
    required String countryCode,
  }) async {
    final body = jsonEncode({
      'profile': _profileToJson(profile),
      if (module2 != null) 'module2': _module2ToJson(module2),
      'country_code': countryCode,
    });
    final response = await _post('/api/module3/opportunities', body);
    final data = _parseResponse(response);
    return Module3Analysis.fromJson(data['opportunities'] as Map<String, dynamic>);
  }

  // ─── Health check ──────────────────────────────────────────────────────────

  Future<bool> isHealthy() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── Internals ─────────────────────────────────────────────────────────────

  Future<http.Response> _post(String path, String body) async {
    try {
      return await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(timeout);
    } on Exception catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Invalid JSON from server', statusCode: response.statusCode);
    }
    if (response.statusCode >= 400) {
      final msg = data['error']?.toString() ?? 'Request failed';
      throw ApiException(msg, statusCode: response.statusCode);
    }
    return data;
  }

  /// Minimal profile JSON for module 2 / 3 requests.
  /// We pass the full profile but only the fields the backend needs.
  Map<String, dynamic> _profileToJson(Module1Profile profile) => {
    'id': profile.id,
    'generated_at': profile.generatedAt,
    'human_summary': profile.humanSummary,
    'primary_occupation': profile.primaryOccupation == null ? null : {
      'title': profile.primaryOccupation!.title,
      'isco_code': profile.primaryOccupation!.iscoCode,
      'isco_title': profile.primaryOccupation!.iscoTitle,
      'confidence': profile.primaryOccupation!.confidence,
      'score': profile.primaryOccupation!.score,
      'sectors': profile.primaryOccupation!.sectors,
    },
    'skills': {
      'mapped': profile.skills.mapped.map((s) => {
        'label': s.label,
        'type': s.type,
      }).toList(),
      'inferred': profile.skills.inferred,
      'local': profile.skills.local,
    },
    'confidence': {
      'overall': profile.confidence.overall,
      'score': profile.confidence.score,
      'extraction_method': profile.confidence.extractionMethod,
    },
  };

  Map<String, dynamic> _module2ToJson(Module2Analysis m2) => {
    'isco_code': m2.iscoCode,
    'occupation_title': m2.occupationTitle,
    'skill_resilience_analysis': {
      'at_risk_skills': m2.skillResilienceAnalysis.atRiskSkills,
      'durable_skills': m2.skillResilienceAnalysis.durableSkills,
      'adjacent_skills': m2.skillResilienceAnalysis.adjacentSkills,
    },
    'final_readiness_profile': {
      'risk_level': m2.finalReadinessProfile.riskLevel.name,
    },
    'economic_context': {
      'country': m2.economicContext.country,
      'informality_level': m2.economicContext.informalityLevel,
    },
  };
}
