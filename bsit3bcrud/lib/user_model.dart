class User {
  final int id; // Add an id field
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int, // Ensure the id is parsed from the map
      name: map['name'],
      email: map['email'],
    );
  }
}
