import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('shop_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Création de la table users
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    // Insertion des utilisateurs par défaut
    await _insertDefaultUsers(db);
  }

  Future _insertDefaultUsers(Database db) async {
    // Admin par défaut
    await db.insert('users', {
      'username': 'admin',
      'password_hash':
          'admin123', // En production, utiliser bcrypt ou similaire
      'role': 'admin',
    });

    // Caissier par défaut
    await db.insert('users', {
      'username': 'caissier',
      'password_hash': 'caissier123',
      'role': 'cashier',
    });

    // Autre caissier
    await db.insert('users', {
      'username': 'marie',
      'password_hash': 'marie123',
      'role': 'cashier',
    });
  }

  // Authentification
  Future<User?> login(String username, String password) async {
    final db = await database;

    final maps = await db.query(
      'users',
      where: 'username = ? AND password_hash = ?',
      whereArgs: [username, password],
    );

    if (maps.isEmpty) return null;

    return User.fromMap(maps.first);
  }

  // Récupérer tous les utilisateurs (pour admin)
  Future<List<User>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users', orderBy: 'username');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  // Fermer la base de données
  Future close() async {
    final db = await database;
    db.close();
  }
}
