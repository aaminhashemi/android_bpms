import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class Rollcal extends HiveObject {

  @HiveField(0)
  late int id;
  @HiveField(1)
  String status;
  @HiveField(2)
  String date;
  @HiveField(3)
  String time;
  @HiveField(4)
  String type;
  @HiveField(5)
  String description;
  @HiveField(6)
  bool synced;

  Rollcal({
      required this.id,
      required this.status,
      required this.date,
      required this.time,
      required this.type,
      required this.synced,
      required this.description
  });
}

class RollcalAdapter extends TypeAdapter<Rollcal> {
  @override
  Rollcal read(BinaryReader reader) {
    final id = reader.readInt();
    final status = reader.readString();
    final date = reader.readString();
    final time = reader.readString();
    final type = reader.readString();
    final description = reader.readString();
    final synced = reader.readBool();
    return Rollcal(
        id: id,
        status: status,
        date: date,
        time: time,
        type: type,
        synced: synced,
        description: description
    );
  }

  @override
  // TODO: implement typeId
  int get typeId => 0;

  @override
  void write(BinaryWriter writer, Rollcal rollcal) {
    writer.writeInt(rollcal.id);
    writer.writeString(rollcal.status);
    writer.writeString(rollcal.date);
    writer.writeString(rollcal.time);
    writer.writeString(rollcal.type);
    writer.writeString(rollcal.description);
    writer.writeBool(rollcal.synced);
  }

}
