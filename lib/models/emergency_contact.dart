import 'risk_type.dart';

class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final bool isPrimary;
  final List<RiskLevel> notifyAtRiskLevels;
  final bool receiveSMS;
  final bool receiveCalls;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.isPrimary = false,
    List<RiskLevel>? notifyAtRiskLevels,
    this.receiveSMS = true,
    this.receiveCalls = true,
  }) : notifyAtRiskLevels = notifyAtRiskLevels ?? [RiskLevel.high, RiskLevel.critical];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
      'isPrimary': isPrimary,
      'notifyAtRiskLevels': notifyAtRiskLevels.map((e) => e.toString()).toList(),
      'receiveSMS': receiveSMS,
      'receiveCalls': receiveCalls,
    };
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id'] as String,
      name: map['name'] as String,
      phoneNumber: map['phoneNumber'] as String,
      relationship: map['relationship'] as String,
      isPrimary: map['isPrimary'] as bool? ?? false,
      notifyAtRiskLevels: (map['notifyAtRiskLevels'] as List<dynamic>?)
          ?.map((e) => RiskLevel.values.firstWhere(
                (level) => level.toString() == e,
                orElse: () => RiskLevel.high,
              ))
          .toList() ??
          [RiskLevel.high, RiskLevel.critical],
      receiveSMS: map['receiveSMS'] as bool? ?? true,
      receiveCalls: map['receiveCalls'] as bool? ?? true,
    );
  }

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? relationship,
    bool? isPrimary,
    List<RiskLevel>? notifyAtRiskLevels,
    bool? receiveSMS,
    bool? receiveCalls,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      notifyAtRiskLevels: notifyAtRiskLevels ?? this.notifyAtRiskLevels,
      receiveSMS: receiveSMS ?? this.receiveSMS,
      receiveCalls: receiveCalls ?? this.receiveCalls,
    );
  }
} 