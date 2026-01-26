// Modèle User pour l'authentification
class User {
  final int? id;
  final String username;
  final String passwordHash;
  final String role; // 'admin' ou 'cashier'

  User({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
  });

  // Conversion vers Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'role': role,
    };
  }

  // Création depuis Map (SQLite)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      passwordHash: map['password_hash'],
      role: map['role'],
    );
  }

  // Vérifier si l'utilisateur est admin
  bool get isAdmin => role == 'admin';
  
  // Vérifier si l'utilisateur est caissier
  bool get isCashier => role == 'cashier';
}