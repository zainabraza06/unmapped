/// Module 3 — Labor Market Opportunity Matching
/// Mirrors the JSON schema produced by services/node-api/lib/opportunity-engine.js

class Module3Analysis {
  final String iscoCode;
  final String occupationTitle;
  final LaborMarketContext laborMarketContext;
  final Opportunities opportunities;
  final List<RankedOpportunity> ranking;
  final PolicyView policyView;
  final List<String> keyDrivers;

  const Module3Analysis({
    required this.iscoCode,
    required this.occupationTitle,
    required this.laborMarketContext,
    required this.opportunities,
    required this.ranking,
    required this.policyView,
    required this.keyDrivers,
  });

  factory Module3Analysis.fromJson(Map<String, dynamic> json) {
    final explainability = json['explainability'] as Map<String, dynamic>? ?? {};
    return Module3Analysis(
      iscoCode: json['isco_code'] ?? '',
      occupationTitle: json['occupation_title'] ?? '',
      laborMarketContext: LaborMarketContext.fromJson(
          json['labor_market_context'] as Map<String, dynamic>? ?? {}),
      opportunities: Opportunities.fromJson(
          json['opportunities'] as Map<String, dynamic>? ?? {}),
      ranking: (json['ranking'] as List<dynamic>? ?? [])
          .map((e) => RankedOpportunity.fromJson(e as Map<String, dynamic>))
          .toList(),
      policyView: PolicyView.fromJson(
          json['policy_view'] as Map<String, dynamic>? ?? {}),
      keyDrivers: (explainability['key_drivers'] as List<dynamic>? ?? []).cast<String>(),
    );
  }
}

class KeyEconomicSignals {
  final EconomicSignal? wageFloor;
  final EconomicSignal? sectorEmploymentShare;
  final EconomicSignal? youthUnemploymentRate;
  final EconomicSignal? neetRate;
  final EconomicSignal? gdpPerCapita;
  final EconomicSignal? selfEmployedShare;
  final EconomicSignal? digitalInfrastructure;

  const KeyEconomicSignals({
    this.wageFloor,
    this.sectorEmploymentShare,
    this.youthUnemploymentRate,
    this.neetRate,
    this.gdpPerCapita,
    this.selfEmployedShare,
    this.digitalInfrastructure,
  });

  factory KeyEconomicSignals.fromJson(Map<String, dynamic> json) => KeyEconomicSignals(
    wageFloor: _sig(json['wage_floor']),
    sectorEmploymentShare: _sig(json['sector_employment_share']),
    youthUnemploymentRate: _sig(json['youth_unemployment_rate']),
    neetRate: _sig(json['neet_rate']),
    gdpPerCapita: _sig(json['gdp_per_capita']),
    selfEmployedShare: _sig(json['self_employed_share']),
    digitalInfrastructure: _sig(json['digital_infrastructure']),
  );

  static EconomicSignal? _sig(dynamic v) {
    if (v == null) return null;
    if (v is String) return EconomicSignal(value: v, source: null);
    if (v is Map<String, dynamic>) return EconomicSignal.fromJson(v);
    return null;
  }

  List<MapEntry<String, EconomicSignal>> get nonNullSignals => [
    if (wageFloor != null) MapEntry('Wage Floor', wageFloor!),
    if (sectorEmploymentShare != null) MapEntry('Sector Employment', sectorEmploymentShare!),
    if (youthUnemploymentRate != null) MapEntry('Youth Unemployment', youthUnemploymentRate!),
    if (neetRate != null) MapEntry('NEET Rate', neetRate!),
    if (gdpPerCapita != null) MapEntry('GDP per Capita', gdpPerCapita!),
    if (selfEmployedShare != null) MapEntry('Self-employed', selfEmployedShare!),
    if (digitalInfrastructure != null) MapEntry('Digital Infrastructure', digitalInfrastructure!),
  ];
}

class EconomicSignal {
  final String value;
  final String? source;
  final String? note;

  const EconomicSignal({required this.value, this.source, this.note});

  factory EconomicSignal.fromJson(Map<String, dynamic> json) => EconomicSignal(
    value: json['value']?.toString() ?? json['formatted']?.toString() ?? '',
    source: json['source'],
    note: json['note'],
  );
}

class LaborMarketContext {
  final String country;
  final String informalityLevel;
  final KeyEconomicSignals keyEconomicSignals;

  const LaborMarketContext({
    required this.country,
    required this.informalityLevel,
    required this.keyEconomicSignals,
  });

  factory LaborMarketContext.fromJson(Map<String, dynamic> json) => LaborMarketContext(
    country: json['country'] ?? '',
    informalityLevel: json['informality_level'] ?? '',
    keyEconomicSignals: KeyEconomicSignals.fromJson(
        json['key_economic_signals'] as Map<String, dynamic>? ?? {}),
  );
}

class DirectOpportunity {
  final String title;
  final String iscoCode;
  final String incomeRange;
  final String demandStrength;
  final String entryBarrier;
  final String stability;
  final String reason;

  const DirectOpportunity({
    required this.title,
    required this.iscoCode,
    required this.incomeRange,
    required this.demandStrength,
    required this.entryBarrier,
    required this.stability,
    required this.reason,
  });

  factory DirectOpportunity.fromJson(Map<String, dynamic> json) => DirectOpportunity(
    title: json['title'] ?? '',
    iscoCode: json['isco_code'] ?? '',
    incomeRange: json['income_range'] ?? '',
    demandStrength: json['demand_strength'] ?? '',
    entryBarrier: json['entry_barrier'] ?? '',
    stability: json['stability'] ?? '',
    reason: json['reason'] ?? '',
  );
}

class AdjacentOpportunity {
  final String title;
  final String iscoCode;
  final String incomeRange;
  final String demandStrength;
  final String entryBarrier;
  final String stability;
  final List<String> requiredUpskilling;
  final String reason;

  const AdjacentOpportunity({
    required this.title,
    required this.iscoCode,
    required this.incomeRange,
    required this.demandStrength,
    required this.entryBarrier,
    required this.stability,
    required this.requiredUpskilling,
    required this.reason,
  });

  factory AdjacentOpportunity.fromJson(Map<String, dynamic> json) => AdjacentOpportunity(
    title: json['title'] ?? '',
    iscoCode: json['isco_code'] ?? '',
    incomeRange: json['income_range'] ?? '',
    demandStrength: json['demand_strength'] ?? '',
    entryBarrier: json['entry_barrier'] ?? '',
    stability: json['stability'] ?? '',
    requiredUpskilling:
        (json['required_upskilling'] as List<dynamic>? ?? []).cast<String>(),
    reason: json['reason'] ?? '',
  );
}

class MicroEnterpriseOpportunity {
  final String title;
  final String incomeRange;
  final String entryBarrier;
  final String stability;
  final String reason;

  const MicroEnterpriseOpportunity({
    required this.title,
    required this.incomeRange,
    required this.entryBarrier,
    required this.stability,
    required this.reason,
  });

  factory MicroEnterpriseOpportunity.fromJson(Map<String, dynamic> json) =>
      MicroEnterpriseOpportunity(
        title: json['title'] ?? '',
        incomeRange: json['income_range'] ?? '',
        entryBarrier: json['entry_barrier'] ?? '',
        stability: json['stability'] ?? '',
        reason: json['reason'] ?? '',
      );
}

class Opportunities {
  final List<DirectOpportunity> direct;
  final List<AdjacentOpportunity> adjacent;
  final List<MicroEnterpriseOpportunity> microEnterprise;

  const Opportunities({
    required this.direct,
    required this.adjacent,
    required this.microEnterprise,
  });

  factory Opportunities.fromJson(Map<String, dynamic> json) => Opportunities(
    direct: (json['direct'] as List<dynamic>? ?? [])
        .map((e) => DirectOpportunity.fromJson(e as Map<String, dynamic>))
        .toList(),
    adjacent: (json['adjacent'] as List<dynamic>? ?? [])
        .map((e) => AdjacentOpportunity.fromJson(e as Map<String, dynamic>))
        .toList(),
    microEnterprise: (json['micro_enterprise'] as List<dynamic>? ?? [])
        .map((e) => MicroEnterpriseOpportunity.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class RankedOpportunity {
  final String opportunity;
  final double score;
  final String reason;

  const RankedOpportunity({
    required this.opportunity,
    required this.score,
    required this.reason,
  });

  factory RankedOpportunity.fromJson(Map<String, dynamic> json) => RankedOpportunity(
    opportunity: json['opportunity'] ?? '',
    score: (json['score'] ?? 0.0).toDouble(),
    reason: json['reason'] ?? '',
  );
}

class PolicyView {
  final String laborGapIdentified;
  final String sectorShortageSignal;
  final String recommendationForGovernmentOrNgos;

  const PolicyView({
    required this.laborGapIdentified,
    required this.sectorShortageSignal,
    required this.recommendationForGovernmentOrNgos,
  });

  factory PolicyView.fromJson(Map<String, dynamic> json) => PolicyView(
    laborGapIdentified: json['labor_gap_identified'] ?? '',
    sectorShortageSignal: json['sector_shortage_signal'] ?? '',
    recommendationForGovernmentOrNgos:
        json['recommendation_for_government_or_ngos'] ?? '',
  );
}
