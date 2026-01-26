import 'package:flutter/material.dart';
import 'database.dart';
import 'models.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoading = false;
  String? _errorMessage;

  // Products & Categories
  List<Product> _products = [];
  List<Category> _categories = [];
  
  final DatabaseHelper _db = DatabaseHelper.instance;

  // Getters
  User? get currentUser => _currentUser;
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Product> get products => _products;
  List<Category> get categories => _categories;
  
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isCashier => _currentUser?.isCashier ?? false;

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

  // Load data
  Future<void> _loadData() async {
    await loadCategories();
    await loadProducts();
  }

  // Logout
  void logout() {
    _currentUser = null;
    _errorMessage = null;
    _products = [];
    _categories = [];
    notifyListeners();
  }

  // Toggle theme
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
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
    await loadProducts(); // Reload products in case some were affected
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
  
  @override
  void dispose() {
    super.dispose();
  }
}