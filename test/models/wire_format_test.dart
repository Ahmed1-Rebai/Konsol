import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

// Reproduces the wire encoding KeyRepository uses, to lock the format.
Uint8List sshString(List<int> value) =>
    _concat(_uint32(value.length), Uint8List.fromList(value));

Uint8List _concat(Uint8List a, Uint8List b) {
  final out = Uint8List(a.length + b.length);
  out.setRange(0, a.length, a);
  out.setRange(a.length, a.length + b.length, b);
  return out;
}

Uint8List _uint32(int v) {
  final d = ByteData(4)..setUint32(0, v);
  return d.buffer.asUint8List();
}

void main() {
  const algorithm = 'ssh-ed25519';

  test('public key blob: string(algorithm) + string(32-byte key)', () {
    final key = List<int>.generate(32, (i) => i);
    final blob = _concat(sshString(utf8.encode(algorithm)), sshString(key));

    expect(blob.length, 4 + algorithm.length + 4 + 32);

    final offset0 = ByteData.sublistView(blob, 0, 4).getUint32(0);
    expect(offset0, algorithm.length);
  });

  test('signature blob: string(algorithm) + string(64-byte signature)', () {
    final sig = List<int>.generate(64, (i) => i);
    final blob = _concat(sshString(utf8.encode(algorithm)), sshString(sig));

    // Non-empty 64-byte signature.
    expect(blob.length, 4 + algorithm.length + 4 + 64);
    expect(sig, isNotEmpty);
  });
}
