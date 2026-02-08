import 'package:flutter/material.dart';
import '../data/repositories/product_repository.dart';
import '../database.dart';
import '../models.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _productRepository;

  List<Product> _products = [];
  bool _isLoading = false;

  ProductProvider() : _productRepository = ProductRepository(DatabaseHelper.instance) {
    loadProducts();
  }

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    _products = await _productRepository.getProducts();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    await _productRepository.insertProduct(product);
    await loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    await _productRepository.updateProduct(product);
    await loadProducts();
  }

  Future<void> deleteProduct(int id) async {
    await _productRepository.deleteProduct(id);
    await loadProducts();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    return await _productRepository.getProductByBarcode(barcode);
  }
}
