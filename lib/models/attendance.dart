import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class Attendance extends HiveObject {
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

  Attendance(
      {required this.status,
      required this.jalali_date,
      required this.time,
      required this.type,
      required this.synced,
      this.description});
}

class AttendanceAdapter extends TypeAdapter<Attendance> {
  @override
  Attendance read(BinaryReader reader) {
    final status = reader.readString();
    final jalali_date = reader.readString();
    final time = reader.readString();
    final type = reader.readString();
    final description = reader.readString();
    final synced = reader.readBool();
    return Attendance(
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
  void write(BinaryWriter writer, Attendance attendance) {
    writer.writeString(attendance.status);
    writer.writeString(attendance.jalali_date);
    writer.writeString(attendance.time);
    writer.writeString(attendance.type);
    writer.writeString(attendance.description ?? '');
    writer.writeBool(attendance.synced);
  }
}
