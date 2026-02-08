import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const int databaseVersion = 11; // Mise à jour de la version de la base de données

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
      version: databaseVersion, // Version mise à jour
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

    if (oldVersion < 4) {
      // Add shop_info table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS shop_info (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          address TEXT NOT NULL,
          phone TEXT NOT NULL,
          email TEXT NOT NULL,
          logo TEXT,
          low_stock_threshold INTEGER NOT NULL DEFAULT 10
        )
      ''');
      await _insertDefaultShopInfo(db);
    }
    
    if (oldVersion < 6) {
      // Add amount_paid and change columns to sales table
      await db.execute('''
        ALTER TABLE sales ADD COLUMN amount_paid REAL DEFAULT NULL
      ''');
      await db.execute('''
        ALTER TABLE sales ADD COLUMN change REAL DEFAULT NULL
      ''');
    }
    if (oldVersion < 7) {
      // Add barcode column to products table
      await db.execute('ALTER TABLE products ADD COLUMN barcode TEXT');
    }
    if (oldVersion < 8) {
      // Set barcodes for default products that might not have one
      await db.rawUpdate(
        "UPDATE products SET barcode = ? WHERE name = ? AND barcode IS NULL",
        ['1111111111111', 'iPhone 15 Pro']);
      await db.rawUpdate(
        "UPDATE products SET barcode = ? WHERE name = ? AND barcode IS NULL",
        ['2222222222222', 'MacBook Air M2']);
    }
     if (oldVersion < 9) {
      try {
        await db.execute('ALTER TABLE shop_info ADD COLUMN low_stock_threshold INTEGER NOT NULL DEFAULT 10');
      } catch (e) {
        // Column likely already exists, which is fine.

      }
    }
    if (oldVersion < 10) {
      // Add is_active column to users table
      await db.execute('ALTER TABLE users ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1');
      
      // Also add the superuser if it doesn't exist, for existing databases
      await db.insert(
        'users',
        {
          'username': 'superuser',
          'password_hash': 'superuser123',
          'role': 'superuser',
          'is_active': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore, // Ignore if 'superuser' already exists
      );
    }
    if (oldVersion < 11) {

      // Re-run superuser creation just in case it failed before.
      await db.insert(
        'users',
        {
          'username': 'superuser',
          'password_hash': 'superuser123',
          'role': 'superuser',
          'is_active': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore, // Ignore if 'superuser' already exists
      );

    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT
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
        barcode TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        customer_id INTEGER,
        total REAL NOT NULL,
        status TEXT NOT NULL,
        amount_paid REAL DEFAULT NULL,
        change REAL DEFAULT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (customer_id) REFERENCES customers (id)
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

    await db.execute('''
      CREATE TABLE shop_info (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL,
        logo TEXT,
        low_stock_threshold INTEGER NOT NULL DEFAULT 10
      )
    ''');

    await _insertDefaultData(db);
    await _insertDefaultShopInfo(db);
  }

  Future _insertDefaultData(Database db) async {
    await db.insert('users', {
      'username': 'admin',
      'password_hash': 'admin123',
      'role': 'admin',
      'is_active': 1,
    });

    await db.insert('users', {
      'username': 'caissier',
      'password_hash': 'caissier123',
      'role': 'cashier',
      'is_active': 1,
    });

    await db.insert('users', {
      'username': 'marie',
      'password_hash': 'marie123',
      'role': 'cashier',
      'is_active': 1,
    });

    await db.insert('users', {
      'username': 'superuser',
      'password_hash': 'superuser123',
      'role': 'superuser',
      'is_active': 1,
    });
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

  Future _insertDefaultCustomers(Database db) async {
    await db.insert('customers', {
      'name': 'Fatou Diallo',
      'phone': '+221 77 123 45 67',
      'email': 'fatou.diallo@email.com',
      'address': 'Dakar, Plateau',
    });
    await db.insert('customers', {
      'name': 'Moussa Sow',
      'phone': '+221 78 234 56 78',
      'email': 'moussa.sow@email.com',
      'address': 'Thiès',
    });
    await db.insert('customers', {
      'name': 'Aminata Ndiaye',
      'phone': '+221 76 345 67 89',
      'email': 'aminata.n@email.com',
      'address': 'Rufisque',
    });
  }

  Future _insertDefaultShopInfo(Database db) async {
    final defaultShop = ShopInfo.defaultShop();
    await db.insert('shop_info', defaultShop.toMap());
  }

  Future _insertDefaultProducts(Database db) async {
    await db.insert('products', {
      'name': 'iPhone 15 Pro',
      'description': 'Smartphone Apple dernière génération',
      'price': 650000.0,
      'stock': 15,
      'category_id': 1,
      'barcode': '1111111111111',
    });
    await db.insert('products', {
      'name': 'MacBook Air M2',
      'description': 'Ordinateur portable Apple',
      'price': 850000.0,
      'stock': 8,
      'category_id': 1,
      'barcode': '2222222222222',
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

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
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
        await txn.insert('sale_items', {...item.toMap(), 'sale_id': saleId});

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

  Future<Sale?> getSaleById(int id) async {
    final db = await database;
    final maps = await db.query(
      'sales',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Sale.fromMap(maps.first);
    }
    return null;
  }

  Future<Map<String, dynamic>> getSalesStats() async {
    final db = await database;

    final totalSales =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM sales WHERE status = "completed"',
          ),
        ) ??
        0;

    final totalRevenue =
        (await db.rawQuery(
          'SELECT SUM(total) as revenue FROM sales WHERE status = "completed"',
        )).first['revenue'] ??
        0.0;

    return {'totalSales': totalSales, 'totalRevenue': totalRevenue};
  }

  // Customer CRUD operations
  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final maps = await db.query('customers', orderBy: 'name');
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap());
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // ShopInfo operations
  Future<ShopInfo> getShopInfo() async {
    final db = await database;
    final maps = await db.query('shop_info', limit: 1);

    if (maps.isNotEmpty) {
      return ShopInfo.fromMap(maps.first);
    }
    return ShopInfo.defaultShop();
  }

  Future<int> updateShopInfo(ShopInfo shopInfo) async {
    final db = await database;
    // Assuming there's only one shop info entry (id=1)
    return await db.update(
      'shop_info',
      shopInfo.toMap(),
      where: 'id = ?',
      whereArgs: [1],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // User operations
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get customer by ID
  Future<Customer?> getCustomerById(int id) async {
    final db = await database;
    final maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  Future<List<SaleWithItems>> getSalesWithItemsInDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final salesMaps = await db.query(
      'sales',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );

    final List<SaleWithItems> salesWithItems = [];

    for (final saleMap in salesMaps) {
      final sale = Sale.fromMap(saleMap);
      final items = await getSaleItems(sale.id!);
      salesWithItems.add(SaleWithItems(sale: sale, items: items));
    }

    return salesWithItems;
  }

  // --- Data Clearing Methods ---

  /// Deletes a single sale and its items.
  Future<void> deleteSale(int saleId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
      await txn.delete('sales', where: 'id = ?', whereArgs: [saleId]);
    });
  }

  /// Deletes sales records within the given date range (inclusive).
  Future<void> deleteSalesInDateRange(String startDate, String endDate) async {
    final db = await database;
    // First, delete sale_items associated with the sales to be deleted.
    await db.rawDelete('''
      DELETE FROM sale_items 
      WHERE sale_id IN (SELECT id FROM sales WHERE date BETWEEN ? AND ?)
    ''', [startDate, endDate]);
    // Then, delete the sales themselves.
    await db.delete('sales', where: 'date BETWEEN ? AND ?', whereArgs: [startDate, endDate]);
  }

  /// Deletes all sales and sale items.
  Future<void> clearSalesHistory() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('sale_items');
      await txn.delete('sales');
    });
  }

  /// Deletes all customers.
  Future<void> clearCustomers() async {
    final db = await database;
    await db.delete('customers');
  }

  /// Deletes all products and categories.
  Future<void> clearProductsAndCategories() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('products');
      await txn.delete('categories');
    });
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
