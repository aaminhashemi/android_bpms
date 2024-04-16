import 'package:hive/hive.dart';

@HiveType(typeId: 4)
class Leaving extends HiveObject {
  @HiveField(0)
  String jalali_request_date;
  @HiveField(1)
  String period;
  @HiveField(2)
  String status;
  @HiveField(3)
  String level;
  @HiveField(4)
  String type;
  @HiveField(5)
  String start;
  @HiveField(6)
  String end;
  @HiveField(7)
  String reason;
  @HiveField(8)
  String? description;
  @HiveField(9)
  bool synced;

  Leaving({
    required this.jalali_request_date,
    required this.period,
    required this.status,
    required this.level,
    required this.type,
    required this.start,
    required this.end,
    required this.reason,
    this.description,
    required this.synced,
  });
}

class LeavingAdapter extends TypeAdapter<Leaving> {
  @override
  Leaving read(BinaryReader reader) {
    final jalali_request_date = reader.readString();
    final period = reader.readString();
    final status = reader.readString();
    final level = reader.readString();
    final type = reader.readString();
    final start = reader.readString();
    final end = reader.readString();
    final reason = reader.readString();
    final description = reader.readString();
    final synced = reader.readBool();
    return Leaving(
      jalali_request_date: jalali_request_date,
      period: period,
      status: status,
      level: level,
      type: type,
      start: start,
      end: end,
      reason: reason,
      description: description,
      synced: synced,
    );
  }

  @override
  // TODO: implement typeId
  int get typeId => 4;

  @override
  void write(BinaryWriter writer, Leaving leaving) {
    writer.writeString(leaving.jalali_request_date);
    writer.writeString(leaving.period);
    writer.writeString(leaving.status);
    writer.writeString(leaving.level);
    writer.writeString(leaving.type);
    writer.writeString(leaving.start);
    writer.writeString(leaving.end);
    writer.writeString(leaving.reason);
    writer.writeString(leaving.description ?? '');
    writer.writeBool(leaving.synced);
  }
}
