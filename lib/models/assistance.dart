import 'package:hive/hive.dart';

@HiveType(typeId: 8)
class Assistances extends HiveObject {
  @HiveField(0)
  String level;
  @HiveField(1)
  String price;
  @HiveField(2)
  String payment_period;
  @HiveField(3)
  String record_date;
  @HiveField(4)
  String? deposit_date;
  @HiveField(5)
  String? payment_date;
  @HiveField(6)
  bool synced;
  @HiveField(7)
  String status;

  @HiveField(5)
  Assistances({
    required this.level,
    required this.price,
    required this.payment_period,
    required this.record_date,
    this.deposit_date,
    this.payment_date,
    required this.synced,
    required this.status,
  });
}

class AssistanceAdapter extends TypeAdapter<Assistances> {
  @override
  Assistances read(BinaryReader reader) {
    final level = reader.readString();
    final price = reader.readString();
    final payment_period = reader.readString();
    final record_date = reader.readString();
    final deposit_date = reader.readString();
    final payment_date = reader.readString();
    final status = reader.readString();
    final synced = reader.readBool();
    return Assistances(
      level: level,
      price: price,
      payment_period: payment_period,
      record_date: record_date,
      deposit_date: deposit_date,
      payment_date: payment_date,
      synced: synced,
      status: status,
    );
  }

  @override
  // TODO: implement typeId
  int get typeId => 8;

  @override
  void write(BinaryWriter writer, Assistances assistances) {
    writer.writeString(assistances.level);
    writer.writeString(assistances.price);
    writer.writeString(assistances.payment_period);
    writer.writeString(assistances.record_date);
    writer.writeString(assistances.deposit_date??'');
    writer.writeString(assistances.payment_date ?? '');
    writer.writeBool(assistances.synced);
    writer.writeString(assistances.status);
  }
}
