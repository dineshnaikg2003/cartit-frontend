import 'package:flutter/material.dart';
import '../core/network/api_constants.dart';
import '../core/network/api_service.dart';
import '../models/category_model.dart';

class CategoryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => _categories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.client.get(ApiConstants.categories);
      if (response.statusCode == 200 && response.data['success'] == true) {
        var list = response.data['data'] as List? ?? [];
        _categories = list.map((e) => CategoryModel.fromJson(e)).toList();
      }
    } catch (e) {
      _errorMessage = 'Failed to load categories';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
