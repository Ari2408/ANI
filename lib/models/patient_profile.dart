class PatientProfile {
  final String id;
  final String name;
  final int age;
  final String dementiaStage;
  final String preferredLanguage;
  final String primaryCaregiverContact;

  PatientProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.dementiaStage,
    required this.preferredLanguage,
    required this.primaryCaregiverContact,
  });

  factory PatientProfile.defaultProfile() {
    return PatientProfile(
      id: 'p_001',
      name: 'Smt. Devi / Shri Kumar',
      age: 74,
      dementiaStage: 'Stage 2 Mild Cognitive Impairment (MCI)',
      preferredLanguage: 'ta',
      primaryCaregiverContact: '+91-9876543210',
    );
  }
}
