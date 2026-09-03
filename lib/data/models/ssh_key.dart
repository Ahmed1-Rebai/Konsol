import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class SSHKey extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String keyType; // 'ed25519' or 'rsa'

  @HiveField(3)
  String publicKey;

  @HiveField(4)
  DateTime createdAt;

  SSHKey({
    required this.id,
    required this.name,
    required this.keyType,
    required this.publicKey,
    required this.createdAt,
  });

  SSHKey copyWith({
    String? name,
    String? keyType,
    String? publicKey,
    DateTime? createdAt,
  }) {
    return SSHKey(
      id: id,
      name: name ?? this.name,
      keyType: keyType ?? this.keyType,
      publicKey: publicKey ?? this.publicKey,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
