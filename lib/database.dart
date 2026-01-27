import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
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
    final documentsDir = await getApplicationDocumentsDirectory();
    final path = join(documentsDir.path, filePath);
    
    final directory = Directory(documentsDir.path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return await openDatabase(
      path,
      version: 3, // CHANGÉ À 3 pour les nouvelles tables
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          description TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          price REAL NOT NULL,
          stock INTEGER NOT NULL,
          category_id INTEGER NOT NULL,
          FOREIGN KEY (category_id) REFERENCES categories (id)
        )
      ''');

      await _insertDefaultCategories(db);
      await _insertDefaultProducts(db);
    }
    
    if (oldVersion < 3) {
      // Ajouter les tables sales
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sales (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          user_id INTEGER NOT NULL,
          total REAL NOT NULL,
          status TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS sale_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sale_id INTEGER NOT NULL,
          product_id INTEGER NOT NULL,
          product_name TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          unit_price REAL NOT NULL,
          subtotal REAL NOT NULL,
          FOREIGN KEY (sale_id) REFERENCES sales (id),
          FOREIGN KEY (product_id) REFERENCES products (id)
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        stock INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        total REAL NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await _insertDefaultData(db);
  }

  Future _insertDefaultData(Database db) async {
    await db.insert('users', {
      'username': 'admin',
      'password_hash': 'admin123',
      'role': 'admin',
    });

    await db.insert('users', {
      'username': 'caissier',
      'password_hash': 'caissier123',
      'role': 'cashier',
    });
    
    await db.insert('users', {
      'username': 'marie',
      'password_hash': 'marie123',
      'role': 'cashier',
    });

    await _insertDefaultCategories(db);
    await _insertDefaultProducts(db);
  }

  Future _insertDefaultCategories(Database db) async {
    await db.insert('categories', {
      'name': 'Électronique',
      'description': 'Appareils électroniques et accessoires',
    });
    await db.insert('categories', {
      'name': 'Vêtements',
      'description': 'Vêtements et accessoires de mode',
    });
    await db.insert('categories', {
      'name': 'Alimentation',
      'description': 'Produits alimentaires',
    });
    await db.insert('categories', {
      'name': 'Livres',
      'description': 'Livres et magazines',
    });
    await db.insert('categories', {
      'name': 'Sport',
      'description': 'Équipements sportifs',
    });
  }

  Future _insertDefaultProducts(Database db) async {
    await db.insert('products', {
      'name': 'iPhone 15 Pro',
      'description': 'Smartphone Apple dernière génération',
      'price': 650000.0,
      'stock': 15,
      'category_id': 1,
    });
    await db.insert('products', {
      'name': 'MacBook Air M2',
      'description': 'Ordinateur portable Apple',
      'price': 850000.0,
      'stock': 8,
      'category_id': 1,
    });
    await db.insert('products', {
      'name': 'AirPods Pro',
      'description': 'Écouteurs sans fil Apple',
      'price': 75000.0,
      'stock': 25,
      'category_id': 1,
    });
    await db.insert('products', {
      'name': 'T-shirt Nike',
      'description': 'T-shirt sport coton',
      'price': 15000.0,
      'stock': 50,
      'category_id': 2,
    });
    await db.insert('products', {
      'name': 'Jean Levi\'s 501',
      'description': 'Jean classique coupe droite',
      'price': 35000.0,
      'stock': 30,
      'category_id': 2,
    });
    await db.insert('products', {
      'name': 'Riz 25kg',
      'description': 'Sac de riz brisé',
      'price': 12500.0,
      'stock': 100,
      'category_id': 3,
    });
    await db.insert('products', {
      'name': 'Huile 5L',
      'description': 'Huile végétale',
      'price': 8500.0,
      'stock': 75,
      'category_id': 3,
    });
  }

  // Auth
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

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users', orderBy: 'username');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  // Categories
  Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'name');
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Products
  Future<List<Product>> getProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'name');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getProductsByCategory(int categoryId) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'name',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // Sales
  Future<int> createSale(Sale sale, List<SaleItem> items) async {
    final db = await database;
    
    return await db.transaction((txn) async {
      final saleId = await txn.insert('sales', sale.toMap());
      
      for (var item in items) {
        await txn.insert('sale_items', {
          ...item.toMap(),
          'sale_id': saleId,
        });
        
        await txn.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [item.quantity, item.productId],
        );
      }
      
      return saleId;
    });
  }

  Future<List<Sale>> getSales() async {
    final db = await database;
    final maps = await db.query('sales', orderBy: 'date DESC');
    return maps.map((map) => Sale.fromMap(map)).toList();
  }

  Future<List<SaleItem>> getSaleItems(int saleId) async {
    final db = await database;
    final maps = await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    return maps.map((map) => SaleItem.fromMap(map)).toList();
  }

  Future<List<Sale>> getSalesByUser(int userId) async {
    final db = await database;
    final maps = await db.query(
      'sales',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Sale.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getSalesStats() async {
    final db = await database;
    
    final totalSales = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM sales WHERE status = "completed"')
    ) ?? 0;
    
    final totalRevenue = (await db.rawQuery(
      'SELECT SUM(total) as revenue FROM sales WHERE status = "completed"'
    )).first['revenue'] ?? 0.0;
    
    return {
      'totalSales': totalSales,
      'totalRevenue': totalRevenue,
    };
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}