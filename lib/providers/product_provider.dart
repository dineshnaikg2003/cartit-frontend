import 'package:flutter/material.dart';

import '../core/network/api_constants.dart';
import '../core/network/api_service.dart';
import '../models/product_model.dart';

enum ProductSort {
  recommended,
  priceLowToHigh,
  priceHighToLow,
  nameAToZ,
  nameZToA,
  newest,
}

class ProductProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // =========================================================
  // PRODUCTS
  // =========================================================

  List<ProductModel> _products = [];

  List<ProductModel> get products => _products;

  List<ProductModel> _featuredProducts = [];

  List<ProductModel> get featuredProducts =>
      _featuredProducts;

  ProductModel? _selectedProduct;

  ProductModel? get selectedProduct =>
      _selectedProduct;

  // =========================================================
  // LOADING / ERROR
  // =========================================================

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  bool _isDetailLoading = false;

  bool get isDetailLoading =>
      _isDetailLoading;

  String? _errorMessage;

  String? get errorMessage =>
      _errorMessage;

  // =========================================================
  // FILTER STATE
  // =========================================================

  String _searchQuery = '';

  int? _selectedCategoryId;

  int? _selectedBrandId;

  ProductSort _selectedSort =
      ProductSort.recommended;

  String get searchQuery =>
      _searchQuery;

  int? get selectedCategoryId =>
      _selectedCategoryId;

  int? get selectedBrandId =>
      _selectedBrandId;

  ProductSort get selectedSort =>
      _selectedSort;

  // =========================================================
  // FETCH FEATURED PRODUCTS
  // =========================================================

  Future<void> fetchFeaturedProducts() async {
    try {
      final response =
          await _apiService.client.get(
        ApiConstants.featuredProducts,
      );

      if (response.statusCode == 200 &&
          response.data['success'] == true) {
        final data =
            response.data['data'];

        List<dynamic> rawList = [];

        if (data is Map &&
            data['content'] is List) {
          rawList = data['content'];
        } else if (data is List) {
          rawList = data;
        }

        _featuredProducts = rawList
            .map(
              (item) =>
                  ProductModel.fromJson(
                Map<String, dynamic>.from(
                  item,
                ),
              ),
            )
            // Customer app must never show
            // inactive featured products.
            .where(
              (product) =>
                  product.active,
            )
            .toList();

        _applyFeaturedSort();

        notifyListeners();
      }
    } catch (e) {
      _featuredProducts = [];
      notifyListeners();
    }
  }

  // =========================================================
  // FETCH PRODUCTS
  // =========================================================

  Future<void> fetchProducts({
    String? query,
    int? categoryId,
    int? brandId,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    // Update only when explicitly supplied.
    if (query != null) {
      _searchQuery =
          query.trim();
    }

    if (categoryId != null) {
      _selectedCategoryId =
          categoryId;
    }

    if (brandId != null) {
      _selectedBrandId =
          brandId;
    }

    notifyListeners();

    try {
      final queryParams =
          <String, dynamic>{
        // IMPORTANT:
        // Customer app requests active products only.
        'active': true,
      };

      // Backend search parameter.
      if (_searchQuery.isNotEmpty) {
        queryParams['keyword'] =
            _searchQuery;
      }

      if (_selectedCategoryId != null) {
        queryParams['categoryId'] =
            _selectedCategoryId;
      }

      if (_selectedBrandId != null) {
        queryParams['brandId'] =
            _selectedBrandId;
      }

      final response =
          await _apiService.client.get(
        ApiConstants.products,
        queryParameters:
            queryParams,
      );

      if (response.statusCode == 200 &&
          response.data['success'] == true) {
        final data =
            response.data['data'];

        List<dynamic> rawList = [];

        // Paginated response
        if (data is Map &&
            data['content'] is List) {
          rawList = data['content'];
        }

        // Normal list response
        else if (data is List) {
          rawList = data;
        }

        _products = rawList
            .map(
              (item) =>
                  ProductModel.fromJson(
                Map<String, dynamic>.from(
                  item,
                ),
              ),
            )
            // Defensive customer-side check.
            .where(
              (product) =>
                  product.active,
            )
            .toList();

        _applyCurrentSort();
      } else {
        _products = [];

        _errorMessage =
            response.data['message'] ??
                'Failed to load products';
      }
    } catch (e) {
      _products = [];

      _errorMessage =
          'Failed to load products';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // FETCH SINGLE PRODUCT
  // =========================================================

  Future<ProductModel?> fetchProductById(
    int productId,
  ) async {
    _isDetailLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final response =
          await _apiService.client.get(
        ApiConstants.productById(
          productId,
        ),
      );

      if (response.statusCode == 200 &&
          response.data['success'] == true) {
        final data =
            response.data['data'];

        if (data is Map) {
          final product =
              ProductModel.fromJson(
            Map<String, dynamic>.from(
              data,
            ),
          );

          _selectedProduct =
              product;

          return product;
        }
      }

      _errorMessage =
          response.data['message'] ??
              'Failed to load product';

      return null;
    } catch (e) {
      _errorMessage =
          'Failed to load product';

      return null;
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  void clearSelectedProduct() {
    _selectedProduct = null;
    notifyListeners();
  }

  // =========================================================
  // SEARCH
  // =========================================================

  void setSearchQuery(
    String query,
  ) {
    _searchQuery =
        query.trim();

    fetchProducts();
  }

  // =========================================================
  // CATEGORY FILTER
  // =========================================================

  void filterByCategory(
    int categoryId,
  ) {
    _selectedCategoryId =
        categoryId;

    fetchProducts();
  }

  void clearCategoryFilter() {
    _selectedCategoryId = null;

    fetchProducts();
  }

  // =========================================================
  // BRAND FILTER
  // =========================================================

  void filterByBrand(
    int brandId,
  ) {
    _selectedBrandId =
        brandId;

    fetchProducts();
  }

  void clearBrandFilter() {
    _selectedBrandId = null;

    fetchProducts();
  }

  // =========================================================
  // CLEAR ALL FILTERS
  // =========================================================

  void clearFilters() {
    _searchQuery = '';
    _selectedCategoryId = null;
    _selectedBrandId = null;
    _selectedSort =
        ProductSort.recommended;

    fetchProducts();
  }

  // =========================================================
  // SORT
  // =========================================================

  void applySort(
    ProductSort sort,
  ) {
    _selectedSort = sort;

    _applyCurrentSort();

    notifyListeners();
  }

  void _applyCurrentSort() {
    switch (_selectedSort) {
      case ProductSort.recommended:
        // Preserve backend order.
        break;

      case ProductSort.priceLowToHigh:
        _products.sort(
          (a, b) =>
              a.effectivePrice.compareTo(
            b.effectivePrice,
          ),
        );
        break;

      case ProductSort.priceHighToLow:
        _products.sort(
          (a, b) =>
              b.effectivePrice.compareTo(
            a.effectivePrice,
          ),
        );
        break;

      case ProductSort.nameAToZ:
        _products.sort(
          (a, b) => a.name
              .toLowerCase()
              .compareTo(
                b.name.toLowerCase(),
              ),
        );
        break;

      case ProductSort.nameZToA:
        _products.sort(
          (a, b) => b.name
              .toLowerCase()
              .compareTo(
                a.name.toLowerCase(),
              ),
        );
        break;

      case ProductSort.newest:
        // Higher ID = newer product
        // based on the current backend model.
        _products.sort(
          (a, b) =>
              b.id.compareTo(a.id),
        );
        break;
    }
  }

  void _applyFeaturedSort() {
    if (_selectedSort ==
        ProductSort.recommended) {
      return;
    }

    _featuredProducts.sort(
      (a, b) {
        switch (_selectedSort) {
          case ProductSort.priceLowToHigh:
            return a.effectivePrice
                .compareTo(
              b.effectivePrice,
            );

          case ProductSort.priceHighToLow:
            return b.effectivePrice
                .compareTo(
              a.effectivePrice,
            );

          case ProductSort.nameAToZ:
            return a.name
                .toLowerCase()
                .compareTo(
                  b.name.toLowerCase(),
                );

          case ProductSort.nameZToA:
            return b.name
                .toLowerCase()
                .compareTo(
                  a.name.toLowerCase(),
                );

          case ProductSort.newest:
            return b.id.compareTo(
              a.id,
            );

          case ProductSort.recommended:
            return 0;
        }
      },
    );
  }
}