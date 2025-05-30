class Guardian {
  final String name;
  final String patientId;
  final String mobile;

  Guardian({
    required this.name,
    required this.patientId,
    required this.mobile,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'patientId': patientId,
    'mobile': mobile,
  };
}