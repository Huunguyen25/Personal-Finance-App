class User {
  final int? id;
  final String email;
  final String? phone;
  final String? firstName;
  final String? lastName;
  final String? dateOfBirth;
  final String password;

  User({
    this.id,
    required this.email,
    this.phone,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'password': password,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      phone: map['phone'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      dateOfBirth: map['dateOfBirth'],
      password: map['password'],
    );
  }
}
