/// Data collected from the user on the home/intake screen.
/// Sent to POST /api/module1/profile.
class IntakeModel {
  final String freeText;
  final String countryCode;
  final String? educationLevel;
  final List<String> informalSkills;
  final List<String> languages;
  final int experienceYears;
  final String? preferredSector;

  const IntakeModel({
    required this.freeText,
    required this.countryCode,
    this.educationLevel,
    this.informalSkills = const [],
    this.languages = const [],
    this.experienceYears = 0,
    this.preferredSector,
  });

  /// Maps to the field names expected by the Node API.
  Map<String, dynamic> toJson() => {
    // Core required fields
    'work_description': freeText,
    'country_code': countryCode,
    // Optional — inferred by LLM if not provided
    if (preferredSector != null) 'sector': preferredSector,
    // Skill signals fed into the extractor
    if (informalSkills.isNotEmpty) 'selected_skills': informalSkills,
    if (languages.isNotEmpty) 'extra_skills': languages.map((l) => '$l speaker').toList(),
    // Scoring signals
    if (experienceYears > 0) 'experience_years': experienceYears,
    if (educationLevel != null) 'education_level': educationLevel,
  };
}

/// Predefined education levels (ISCED-aligned labels)
const List<String> kEducationLevels = [
  'No formal education',
  'Primary (ISCED 1)',
  'Lower secondary (ISCED 2)',
  'Upper secondary (ISCED 3)',
  'Vocational / TVET (ISCED 4)',
  'Bachelor or equivalent (ISCED 6)',
  'Master or equivalent (ISCED 7)',
];

/// Common informal skill tags shown as checkboxes
const List<String> kInformalSkillOptions = [
  'Mobile phone repair',
  'Electrical wiring',
  'Cooking / food preparation',
  'Tailoring / sewing',
  'Carpentry / woodwork',
  'Masonry / construction',
  'Driving / transport',
  'Small retail / trading',
  'Farming / agriculture',
  'Hair and beauty',
  'Welding / metalwork',
  'IT / computer skills',
  'Teaching / tutoring',
  'Healthcare / first aid',
];

/// Common global language options (extends automatically — user can type in free text)
const List<String> kLanguageOptions = [
  'English',
  'Arabic',
  'Bengali',
  'Chinese (Mandarin)',
  'French',
  'Hausa',
  'Hindi',
  'Indonesian',
  'Kiswahili',
  'Portuguese',
  'Russian',
  'Spanish',
  'Twi',
  'Urdu',
  'Vietnamese',
  'Yoruba',
];

/// Sector options (maps to ISCO major groups)
const List<String> kSectorOptions = [
  'Agriculture & Fishing',
  'Construction & Trades',
  'Manufacturing',
  'Retail & Commerce',
  'Transport & Logistics',
  'ICT & Electronics',
  'Health & Social Care',
  'Education',
  'Food & Hospitality',
  'Finance & Administration',
];
