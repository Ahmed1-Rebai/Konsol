import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class Host extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String address;

  @HiveField(3)
  int port;

  @HiveField(4)
  String username;

  @HiveField(5)
  String authMethod; // 'password' or 'key'

  @HiveField(6)
  String? keyId;

  @HiveField(7)
  int colorIndex;

  @HiveField(8)
  DateTime? lastConnectedAt;

  @HiveField(9)
  bool isPinned;

  Host({
    required this.id,
    required this.name,
    required this.address,
    this.port = 22,
    required this.username,
    this.authMethod = 'password',
    this.keyId,
    this.colorIndex = 0,
    this.lastConnectedAt,
    this.isPinned = false,
  });

  Host copyWith({
    String? name,
    String? address,
    int? port,
    String? username,
    String? authMethod,
    String? keyId,
    int? colorIndex,
    DateTime? lastConnectedAt,
    bool? isPinned,
  }) {
    return Host(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      port: port ?? this.port,
      username: username ?? this.username,
      authMethod: authMethod ?? this.authMethod,
      keyId: keyId ?? this.keyId,
      colorIndex: colorIndex ?? this.colorIndex,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  String get displayAddress => port == 22 ? address : '$address:$port';

  Map<String, dynamic> toDisplayMap() {
    return {
      'name': name,
      'address': displayAddress,
      'username': username,
    };
  }
}
