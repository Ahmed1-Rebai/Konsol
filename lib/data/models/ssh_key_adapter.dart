import 'package:hive/hive.dart';
import 'ssh_key.dart';

class SSHKeyAdapter extends TypeAdapter<SSHKey> {
  @override
  final int typeId = 1;

  @override
  SSHKey read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return SSHKey(
      id: fields[0] as String,
      name: fields[1] as String,
      keyType: fields[2] as String,
      publicKey: fields[3] as String,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SSHKey obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.keyType)
      ..writeByte(3)
      ..write(obj.publicKey)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SSHKeyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
