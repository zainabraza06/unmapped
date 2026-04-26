/// Module 2 — AI Automation Risk Analysis
/// Mirrors the JSON schema produced by services/node-api/lib/risk-engine.js

class Module2Analysis {
  final String iscoCode;
  final String occupationTitle;
  final AutomationAnalysis automationAnalysis;
  final TaskBreakdown taskBreakdown;
  final SkillResilienceAnalysis skillResilienceAnalysis;
  final EconomicContext economicContext;
  final MacroSignals macroSignals;
  final FinalReadinessProfile finalReadinessProfile;
  final List<String> keyDrivers;
  final AnalysisMeta? meta;

  const Module2Analysis({
    required this.iscoCode,
    required this.occupationTitle,
    required this.automationAnalysis,
    required this.taskBreakdown,
    required this.skillResilienceAnalysis,
    required this.economicContext,
    required this.macroSignals,
    required this.finalReadinessProfile,
    required this.keyDrivers,
    this.meta,
  });

  factory Module2Analysis.fromJson(Map<String, dynamic> json) {
    final explainability = json['explainability'] as Map<String, dynamic>? ?? {};
    return Module2Analysis(
      iscoCode: json['isco_code'] ?? '',
      occupationTitle: json['occupation_title'] ?? '',
      automationAnalysis: AutomationAnalysis.fromJson(
          json['automation_analysis'] as Map<String, dynamic>? ?? {}),
      taskBreakdown: TaskBreakdown.fromJson(
          json['task_breakdown'] as Map<String, dynamic>? ?? {}),
      skillResilienceAnalysis: SkillResilienceAnalysis.fromJson(
          json['skill_resilience_analysis'] as Map<String, dynamic>? ?? {}),
      economicContext: EconomicContext.fromJson(
          json['economic_context'] as Map<String, dynamic>? ?? {}),
      macroSignals: MacroSignals.fromJson(
          json['macro_signals'] as Map<String, dynamic>? ?? {}),
      finalReadinessProfile: FinalReadinessProfile.fromJson(
          json['final_readiness_profile'] as Map<String, dynamic>? ?? {}),
      keyDrivers: (explainability['key_drivers'] as List<dynamic>? ?? []).cast<String>(),
      meta: json['_meta'] != null
          ? AnalysisMeta.fromJson(json['_meta'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AutomationAnalysis {
  final String sourceModel;
  final double? baseAutomationProbability;
  final String baseSource;
  final double adjustmentFactor;
  final double? adjustedAutomationProbability;
  final List<String> lmicAdjustmentExplanation;
  final List<String> sources;
  final double? uncertaintyBand;

  const AutomationAnalysis({
    required this.sourceModel,
    this.baseAutomationProbability,
    required this.baseSource,
    required this.adjustmentFactor,
    this.adjustedAutomationProbability,
    required this.lmicAdjustmentExplanation,
    required this.sources,
    this.uncertaintyBand,
  });

  factory AutomationAnalysis.fromJson(Map<String, dynamic> json) =>
      AutomationAnalysis(
        sourceModel: json['source_model'] ?? '',
        baseAutomationProbability: json['base_automation_probability'] != null
            ? (json['base_automation_probability'] as num).toDouble()
            : null,
        baseSource: json['base_source'] ?? '',
        adjustmentFactor: (json['adjustment_factor'] ?? 1.0).toDouble(),
        adjustedAutomationProbability: json['adjusted_automation_probability'] != null
            ? (json['adjusted_automation_probability'] as num).toDouble()
            : null,
        lmicAdjustmentExplanation:
            (json['lmic_adjustment_explanation'] as List<dynamic>? ?? []).cast<String>(),
        sources: (json['sources'] as List<dynamic>? ?? []).cast<String>(),
        uncertaintyBand: json['uncertainty_band'] != null
            ? (json['uncertainty_band'] as num).toDouble()
            : null,
      );
}

class RatedTask {
  final String task;
  final double riskScore;

  const RatedTask({required this.task, required this.riskScore});

  factory RatedTask.fromJson(Map<String, dynamic> json) => RatedTask(
    task: json['task'] ?? '',
    riskScore: (json['risk_score'] ?? 0.0).toDouble(),
  );
}

class TaskBreakdown {
  final List<RatedTask> highRiskTasks;
  final List<RatedTask> lowRiskTasks;

  const TaskBreakdown({required this.highRiskTasks, required this.lowRiskTasks});

  factory TaskBreakdown.fromJson(Map<String, dynamic> json) => TaskBreakdown(
    highRiskTasks: (json['high_risk_tasks'] as List<dynamic>? ?? [])
        .map((e) => RatedTask.fromJson(e as Map<String, dynamic>))
        .toList(),
    lowRiskTasks: (json['low_risk_tasks'] as List<dynamic>? ?? [])
        .map((e) => RatedTask.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class SkillResilienceAnalysis {
  final List<String> atRiskSkills;
  final List<String> durableSkills;
  final List<String> adjacentSkills;

  const SkillResilienceAnalysis({
    required this.atRiskSkills,
    required this.durableSkills,
    required this.adjacentSkills,
  });

  factory SkillResilienceAnalysis.fromJson(Map<String, dynamic> json) =>
      SkillResilienceAnalysis(
        atRiskSkills: (json['at_risk_skills'] as List<dynamic>? ?? []).cast<String>(),
        durableSkills: (json['durable_skills'] as List<dynamic>? ?? []).cast<String>(),
        adjacentSkills: (json['adjacent_skills'] as List<dynamic>? ?? []).cast<String>(),
      );
}

class EconomicContext {
  final String country;
  final String informalityLevel;
  final String interpretation;

  const EconomicContext({
    required this.country,
    required this.informalityLevel,
    required this.interpretation,
  });

  factory EconomicContext.fromJson(Map<String, dynamic> json) => EconomicContext(
    country: json['country'] ?? '',
    informalityLevel: json['informality_level'] ?? '',
    interpretation: json['interpretation'] ?? '',
  );
}

class MacroSignals {
  final String educationProjection;
  final String laborShiftTrend;

  const MacroSignals({required this.educationProjection, required this.laborShiftTrend});

  factory MacroSignals.fromJson(Map<String, dynamic> json) => MacroSignals(
    educationProjection: json['education_projection'] ?? '',
    laborShiftTrend: json['labor_shift_trend'] ?? '',
  );
}

enum RiskLevel { low, medium, high, veryHigh }
enum ResilienceLevel { low, medium, high }
enum OpportunityType { displacement, stable, upskillingRequired, growthArea }

class FinalReadinessProfile {
  final RiskLevel riskLevel;
  final ResilienceLevel resilienceLevel;
  final OpportunityType opportunityType;
  final String summary;

  const FinalReadinessProfile({
    required this.riskLevel,
    required this.resilienceLevel,
    required this.opportunityType,
    required this.summary,
  });

  factory FinalReadinessProfile.fromJson(Map<String, dynamic> json) {
    return FinalReadinessProfile(
      riskLevel: _parseRiskLevel(json['risk_level']),
      resilienceLevel: _parseResilienceLevel(json['resilience_level']),
      opportunityType: _parseOpportunityType(json['opportunity_type']),
      summary: json['summary'] ?? '',
    );
  }

  static RiskLevel _parseRiskLevel(String? s) => switch (s) {
    'low'       => RiskLevel.low,
    'medium'    => RiskLevel.medium,
    'high'      => RiskLevel.high,
    'very high' => RiskLevel.veryHigh,
    _           => RiskLevel.medium,
  };

  static ResilienceLevel _parseResilienceLevel(String? s) => switch (s) {
    'low'    => ResilienceLevel.low,
    'medium' => ResilienceLevel.medium,
    'high'   => ResilienceLevel.high,
    _        => ResilienceLevel.medium,
  };

  static OpportunityType _parseOpportunityType(String? s) => switch (s) {
    'displacement'        => OpportunityType.displacement,
    'stable'              => OpportunityType.stable,
    'upskilling_required' => OpportunityType.upskillingRequired,
    'growth_area'         => OpportunityType.growthArea,
    _                     => OpportunityType.stable,
  };
}

class AnalysisMeta {
  final String analysisProvider;
  final String profileId;
  final String generatedAt;

  const AnalysisMeta({
    required this.analysisProvider,
    required this.profileId,
    required this.generatedAt,
  });

  factory AnalysisMeta.fromJson(Map<String, dynamic> json) => AnalysisMeta(
    analysisProvider: json['analysis_provider'] ?? '',
    profileId: json['profile_id'] ?? '',
    generatedAt: json['generated_at'] ?? '',
  );
}
