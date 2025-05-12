class User {
  final String firstName;
  final String lastName;
  final String nic;
  final String? fullName;
  final String? address;
  final String? contact;
  final String? profession;
  final String? district;
  final String? gender;
  final String? language;

  User({
    required this.firstName,
    required this.lastName,
    required this.nic,
    this.fullName,
    this.address,
    this.contact,
    this.profession,
    this.district,
    this.gender,
    this.language,
  });
}