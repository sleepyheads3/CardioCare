class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String mobile;
  final String guardianMobile;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.mobile,
    required this.guardianMobile,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'age': age,
    'gender': gender,
    'mobile': mobile,
    'guardianMobile': guardianMobile,
  };
}