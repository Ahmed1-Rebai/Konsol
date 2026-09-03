import 'package:hive/hive.dart';
import 'host.dart';

class HostAdapter extends TypeAdapter<Host> {
  @override
  final int typeId = 0;

  @override
  Host read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Host(
      id: fields[0] as String,
      name: fields[1] as String,
      address: fields[2] as String,
      port: fields[3] as int,
      username: fields[4] as String,
      authMethod: fields[5] as String,
      keyId: fields[6] as String?,
      colorIndex: fields[7] as int,
      lastConnectedAt: fields[8] as DateTime?,
      isPinned: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Host obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.port)
      ..writeByte(4)
      ..write(obj.username)
      ..writeByte(5)
      ..write(obj.authMethod)
      ..writeByte(6)
      ..write(obj.keyId)
      ..writeByte(7)
      ..write(obj.colorIndex)
      ..writeByte(8)
      ..write(obj.lastConnectedAt)
      ..writeByte(9)
      ..write(obj.isPinned);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HostAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
