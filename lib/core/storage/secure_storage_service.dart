import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyToken = 'auth_token';
  static const String _keyUserPhone = 'user_phone';
  static const String _keyUserName = 'user_name';
  static const String _keyUserId = 'user_id';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> saveUserInfo({
    required String phone,
    String? name,
    String? id,
  }) async {
    await _storage.write(key: _keyUserPhone, value: phone);
    if (name != null) await _storage.write(key: _keyUserName, value: name);
    if (id != null) await _storage.write(key: _keyUserId, value: id);
  }

  Future<String?> getUserPhone() async {
    return await _storage.read(key: _keyUserPhone);
  }

  Future<String?> getUserName() async {
    return await _storage.read(key: _keyUserName);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
