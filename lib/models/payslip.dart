import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class Payslip extends HiveObject {
  @HiveField(0)
  late int id;
  @HiveField(1)
  String payment_period;
  @HiveField(2)
  String price;
  @HiveField(3)
  String level;
  @HiveField(4)
  String payment_date;

  @HiveField(5)
  Payslip({
    required this.id,
    required this.payment_period,
    required this.price,
    required this.level,
    required this.payment_date,
  });
}

class PayslipAdapter extends TypeAdapter<Payslip> {
  @override
  Payslip read(BinaryReader reader) {
    final id = reader.readInt();
    final payment_period = reader.readString();
    final price = reader.readString();
    final level = reader.readString();
    final payment_date = reader.readString();
    return Payslip(
      id: id,
      payment_period: payment_period,
      price: price,
      level: level,
      payment_date: payment_date,
    );
  }

  @override
  // TODO: implement typeId
  int get typeId => 2;

  @override
  void write(BinaryWriter writer, Payslip payslip) {
    writer.writeInt(payslip.id);
    writer.writeString(payslip.payment_period);
    writer.writeString(payslip.price);
    writer.writeString(payslip.level);
    writer.writeString(payslip.payment_date);
  }
}
