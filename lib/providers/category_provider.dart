import 'package:flutter/material.dart';
import '../data/repositories/category_repository.dart';
import '../database.dart'; // For DatabaseHelper.instance
import '../models.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _categoryRepository;

  List<Category> _categories = [];
  bool _isLoading = false;

  CategoryProvider() : _categoryRepository = CategoryRepository(DatabaseHelper.instance) {
    loadCategories();
  }

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();
    _categories = await _categoryRepository.getCategories();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(Category category) async {
    await _categoryRepository.insertCategory(category);
    await loadCategories();
  }

  Future<void> updateCategory(Category category) async {
    await _categoryRepository.updateCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    await _categoryRepository.deleteCategory(id);
    await loadCategories();
    // Note: Products associated with this category might need to be handled.
    // This will be handled by ProductProvider reloading its data.
  }

  String getCategoryName(int categoryId) {
    final category = _categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => Category(name: 'Inconnu'),
    );
    return category.name;
  }
}
