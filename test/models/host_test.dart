import 'package:flutter_test/flutter_test.dart';
import 'package:konsol/data/models/host.dart';

void main() {
  group('Host', () {
    test('displayAddress omits port when default 22', () {
      final host = Host(
        id: 'a',
        name: 'web',
        address: '192.168.1.50',
        username: 'root',
      );
      expect(host.displayAddress, '192.168.1.50');
    });

    test('displayAddress includes custom port', () {
      final host = Host(
        id: 'a',
        name: 'custom',
        address: '10.0.0.2',
        port: 2222,
        username: 'ubuntu',
      );
      expect(host.displayAddress, '10.0.0.2:2222');
    });

    test('copyWith preserves id and overlays fields', () {
      final host = Host(
        id: 'x',
        name: 'a',
        address: '1.1.1.1',
        username: 'u',
      );
      final updated = host.copyWith(name: 'b', isPinned: true);
      expect(updated.id, 'x');
      expect(updated.name, 'b');
      expect(updated.address, '1.1.1.1');
      expect(updated.isPinned, true);
      expect(updated.port, 22);
    });
  });
}
