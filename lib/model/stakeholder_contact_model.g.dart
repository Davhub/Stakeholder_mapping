// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stakeholder_contact_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StakeholderAdapter extends TypeAdapter<Stakeholder> {
  @override
  final int typeId = 0;

  @override
  Stakeholder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Stakeholder(
      fullName: fields[0] as String,
      phoneNumber: fields[1] as String,
      whatsappNumber: fields[2] as String,
      email: fields[3] as String,
      association: fields[4] as String,
      levelOfAdministration: fields[5] as String,
      country: fields[6] as String,
      state: fields[7] as String,
      lg: fields[8] as String,
      ward: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Stakeholder obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.fullName)
      ..writeByte(1)
      ..write(obj.phoneNumber)
      ..writeByte(2)
      ..write(obj.whatsappNumber)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.association)
      ..writeByte(5)
      ..write(obj.levelOfAdministration)
      ..writeByte(6)
      ..write(obj.country)
      ..writeByte(7)
      ..write(obj.state)
      ..writeByte(8)
      ..write(obj.lg)
      ..writeByte(9)
      ..write(obj.ward);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StakeholderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
