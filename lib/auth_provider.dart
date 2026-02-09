import 'package:flutter/material.dart';
import 'database.dart';
import 'models.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoading = false;
  String? _errorMessage;

  List<Sale> _sales = [];
  List<CartItem> _cart = [];
  List<Customer> _customers = [];
  List<User> _users = [];
  Customer? _selectedCustomer;
  ShopInfo? _shopInfo;
  CashSession? _openCashSession;

  final DatabaseHelper _db = DatabaseHelper.instance;

  // Getters
  User? get currentUser => _currentUser;
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Sale> get sales => _sales;
  List<CartItem> get cart => _cart;
  List<Customer> get customers => _customers;
  List<User> get users => _users;
  ShopInfo? get shopInfo => _shopInfo;
  Customer? get selectedCustomer => _selectedCustomer;
  CashSession? get openCashSession => _openCashSession;

  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isCashier => _currentUser?.isCashier ?? false;
  bool get isSuperuser => _currentUser?.isSuperuser ?? false; // New getter

  double get cartTotal => _cart.fold(0, (sum, item) => sum + item.subtotal);
  int get cartItemCount => _cart.fold(0, (sum, item) => sum + item.quantity);

  // Login
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _db.login(username, password);

      if (user != null && user.isActive) { // Check if user is active
        _currentUser = user;
        await _loadData();
        _isLoading = false;
        notifyListeners();
        return true;
      } else if (user != null && !user.isActive) {
        _errorMessage = 'Votre compte est désactivé.';
        _isLoading = false;
        notifyListeners();
        return false;
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
    await loadSales();
    await loadCustomers();
    await loadShopInfo();
    await loadOpenCashSession();
  }

  void logout() {
    _currentUser = null;
    _errorMessage = null;
    _sales = [];
    _cart = [];
    _customers = [];
    _users = [];
    _selectedCustomer = null;
    _shopInfo = null;
    _openCashSession = null;
    notifyListeners();
  }

  Future<void> loadOpenCashSession() async {
    _openCashSession = await _db.getOpenCashSession();
    notifyListeners();
  }

  Future<CashSession?> startCashSession({
    required double openingAmount,
    String? note,
  }) async {
    if (_currentUser == null) return null;
    final session = CashSession(
      openedAt: DateTime.now(),
      openedBy: _currentUser!.id!,
      openingAmount: openingAmount,
      note: note,
      status: 'open',
    );
    final id = await _db.openCashSession(session);
    _openCashSession = session.copyWith(id: id);
    notifyListeners();
    return _openCashSession;
  }

  Future<Map<String, double>?> getOpenCashSessionSummary() async {
    if (_openCashSession?.id == null) return null;
    final totals = await _db.getCashSessionTotals(_openCashSession!.id!);
    final expected =
        _openCashSession!.openingAmount +
        (totals['total_received']! - totals['total_change']!);
    return {
      ...totals,
      'expected_amount': expected,
    };
  }

  Future<bool> closeOpenCashSession({
    required double closingAmount,
  }) async {
    if (_openCashSession?.id == null) return false;
    final summary = await getOpenCashSessionSummary();
    if (summary == null) return false;
    final expected = summary['expected_amount']!;
    final difference = closingAmount - expected;
    await _db.closeCashSession(
      sessionId: _openCashSession!.id!,
      closingAmount: closingAmount,
      expectedAmount: expected,
      difference: difference,
    );
    _openCashSession = null;
    notifyListeners();
    return true;
  }

  Future<List<CashSessionSummary>> getCashSessionSummaries() async {
    final sessions = await _db.getCashSessions();
    final summaries = <CashSessionSummary>[];

    for (final session in sessions) {
      if (session.id == null) continue;
      final totals = await _db.getCashSessionTotals(session.id!);
      final expected = session.expectedAmount ??
          (session.openingAmount +
              (totals['total_received']! - totals['total_change']!));

      summaries.add(
        CashSessionSummary(
          session: session,
          totalSales: totals['total_sales'] ?? 0,
          totalReceived: totals['total_received'] ?? 0,
          totalChange: totals['total_change'] ?? 0,
          expectedAmount: expected,
          totalCount: (totals['total_count'] ?? 0).round(),
        ),
      );
    }

    return summaries;
  }

  Future<void> deleteCashSession(int sessionId) async {
    await _db.deleteCashSession(sessionId);
    notifyListeners();
  }

  Future<void> loadUsers() async {
    _users = await _db.getAllUsers();
    notifyListeners();
  }

  // New User Management Methods
  Future<void> createUser(User user) async {
    await _db.insertUser(user);
    await loadUsers();
  }

  Future<void> updateUser(User user) async {
    await _db.updateUser(user);
    await loadUsers();
    // If the updated user is the current logged-in user, refresh _currentUser
    if (_currentUser?.id == user.id) {
      _currentUser = user;
    }
  }

  Future<void> deleteUser(int userId) async {
    await _db.deleteUser(userId);
    await loadUsers();
  }

  Future<void> loadShopInfo() async {
    _shopInfo = await _db.getShopInfo();
    notifyListeners();
  }

  Future<void> updateShopInfo(ShopInfo shopInfo) async {
    await _db.updateShopInfo(shopInfo);
    _shopInfo = shopInfo;
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
  Future<Map<String, dynamic>?> completeSale({double? amountPaid}) async {
    if (_cart.isEmpty || _currentUser == null) return null;
    if (_openCashSession == null) {
      _errorMessage = 'Aucune caisse ouverte.';
      notifyListeners();
      return null;
    }

    final customer = _selectedCustomer ?? Customer.walkin;
    List<CartItem> currentCart = List.from(_cart); // Create a copy of the cart

    try {
      final change = amountPaid != null ? amountPaid - cartTotal : null;
      final sale = Sale(
        date: DateTime.now(),
        userId: _currentUser!.id!,
        total: cartTotal,
        customerId: customer.id == 0 ? null : customer.id, // Store null for walk-in customer
        amountPaid: amountPaid,
        change: change,
        sessionId: _openCashSession!.id,
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

      final createdSaleId = await _db.createSale(sale, items);
      final fetchedSaleItems = await _db.getSaleItems(createdSaleId); // Fetch actual SaleItems with correct saleId
      final fullSale = await _db.getSaleById(createdSaleId); // Fetch the full Sale object

      _selectedCustomer = null; // Reset client
      clearCart();
      await loadSales();

      Customer? actualCustomer = customer.id == 0 ? null : await _db.getCustomerById(customer.id!);

      return {
        'sale': fullSale,
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

  Future<List<SaleWithItems>> getSalesWithItemsInDateRange(DateTime start, DateTime end) async {
    return await _db.getSalesWithItemsInDateRange(start, end);
  }

  Future<void> deleteSale(int saleId) async {
    await _db.deleteSale(saleId);
    await loadSales();
  }

  Future<void> deleteSalesInDateRange(DateTime startDate, DateTime endDate) async {
    await _db.deleteSalesInDateRange(startDate.toIso8601String(), endDate.toIso8601String());
    await loadSales();
  }

  // --- Data Clearing Methods ---

  Future<void> deleteAllSales() async {
    await _db.clearSalesHistory();
    await loadSales();
  }

  Future<void> clearCustomers() async {
    await _db.clearCustomers();
    await loadCustomers();
  }

  Future<void> clearProductsAndCategories() async {
    await _db.clearProductsAndCategories();
  }
}
