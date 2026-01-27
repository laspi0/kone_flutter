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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'role': role,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      passwordHash: map['password_hash'],
      role: map['role'],
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isCashier => role == 'cashier';
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

  Product({
    this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category_id': categoryId,
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
    );
  }
}

// NOUVEAUX MODÈLES POUR VENTES

class Sale {
  final int? id;
  final DateTime date;
  final int userId;
  final int? customerId; // Nouveau champ pour le client
  final double total;
  final String status;

  Sale({
    this.id,
    required this.date,
    required this.userId,
    this.customerId,
    required this.total,
    this.status = 'completed',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'user_id': userId,
      'customer_id': customerId,
      'total': total,
      'status': status,
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
    );
  }

  Sale copyWith({
    int? id,
    DateTime? date,
    int? userId,
    int? customerId,
    double? total,
    String? status,
  }) {
    return Sale(
      id: id ?? this.id,
      date: date ?? this.date,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      total: total ?? this.total,
      status: status ?? this.status,
    );
  }
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
