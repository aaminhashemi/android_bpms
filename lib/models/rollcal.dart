import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class Rollcal extends HiveObject {
  @HiveField(0)
  String status;
  @HiveField(1)
  String jalali_date;
  @HiveField(2)
  String time;
  @HiveField(3)
  String type;
  @HiveField(4)
  String? description;
  @HiveField(5)
  bool synced;

  Rollcal(
      {required this.status,
      required this.jalali_date,
      required this.time,
      required this.type,
      required this.synced,
      required this.description});
}

class RollcalAdapter extends TypeAdapter<Rollcal> {
  @override
  Rollcal read(BinaryReader reader) {
    final status = reader.readString();
    final jalali_date = reader.readString();
    final time = reader.readString();
    final type = reader.readString();
    final description = reader.readString();
    final synced = reader.readBool();
    return Rollcal(
        status: status,
        jalali_date: jalali_date,
        time: time,
        type: type,
        synced: synced,
        description: description);
  }

  @override
  // TODO: implement typeId
  int get typeId => 0;

  @override
  void write(BinaryWriter writer, Rollcal rollcal) {
    writer.writeString(rollcal.status);
    writer.writeString(rollcal.jalali_date);
    writer.writeString(rollcal.time);
    writer.writeString(rollcal.type);
    writer.writeString(rollcal.description ?? '');
    writer.writeBool(rollcal.synced);
  }
}
