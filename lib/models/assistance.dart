import 'package:hive/hive.dart';

@HiveType(typeId: 3)
class Assistance extends HiveObject {
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

  @HiveField(5)
  Assistance({
    required this.level,
    required this.price,
    required this.payment_period,
    required this.record_date,
    this.deposit_date,
    this.payment_date,
    required this.synced,
  });
}

class AssistanceAdapter extends TypeAdapter<Assistance> {
  @override
  Assistance read(BinaryReader reader) {
    final level = reader.readString();
    final price = reader.readString();
    final payment_period = reader.readString();
    final record_date = reader.readString();
    final deposit_date = reader.readString();
    final payment_date = reader.readString();
    final synced = reader.readBool();
    return Assistance(
      level: level,
      price: price,
      payment_period: payment_period,
      record_date: record_date,
      deposit_date: deposit_date,
      payment_date: payment_date,
      synced: synced,
    );
  }

  @override
  // TODO: implement typeId
  int get typeId => 3;

  @override
  void write(BinaryWriter writer, Assistance assistance) {
    writer.writeString(assistance.level);
    writer.writeString(assistance.price);
    writer.writeString(assistance.payment_period);
    writer.writeString(assistance.record_date);
    writer.writeString(assistance.deposit_date??'');
    writer.writeString(assistance.payment_date ?? '');
    writer.writeBool(assistance.synced);
  }
}
