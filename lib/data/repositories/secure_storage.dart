import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Passwords
  Future<void> savePassword(String hostId, String password) async {
    await _storage.write(key: 'host_password_$hostId', value: password);
  }

  Future<String?> getPassword(String hostId) async {
    return await _storage.read(key: 'host_password_$hostId');
  }

  Future<void> deletePassword(String hostId) async {
    await _storage.delete(key: 'host_password_$hostId');
  }

  // Private keys
  Future<void> savePrivateKey(String keyId, String privateKey) async {
    await _storage.write(key: 'ssh_private_key_$keyId', value: privateKey);
  }

  Future<String?> getPrivateKey(String keyId) async {
    return await _storage.read(key: 'ssh_private_key_$keyId');
  }

  Future<void> deletePrivateKey(String keyId) async {
    await _storage.delete(key: 'ssh_private_key_$keyId');
  }

  // Generic
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
