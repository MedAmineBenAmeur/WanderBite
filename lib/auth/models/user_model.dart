class User {
  final String name;
  final String email;
  final String password;
  final String? profileImagePath;

  User({
    required this.name,
    required this.email,
    required this.password,
    this.profileImagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'profileImagePath': profileImagePath,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      email: json['email'],
      password: json['password'],
      profileImagePath: json['profileImagePath'],
    );
  }

  // Create a copy with updated fields
  User copyWith({
    String? name,
    String? email,
    String? password,
    String? profileImagePath,
  }) {
    return User(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }

  @override
  String toString() {
    return 'User{name: $name, email: $email}';
  }
}
