import 'package:hive/hive.dart';
import 'package:konsol/data/models/host.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
const String _boxName = 'hosts';

class HostRepository {
  late Box<Host> _box;

  Future<void> init() async {
    _box = await Hive.openBox<Host>(_boxName);
  }

  List<Host> getAll() {
    final hosts = _box.values.toList();
    hosts.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return (b.lastConnectedAt ?? DateTime(0))
          .compareTo(a.lastConnectedAt ?? DateTime(0));
    });
    return hosts;
  }

  Host? getById(String id) {
    try {
      return _box.values.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<String> create({
    required String name,
    required String address,
    int port = 22,
    required String username,
    String authMethod = 'password',
    String? keyId,
    int colorIndex = 0,
  }) async {
    final id = _uuid.v4();
    final host = Host(
      id: id,
      name: name,
      address: address,
      port: port,
      username: username,
      authMethod: authMethod,
      keyId: keyId,
      colorIndex: colorIndex,
    );
    await _box.put(id, host);
    return id;
  }

  Future<void> update(Host host) async {
    await _box.put(host.id, host);
  }

  Future<void> updateLastConnected(String id) async {
    final host = getById(id);
    if (host != null) {
      host.lastConnectedAt = DateTime.now();
      await _box.put(id, host);
    }
  }

  Future<void> togglePin(String id) async {
    final host = getById(id);
    if (host != null) {
      host.isPinned = !host.isPinned;
      await _box.put(id, host);
    }
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
