import 'package:flutter/material.dart';
import '../core/network/api_constants.dart';
import '../core/network/api_service.dart';
import '../core/network/network_error_helper.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/auth_models.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SecureStorageService _storage = SecureStorageService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  bool _isNewUser = false;
  bool get isNewUser => _isNewUser;

  String? _currentPhone;
  String? get currentPhone => _currentPhone;

  String? _currentName;
  String? get currentName => _currentName;

  Future<void> checkAuthStatus() async {
    final token = await _storage.getToken();
    _isLoggedIn = token != null && token.isNotEmpty;
    _currentPhone = await _storage.getUserPhone();
    _currentName = await _storage.getUserName();
    notifyListeners();
  }

  Future<void> updateProfile({required String name}) async {
    _currentName = name;
    if (_currentPhone != null) {
      await _storage.saveUserInfo(phone: _currentPhone!, name: name);
    }
    notifyListeners();
  }

  Future<bool> sendOtp(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Check if phone exists (to determine if new user)
      try {
        final checkRes = await _apiService.client.post(
          ApiConstants.checkPhone,
          data: SendOtpRequest(phone: phone).toJson(),
        );
        if (checkRes.statusCode == 200 && checkRes.data['data'] != null) {
          _isNewUser = !(checkRes.data['data'] as bool);
        }
      } catch (_) {
        _isNewUser = true; // Fallback
      }

      // 2. Send OTP
      final response = await _apiService.client.post(
        ApiConstants.sendOtp,
        data: SendOtpRequest(phone: phone).toJson(),
      );

      _isLoading = false;
      if (response.statusCode == 200 && response.data['success'] == true) {
        _currentPhone = phone;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.data['message'] ?? 'Failed to send OTP';
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

  Future<bool> verifyOtp(String phone, String otp, {String? name, String? email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.client.post(
        ApiConstants.verifyOtp,
        data: VerifyOtpRequest(
          phone: phone,
          otp: otp,
          name: name,
          email: email,
        ).toJson(),
      );

      _isLoading = false;
      if (response.statusCode == 200 && response.data['success'] == true) {
        final authData = AuthResponse.fromJson(response.data['data']);
        await _storage.saveToken(authData.token);
        final userName = authData.user?.name ?? name;
        await _storage.saveUserInfo(
          phone: phone,
          name: userName,
        );
        _currentPhone = phone;
        _currentName = userName;
        _isLoggedIn = true;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.data['message'] ?? 'Invalid OTP';
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

  Future<void> logout() async {
    await _storage.clearAll();
    _isLoggedIn = false;
    _currentPhone = null;
    _isNewUser = false;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    return NetworkErrorHelper.parseError(e);
  }
}
