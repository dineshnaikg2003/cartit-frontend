import 'package:flutter/material.dart';
import '../core/network/api_constants.dart';
import '../core/network/api_service.dart';
import '../models/brand_model.dart';

class BrandProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<BrandModel> _brands = [];
  List<BrandModel> get brands => _brands;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchBrands() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.client.get(ApiConstants.brands);
      if (response.statusCode == 200 && response.data['success'] == true) {
        var list = response.data['data'] as List? ?? [];
        _brands = list.map((e) => BrandModel.fromJson(e)).toList();
      }
    } catch (e) {
      _errorMessage = 'Failed to load brands';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
