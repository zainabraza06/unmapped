/// Module 1 — Skills Profile
/// Mirrors the JSON schema produced by services/node-api/lib/profile.js

class Module1Profile {
  final String id;
  final String generatedAt;
  final String? humanSummary;
  final PrimaryOccupation? primaryOccupation;
  final ProfileEducation? education;
  final ProfileSkills skills;
  final ProfileConfidence confidence;

  const Module1Profile({
    required this.id,
    required this.generatedAt,
    this.humanSummary,
    this.primaryOccupation,
    this.education,
    required this.skills,
    required this.confidence,
  });

  factory Module1Profile.fromJson(Map<String, dynamic> json) {
    return Module1Profile(
      id: json['id'] ?? '',
      generatedAt: json['generated_at'] ?? '',
      humanSummary: json['human_summary'],
      primaryOccupation: json['primary_occupation'] != null
          ? PrimaryOccupation.fromJson(json['primary_occupation'])
          : null,
      education: json['education'] != null
          ? ProfileEducation.fromJson(json['education'])
          : null,
      skills: json['skills'] != null
          ? ProfileSkills.fromJson(json['skills'])
          : const ProfileSkills(mapped: [], inferred: [], local: []),
      confidence: json['confidence'] != null
          ? ProfileConfidence.fromJson(json['confidence'])
          : const ProfileConfidence(overall: 'low', score: 0.0, extractionMethod: 'heuristic'),
    );
  }
}

class PrimaryOccupation {
  final String title;
  final String iscoCode;
  final String? iscoTitle;
  final String? escoCode;
  final String confidence;
  final double score;
  final String? matchReason;
  final List<String> sectors;

  const PrimaryOccupation({
    required this.title,
    required this.iscoCode,
    this.iscoTitle,
    this.escoCode,
    required this.confidence,
    required this.score,
    this.matchReason,
    this.sectors = const [],
  });

  /// The label shown prominently in the UI.
  /// Prefers the broader ISCO-08 group title over the specific ESCO label.
  String get displayTitle => iscoTitle ?? title;

  factory PrimaryOccupation.fromJson(Map<String, dynamic> json) {
    return PrimaryOccupation(
      title: json['title'] ?? '',
      iscoCode: json['isco_code'] ?? '',
      iscoTitle: json['isco_title'],
      escoCode: json['esco_code'],
      confidence: json['confidence'] ?? 'low',
      score: (json['score'] ?? 0.0).toDouble(),
      matchReason: json['match_reason'],
      sectors: (json['sectors'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

class ProfileEducation {
  final String isced;
  final String label;

  const ProfileEducation({required this.isced, required this.label});

  factory ProfileEducation.fromJson(Map<String, dynamic> json) =>
      ProfileEducation(isced: json['isced'] ?? '', label: json['label'] ?? '');
}

class MappedSkill {
  final String label;
  final String type;
  final double? matchScore;
  final String? reason;

  const MappedSkill({
    required this.label,
    required this.type,
    this.matchScore,
    this.reason,
  });

  factory MappedSkill.fromJson(Map<String, dynamic> json) => MappedSkill(
    label: json['label'] ?? json['skill'] ?? '',
    type: json['type'] ?? 'knowledge',
    matchScore: json['match_score'] != null ? (json['match_score'] as num).toDouble() : null,
    reason: json['reason'],
  );
}

class ProfileSkills {
  final List<MappedSkill> mapped;
  final List<String> inferred;
  final List<String> local;

  const ProfileSkills({
    required this.mapped,
    required this.inferred,
    required this.local,
  });

  factory ProfileSkills.fromJson(Map<String, dynamic> json) => ProfileSkills(
    mapped: (json['mapped'] as List<dynamic>? ?? [])
        .map((e) => MappedSkill.fromJson(e as Map<String, dynamic>))
        .toList(),
    inferred: (json['inferred'] as List<dynamic>? ?? []).cast<String>(),
    local: (json['local'] as List<dynamic>? ?? []).cast<String>(),
  );
}

class ProfileConfidence {
  final String overall;
  final double score;
  final String extractionMethod;
  final String? extractionProvider;
  final List<String> countryAdjustments;

  const ProfileConfidence({
    required this.overall,
    required this.score,
    required this.extractionMethod,
    this.extractionProvider,
    this.countryAdjustments = const [],
  });

  factory ProfileConfidence.fromJson(Map<String, dynamic> json) => ProfileConfidence(
    overall: json['overall'] ?? 'low',
    score: (json['score'] ?? 0.0).toDouble(),
    extractionMethod: json['extraction_method'] ?? 'heuristic',
    extractionProvider: json['extraction_provider'],
    countryAdjustments: (json['country_adjustments'] as List<dynamic>? ?? []).cast<String>(),
  );
}
