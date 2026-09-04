import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:konsol/data/models/host.dart';
import 'package:konsol/data/models/ssh_key.dart';
import 'package:konsol/data/repositories/host_repository.dart';
import 'package:konsol/data/repositories/key_repository.dart';
import 'package:konsol/data/repositories/secure_storage.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final hostRepositoryProvider = Provider<HostRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final keyRepositoryProvider = Provider<KeyRepository>((ref) {
  final secure = ref.watch(secureStorageProvider);
  return KeyRepository(secure);
});

final hostsProvider = StateNotifierProvider<HostsNotifier, List<Host>>((ref) {
  final repo = ref.watch(hostRepositoryProvider);
  return HostsNotifier(repo);
});

class HostsNotifier extends StateNotifier<List<Host>> {
  final HostRepository _repo;

  HostsNotifier(this._repo) : super([]) {
    _load();
  }

  void _load() {
    state = _repo.getAll();
  }

  Future<String> addHost({
    required String name,
    required String address,
    int port = 22,
    required String username,
    String authMethod = 'password',
    String? keyId,
    int colorIndex = 0,
  }) async {
    final id = await _repo.create(
      name: name,
      address: address,
      port: port,
      username: username,
      authMethod: authMethod,
      keyId: keyId,
      colorIndex: colorIndex,
    );
    _load();
    return id;
  }

  Future<void> updateHost(Host host) async {
    await _repo.update(host);
    _load();
  }

  Future<void> deleteHost(String id) async {
    await _repo.delete(id);
    _load();
  }

  Future<void> togglePin(String id) async {
    await _repo.togglePin(id);
    _load();
  }

  Future<void> updateLastConnected(String id) async {
    await _repo.updateLastConnected(id);
    _load();
  }

  void refresh() => _load();
}

// Settings
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, Map<String, dynamic>>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  SettingsNotifier() : super({}) {
    _load();
  }

  void _load() {
    final box = Hive.box('settings');
    state = {
      'themeMode': box.get('themeMode', defaultValue: 'dark'),
      'defaultFontSize': box.get('defaultFontSize', defaultValue: 14.0),
      'terminalColorScheme':
          box.get('terminalColorScheme', defaultValue: 'default'),
      'welcomeBanner': box.get('welcomeBanner', defaultValue: true),
    };
  }

  Future<void> updateSetting(String key, dynamic value) async {
    final box = Hive.box('settings');
    await box.put(key, value);
    _load();
  }
}

// Keys
final keysProvider = StateNotifierProvider<KeysNotifier, List<SSHKey>>((ref) {
  final repo = ref.watch(keyRepositoryProvider);
  return KeysNotifier(repo);
});

class KeysNotifier extends StateNotifier<List<SSHKey>> {
  final KeyRepository _repo;

  KeysNotifier(this._repo) : super([]) {
    _load();
  }

  void _load() {
    final repoKeys = _repo.getAll();
    repoKeys.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );
    state = repoKeys;
  }

  Future<SSHKey> generateEd25519({String? name}) async {
    final key = await _repo.generateEd25519(name: name);
    _load();
    return key;
  }

  Future<SSHKey> importFromPem(String pem, {String? name}) async {
    final key = await _repo.importFromPem(pem, name: name);
    _load();
    return key;
  }

  Future<void> rename(String id, String newName) async {
    await _repo.rename(id, newName);
    _load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _load();
  }
}
