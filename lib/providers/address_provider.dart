import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/network/api_constants.dart';
import '../core/network/api_service.dart';
import '../models/address_model.dart';

class AddressProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<AddressModel> _addresses = [];
  List<AddressModel> get addresses => _addresses;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AddressModel? get defaultAddress {
    if (_addresses.isEmpty) return null;
    return _addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => _addresses.first,
    );
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchAddresses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.client.get(ApiConstants.addresses);
      if (response.statusCode == 200 && response.data['success'] == true) {
        var list = response.data['data'] as List? ?? [];
        _addresses = list.map((e) => AddressModel.fromJson(e)).toList();
      }
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAddress(AddressModel address) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.client.post(
        ApiConstants.addresses,
        data: address.toJson(),
      );

      _isLoading = false;
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchAddresses();
        return true;
      } else {
        _errorMessage = response.data['message'] ?? 'Failed to save address';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAddress(AddressModel address) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.client.put(
        '${ApiConstants.addresses}/${address.id}',
        data: address.toJson(),
      );

      _isLoading = false;
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchAddresses();
        return true;
      } else {
        _errorMessage = response.data['message'] ?? 'Failed to update address';
        notifyListeners();
        return false;
      }
    } catch (e) {
      final index = _addresses.indexWhere((a) => a.id == address.id);
      if (index != -1) {
        _addresses[index] = address;
      } else {
        _addresses.add(address);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  Future<void> setDefaultAddress(int addressId) async {
    try {
      await _apiService.client.patch('${ApiConstants.addresses}/$addressId/default');
      await fetchAddresses();
    } catch (_) {}
  }

  Future<void> deleteAddress(int addressId) async {
    try {
      await _apiService.client.delete('${ApiConstants.addresses}/$addressId');
      _addresses.removeWhere((a) => a.id == addressId);
      notifyListeners();
    } catch (_) {}
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      if (e.response?.data != null && e.response?.data is Map) {
        return e.response?.data['message'] ?? 'Failed to save address';
      }
      return e.message ?? 'Network error';
    }
    return e.toString();
  }
}
