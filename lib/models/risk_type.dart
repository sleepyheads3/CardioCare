enum RiskLevel {
  low,
  medium,
  high,
  critical
}

class RiskType {
  final RiskLevel level;
  final String name;
  final String description;
  final String messageTemplate;
  final bool notifyContacts;
  final bool callAmbulance;
  final bool showHospitals;

  const RiskType({
    required this.level,
    required this.name,
    required this.description,
    required this.messageTemplate,
    required this.notifyContacts,
    required this.callAmbulance,
    required this.showHospitals,
  });

  static const List<RiskType> types = [
    RiskType(
      level: RiskLevel.low,
      name: 'Low Risk',
      description: 'Slight deviation from normal values',
      messageTemplate: 'Patient is showing slight deviations in vital signs. Please check in.',
      notifyContacts: true,
      callAmbulance: false,
      showHospitals: false,
    ),
    RiskType(
      level: RiskLevel.medium,
      name: 'Medium Risk',
      description: 'Moderate deviation requiring attention',
      messageTemplate: 'Patient is showing concerning vital signs. Immediate attention recommended.',
      notifyContacts: true,
      callAmbulance: false,
      showHospitals: true,
    ),
    RiskType(
      level: RiskLevel.high,
      name: 'High Risk',
      description: 'Severe deviation requiring immediate action',
      messageTemplate: 'URGENT: Patient is showing severe vital sign deviations. Immediate medical attention required.',
      notifyContacts: true,
      callAmbulance: true,
      showHospitals: true,
    ),
    RiskType(
      level: RiskLevel.critical,
      name: 'Critical Risk',
      description: 'Life-threatening condition',
      messageTemplate: 'EMERGENCY: Patient is in critical condition. Immediate medical intervention required.',
      notifyContacts: true,
      callAmbulance: true,
      showHospitals: true,
    ),
  ];

  static RiskType fromString(String name) {
    return types.firstWhere(
      (type) => type.name.toLowerCase() == name.toLowerCase(),
      orElse: () => types.first,
    );
  }
} 