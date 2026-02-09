class User {
  final int? id;
  final String username;
  final String passwordHash;
  final String role; // 'admin', 'cashier', or 'superuser'
  final bool isActive; // New field for account activation/deactivation

  User({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
    this.isActive = true, // Default to true
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'role': role,
      'is_active': isActive ? 1 : 0, // Store boolean as integer
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      passwordHash: map['password_hash'],
      role: map['role'],
      isActive: map['is_active'] == 1, // Convert integer back to boolean
    );
  }

  bool get isAdmin => role == 'admin' || role == 'superuser';
  bool get isCashier => role == 'cashier';
  bool get isSuperuser => role == 'superuser'; // New getter for superuser role

  User copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? role,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}

class Category {
  final int? id;
  final String name;
  final String? description;

  Category({this.id, required this.name, this.description});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'description': description};
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      description: map['description'],
    );
  }
}

class Product {
  final int? id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final int categoryId;
  final String? barcode; // Champ ajouté

  Product({
    this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    this.barcode, // Ajouté au constructeur
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category_id': categoryId,
      'barcode': barcode, // Ajouté à la map
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: (map['price'] as num).toDouble(),
      stock: map['stock'],
      categoryId: map['category_id'],
      barcode: map['barcode'], // Ajouté depuis la map
    );
  }
}

// NOUVEAUX MODÈLES POUR VENTES

// AJOUT À FAIRE DANS models.dart

class Sale {
  final int? id;
  final DateTime date;
  final int userId;
  final int? customerId;
  final double total;
  final String status;
  final double? amountPaid; // NOUVEAU: Montant reçu du client
  final double? change; // NOUVEAU: Monnaie rendue (calculé automatiquement)
  final int? sessionId; // Session de caisse

  Sale({
    this.id,
    required this.date,
    required this.userId,
    this.customerId,
    required this.total,
    this.status = 'completed',
    this.amountPaid,
    this.change,
    this.sessionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'user_id': userId,
      'customer_id': customerId,
      'total': total,
      'status': status,
      'amount_paid': amountPaid,
      'change': change,
      'session_id': sessionId,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      date: DateTime.parse(map['date']),
      userId: map['user_id'],
      customerId: map['customer_id'],
      total: (map['total'] as num).toDouble(),
      status: map['status'],
      amountPaid: map['amount_paid'] != null 
          ? (map['amount_paid'] as num).toDouble() 
          : null,
      change: map['change'] != null 
          ? (map['change'] as num).toDouble() 
          : null,
      sessionId: map['session_id'],
    );
  }

  Sale copyWith({
    int? id,
    DateTime? date,
    int? userId,
    int? customerId,
    double? total,
    String? status,
    double? amountPaid,
    double? change,
    int? sessionId,
  }) {
    return Sale(
      id: id ?? this.id,
      date: date ?? this.date,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      total: total ?? this.total,
      status: status ?? this.status,
      amountPaid: amountPaid ?? this.amountPaid,
      change: change ?? this.change,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  // Calculer automatiquement la monnaie rendue
  double get calculatedChange => 
      amountPaid != null ? amountPaid! - total : 0.0;
}

class CashSession {
  final int? id;
  final DateTime openedAt;
  final DateTime? closedAt;
  final int openedBy;
  final double openingAmount;
  final double? closingAmount;
  final double? expectedAmount;
  final double? difference;
  final String status; // open, closed
  final String? note;

  CashSession({
    this.id,
    required this.openedAt,
    this.closedAt,
    required this.openedBy,
    required this.openingAmount,
    this.closingAmount,
    this.expectedAmount,
    this.difference,
    this.status = 'open',
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'opened_at': openedAt.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'opened_by': openedBy,
      'opening_amount': openingAmount,
      'closing_amount': closingAmount,
      'expected_amount': expectedAmount,
      'difference': difference,
      'status': status,
      'note': note,
    };
  }

  factory CashSession.fromMap(Map<String, dynamic> map) {
    return CashSession(
      id: map['id'],
      openedAt: DateTime.parse(map['opened_at']),
      closedAt: map['closed_at'] != null
          ? DateTime.parse(map['closed_at'])
          : null,
      openedBy: map['opened_by'],
      openingAmount: (map['opening_amount'] as num).toDouble(),
      closingAmount: map['closing_amount'] != null
          ? (map['closing_amount'] as num).toDouble()
          : null,
      expectedAmount: map['expected_amount'] != null
          ? (map['expected_amount'] as num).toDouble()
          : null,
      difference: map['difference'] != null
          ? (map['difference'] as num).toDouble()
          : null,
      status: map['status'],
      note: map['note'],
    );
  }

  CashSession copyWith({
    int? id,
    DateTime? openedAt,
    DateTime? closedAt,
    int? openedBy,
    double? openingAmount,
    double? closingAmount,
    double? expectedAmount,
    double? difference,
    String? status,
    String? note,
  }) {
    return CashSession(
      id: id ?? this.id,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      openedBy: openedBy ?? this.openedBy,
      openingAmount: openingAmount ?? this.openingAmount,
      closingAmount: closingAmount ?? this.closingAmount,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      difference: difference ?? this.difference,
      status: status ?? this.status,
      note: note ?? this.note,
    );
  }
}

class CashSessionSummary {
  final CashSession session;
  final double totalSales;
  final double totalReceived;
  final double totalChange;
  final double expectedAmount;
  final int totalCount;

  CashSessionSummary({
    required this.session,
    required this.totalSales,
    required this.totalReceived,
    required this.totalChange,
    required this.expectedAmount,
    required this.totalCount,
  });
}

class SaleItem {
  final int? id;
  final int saleId;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  SaleItem({
    this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'],
      saleId: map['sale_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      quantity: map['quantity'],
      unitPrice: (map['unit_price'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.price * quantity;
}

// À AJOUTER dans models.dart

class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;

  Customer({this.id, required this.name, this.phone, this.email, this.address});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
    );
  }

  // Client spécial pour les ventes au comptoir
  static Customer get walkin => Customer(id: 0, name: 'Client au comptoir');

  bool get isWalkin => id == 0;
}

class ShopInfo {
  final int id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String? logo;
  final int lowStockThreshold;

  ShopInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    this.logo,
    this.lowStockThreshold = 10,
  });

  factory ShopInfo.defaultShop() => ShopInfo(
        id: 1,
        name: 'Mon Magasin',
        address: 'Votre adresse ici',
        phone: 'XX-XXX-XX-XX',
        email: 'pro43071919@gmail.com',
        lowStockThreshold: 10,
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'logo': logo,
      'low_stock_threshold': lowStockThreshold,
    };
  }

  factory ShopInfo.fromMap(Map<String, dynamic> map) {
    return ShopInfo(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      phone: map['phone'],
      email: map['email'],
      logo: map['logo'],
      lowStockThreshold: map['low_stock_threshold'] ?? 10,
    );
  }

  ShopInfo copyWith({
    String? name,
    String? address,
    String? phone,
    String? email,
    String? logo,
    int? lowStockThreshold,
  }) {
    return ShopInfo(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logo: logo ?? this.logo,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    );
  }
}

class SaleWithItems {
  final Sale sale;
  final List<SaleItem> items;

  SaleWithItems({required this.sale, required this.items});
}
