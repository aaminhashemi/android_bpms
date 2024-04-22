import 'package:hive/hive.dart';

@HiveType(typeId: 6)
class Loan extends HiveObject {
  @HiveField(0)
  String jalali_request_date;
  @HiveField(1)
  String suggested_value;
  @HiveField(2)
  String? formatted_requested_value;
  @HiveField(3)
  String level;
  @HiveField(4)
  String status;
  @HiveField(5)
  String? suggested_repayment_count;
  @HiveField(6)
  String? repayment_count;
  @HiveField(7)
  String? formatted_repayment_value;
  @HiveField(8)
  String? formatted_residue_value;
  @HiveField(9)
  String description;
  @HiveField(10)
  bool synced;

  Loan({
    required this.jalali_request_date,
    required this.suggested_value,
    this.formatted_requested_value,
    required this.level,
    required this.status,
    this.suggested_repayment_count,
    this.repayment_count,
    this.formatted_repayment_value,
    this.formatted_residue_value,
    required this.description,
    required this.synced,
  });
}

class LoanAdapter extends TypeAdapter<Loan> {
  @override
  Loan read(BinaryReader reader) {
    final jalali_request_date = reader.readString();
    final suggested_value = reader.readString();
    final formatted_requested_value = reader.readString();
    final level = reader.readString();
    final status = reader.readString();
    final suggested_repayment_count = reader.readString();
    final repayment_count = reader.readString();
    final formatted_repayment_value = reader.readString();
    final formatted_residue_value = reader.readString();
    final description = reader.readString();
    final synced = reader.readBool();
    return Loan(
      jalali_request_date: jalali_request_date,
      suggested_value: suggested_value,
      formatted_requested_value: formatted_requested_value,
      level: level,
      status: status,
      suggested_repayment_count: suggested_repayment_count,
      repayment_count: repayment_count,
      formatted_repayment_value: formatted_repayment_value,
      formatted_residue_value: formatted_residue_value,
      description: description,
      synced: synced,
    );
  }

  @override
  // TODO: implement typeId
  int get typeId => 6;

  @override
  void write(BinaryWriter writer, Loan loan) {
    writer.writeString(loan.jalali_request_date);
    writer.writeString(loan.suggested_value);
    writer.writeString(loan.formatted_requested_value??'');
    writer.writeString(loan.level);
    writer.writeString(loan.status);
    writer.writeString(loan.suggested_repayment_count??'');
    writer.writeString(loan.repayment_count?? '');
    writer.writeString(loan.formatted_repayment_value?? '');
    writer.writeString(loan.formatted_residue_value?? '');
    writer.writeString(loan.description);
    writer.writeBool(loan.synced);
  }
}
