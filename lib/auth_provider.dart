import 'package:flutter/material.dart';
import 'database.dart';
import 'models.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> _products = [];
  List<Category> _categories = [];
  List<Sale> _sales = [];
  List<CartItem> _cart = [];
  List<Customer> _customers = [];
  List<User> _users = [];
  Customer? _selectedCustomer;

  final DatabaseHelper _db = DatabaseHelper.instance;

  // Getters
  User? get currentUser => _currentUser;
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Product> get products => _products;
  List<Category> get categories => _categories;
  List<Sale> get sales => _sales;
  List<CartItem> get cart => _cart;
  List<Customer> get customers => _customers;
  List<User> get users => _users;
  Customer? get selectedCustomer => _selectedCustomer;

  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isCashier => _currentUser?.isCashier ?? false;

  double get cartTotal => _cart.fold(0, (sum, item) => sum + item.subtotal);
  int get cartItemCount => _cart.fold(0, (sum, item) => sum + item.quantity);

  // Login
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _db.login(username, password);

      if (user != null) {
        _currentUser = user;
        await _loadData();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Identifiants incorrects';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _loadData() async {
    await loadUsers();
    await loadCategories();
    await loadProducts();
    await loadSales();
    await loadCustomers();
  }

  void logout() {
    _currentUser = null;
    _errorMessage = null;
    _products = [];
    _categories = [];
    _sales = [];
    _cart = [];
    _customers = [];
    _users = [];
    _selectedCustomer = null;
    notifyListeners();
  }
   Future<void> loadUsers() async {
    _users = await _db.getAllUsers();
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // User profile updates
  Future<void> updateUsername(String newUsername) async {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(username: newUsername);
    await _db.updateUser(updatedUser);
    _currentUser = updatedUser;
    notifyListeners();
  }

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    if (_currentUser == null) return false;

    // NOTE: This is a simple comparison. In a real app, you'd hash
    // the input and compare the hashes.
    if (_currentUser!.passwordHash != currentPassword) {
      return false;
    }

    final updatedUser = _currentUser!.copyWith(passwordHash: newPassword);
    await _db.updateUser(updatedUser);
    _currentUser = updatedUser;
    notifyListeners();
    return true;
  }

  // Categories
  Future<void> loadCategories() async {
    _categories = await _db.getCategories();
    notifyListeners();
  }

  Future<void> addCategory(Category category) async {
    await _db.insertCategory(category);
    await loadCategories();
  }

  Future<void> updateCategory(Category category) async {
    await _db.updateCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    await _db.deleteCategory(id);
    await loadCategories();
    await loadProducts();
  }

  // Products
  Future<void> loadProducts() async {
    _products = await _db.getProducts();
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    await _db.insertProduct(product);
    await loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    await _db.updateProduct(product);
    await loadProducts();
  }

  Future<void> deleteProduct(int id) async {
    await _db.deleteProduct(id);
    await loadProducts();
  }

  String getCategoryName(int categoryId) {
    final category = _categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => Category(name: 'Inconnu'),
    );
    return category.name;
  }

  // Cart operations
  void addToCart(Product product) {
    final existingIndex = _cart.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      if (_cart[existingIndex].quantity < product.stock) {
        _cart[existingIndex].quantity++;
      }
    } else {
      _cart.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void removeFromCart(Product product) {
    _cart.removeWhere((item) => item.product.id == product.id);
    notifyListeners();
  }

  void updateCartQuantity(Product product, int quantity) {
    final index = _cart.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      if (quantity <= 0) {
        _cart.removeAt(index);
      } else if (quantity <= product.stock) {
        _cart[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cart = [];
    notifyListeners();
  }

  // Sales operations
  Future<Map<String, dynamic>?> completeSale() async {
    if (_cart.isEmpty || _currentUser == null) return null;

    final customer = _selectedCustomer ?? Customer.walkin;
    List<CartItem> currentCart = List.from(_cart); // Create a copy of the cart

    try {
      final sale = Sale(
        date: DateTime.now(),
        userId: _currentUser!.id!,
        total: cartTotal,
        customerId: customer.id == 0 ? null : customer.id, // Store null for walk-in customer
      );

      final items = currentCart
          .map(
            (cartItem) => SaleItem(
              saleId: 0, // Will be updated by DB
              productId: cartItem.product.id!,
              productName: cartItem.product.name,
              quantity: cartItem.quantity,
              unitPrice: cartItem.product.price,
              subtotal: cartItem.subtotal,
            ),
          )
          .toList();

      final createdSale = await _db.createSale(sale, items);
      final fetchedSaleItems = await _db.getSaleItems(createdSale.id!); // Fetch actual SaleItems with correct saleId

      _selectedCustomer = null; // Reset client
      clearCart();
      await loadProducts();
      await loadSales();

      Customer? actualCustomer = customer.id == 0 ? null : await _db.getCustomerById(customer.id!);

      return {
        'sale': createdSale,
        'saleItems': fetchedSaleItems,
        'customer': actualCustomer,
      };
    } catch (e) {
      _errorMessage = 'Erreur lors de la vente: $e';
      notifyListeners();
      return null;
    }
  }

  // Customer operations
  Future<void> loadCustomers() async {
    _customers = await _db.getCustomers();
    notifyListeners();
  }

  Future<void> addCustomer(Customer customer) async {
    await _db.insertCustomer(customer);
    await loadCustomers();
  }

  Future<void> updateCustomer(Customer customer) async {
    await _db.updateCustomer(customer);
    await loadCustomers();
  }

  Future<void> deleteCustomer(int id) async {
    await _db.deleteCustomer(id);
    await loadCustomers();
  }

  void selectCustomer(Customer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  Future<void> loadSales() async {
    _sales = await _db.getSales();
    notifyListeners();
  }

  Future<List<SaleItem>> getSaleItems(int saleId) async {
    return await _db.getSaleItems(saleId);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
