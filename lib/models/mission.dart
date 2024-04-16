import 'package:hive/hive.dart';

@HiveType(typeId: 5)
class Mission extends HiveObject {
  @HiveField(0)
  String jalali_request_date;
  @HiveField(1)
  String type;
  @HiveField(2)
  String level;
  @HiveField(3)
  String status;
  @HiveField(4)
  String start;
  @HiveField(5)
  String end;
  @HiveField(6)
  String origin;
  @HiveField(7)
  String destination;
  @HiveField(8)
  String reason;
  @HiveField(9)
  String? description;
  @HiveField(10)
  bool synced;

  Mission({
    required this.jalali_request_date,
    required this.type,
    required this.level,
    required this.status,
    required this.start,
    required this.end,
    required this.origin,
    required this.destination,
    required this.reason,
    this.description,
    required this.synced,
  });
}

class MissionAdapter extends TypeAdapter<Mission> {
  @override
  Mission read(BinaryReader reader) {
    final jalali_request_date = reader.readString();
    final type = reader.readString();
    final level = reader.readString();
    final status = reader.readString();
    final start = reader.readString();
    final end = reader.readString();
    final reason = reader.readString();
    final origin = reader.readString();
    final destination = reader.readString();
    final description = reader.readString();
    final synced = reader.readBool();
    return Mission(
      jalali_request_date: jalali_request_date,
      type: type,
      level: level,
      status: status,
      start: start,
      end: end,
      origin: origin,
      destination: destination,
      reason: reason,
      description: description,
      synced: synced,
    );
  }

  @override
  // TODO: implement typeId
  int get typeId => 5;

  @override
  void write(BinaryWriter writer, Mission mission) {
    writer.writeString(mission.jalali_request_date);
    writer.writeString(mission.type);
    writer.writeString(mission.level);
    writer.writeString(mission.status);
    writer.writeString(mission.start);
    writer.writeString(mission.end);
    writer.writeString(mission.origin);
    writer.writeString(mission.destination);
    writer.writeString(mission.reason);
    writer.writeString(mission.description ?? '');
    writer.writeBool(mission.synced);
  }
}
