import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:hive/hive.dart';
import 'package:konsol/data/models/ssh_key.dart';
import 'package:konsol/data/repositories/secure_storage.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
const String _boxName = 'ssh_keys';

/// Metadata + public key management for SSH keys.
///
/// Private keys are NEVER stored in Hive — only in [SecureStorageService].
/// For generated ed25519 keys we keep the raw seed so [identityFor] can
/// rebuild a signing identity without ever writing it to disk in plaintext.
class KeyRepository {
  late Box<SSHKey> _box;
  final SecureStorageService _secure;

  KeyRepository(this._secure);

  Future<void> init() async {
    _box = await Hive.openBox<SSHKey>(_boxName);
  }

  List<SSHKey> getAll() => _box.values.toList();

  SSHKey? getById(String id) {
    try {
      return _box.values.firstWhere((k) => k.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Generate a fresh ed25519 key pair.
  Future<SSHKey> generateEd25519({String? name}) async {
    final algorithm = Ed25519();
    final pair = await algorithm.newKeyPair();
    final extracted = await pair.extract();
    final public = await extracted.extractPublicKey();

    final id = _uuid.v4();
    final keyName = name ?? 'Key ${_box.length + 1}';

    final sshKey = SSHKey(
      id: id,
      name: keyName,
      keyType: 'ed25519',
      publicKey: 'ssh-ed25519 ${base64Encode(public.bytes)}',
      createdAt: DateTime.now(),
    );

    await _secure.savePrivateKey(
      id,
      jsonEncode({
        'kind': 'ed25519-raw',
        'secret': base64Encode(Uint8List.fromList(extracted.bytes)),
      }),
    );
    await _box.put(id, sshKey);
    return sshKey;
  }

  /// Import an existing PEM private key (OpenSSH, PKCS#1 RSA, or SEC1 EC).
  Future<SSHKey> importFromPem(String pem, {String? name}) async {
    final pairs = SSHKeyPair.fromPem(pem);
    if (pairs.isEmpty) {
      throw const FormatException('Could not parse the private key.');
    }
    final pair = pairs.first;
    final pub = pair.toPublicKey();
    // The wire blob already embeds the type as the first SSH string, so the
    // standard "ssh-xxx AAAA..." form is prefix-type + base64(whole blob).
    final publicKeyString = '${pair.name} ${base64Encode(pub.encode())}';

    final id = _uuid.v4();
    final keyName = name ?? 'Imported Key';

    final sshKey = SSHKey(
      id: id,
      name: keyName,
      keyType: _keyTypeLabel(pair),
      publicKey: publicKeyString,
      createdAt: DateTime.now(),
    );

    await _secure.savePrivateKey(
      id,
      jsonEncode({'kind': 'pem', 'pem': pem}),
    );
    await _box.put(id, sshKey);
    return sshKey;
  }

  Future<void> rename(String id, String newName) async {
    final key = getById(id);
    if (key != null) {
      key.name = newName;
      await _box.put(id, key);
    }
  }

  Future<void> delete(String id) async {
    await _secure.deletePrivateKey(id);
    await _box.delete(id);
  }

  /// Build an [SSHIdentity] for a stored key to use during authentication.
  Future<SSHIdentity> identityFor(String keyId) async {
    final key = getById(keyId);
    if (key == null) {
      throw StateError('SSH key not found.');
    }
    final stored = await _secure.getPrivateKey(keyId);
    if (stored == null) {
      throw StateError('No private key material for this SSH key.');
    }

    final map = jsonDecode(stored) as Map<String, dynamic>;
    final kind = map['kind'] as String;

    if (kind == 'ed25519-raw') {
      final seed = base64Decode(map['secret'] as String);
      final algorithm = Ed25519();
      final keyPair = await algorithm.newKeyPairFromSeed(
        Uint8List.fromList(seed),
      );

      final publicParts = key.publicKey.split(' ');
      final publicBlob = publicParts.length == 2
          ? _publicKeyBlob('ssh-ed25519', base64Decode(publicParts[1]))
          : _publicKeyBlob('ssh-ed25519', (await keyPair.extractPublicKey()).bytes);

      return SSHIdentity.custom(
        type: 'ssh-ed25519',
        publicKey: SSHRawHostKey(Uint8List.fromList(publicBlob)),
        signer: (data) async {
          final signature = await algorithm.sign(
            Uint8List.fromList(data),
            keyPair: keyPair,
          );
          final sigBlob = _signatureBlob(
            'ssh-ed25519',
            Uint8List.fromList(signature.bytes),
          );
          return SSHRawSignature(Uint8List.fromList(sigBlob));
        },
        comment: key.name,
      );
    }

    // PEM-backed key: dartssh2 parses it into a ready SSHIdentity.
    final pem = map['pem'] as String;
    final pairs = SSHKeyPair.fromPem(pem);
    if (pairs.isEmpty) {
      throw StateError('Could not parse stored private key.');
    }
    return pairs.first;
  }

  // --- wire encoding helpers (SSH "string" format) ---

  Uint8List _publicKeyBlob(String type, List<int> keyBytes) {
    final b = BytesBuilder();
    _putString(b, utf8.encode(type));
    _putString(b, keyBytes);
    return b.toBytes();
  }

  Uint8List _signatureBlob(String algorithm, List<int> sigBytes) {
    final b = BytesBuilder();
    _putString(b, utf8.encode(algorithm));
    _putString(b, sigBytes);
    return b.toBytes();
  }

  void _putString(BytesBuilder b, List<int> bytes) {
    b.add(_uint32(bytes.length));
    b.add(bytes);
  }

  Uint8List _uint32(int value) {
    final r = ByteData(4)..setUint32(0, value);
    return r.buffer.asUint8List();
  }

  String _keyTypeLabel(SSHKeyPair pair) => pair.type.startsWith('rsa')
      ? 'rsa'
      : pair.type.contains('ed25519')
          ? 'ed25519'
          : pair.type;
}
