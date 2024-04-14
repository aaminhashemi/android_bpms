import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class Coordinate extends HiveObject {

  @HiveField(0)
  late int id;
  @HiveField(1)
  double latitude;
  @HiveField(2)
  double longitude;

  Coordinate({
      required this.id,
      required this.latitude,
      required this.longitude,
  });
}

class CoordinateAdapter extends TypeAdapter<Coordinate> {
  @override
  Coordinate read(BinaryReader reader) {
    final id = reader.readInt();
    final latitude = reader.readDouble();
    final longitude = reader.readDouble();
    return Coordinate(
        id: id,
        latitude: latitude,
        longitude: longitude,
    );
  }

  @override
  // TODO: implement typeId
  int get typeId => 1;

  @override
  void write(BinaryWriter writer, Coordinate coordinate) {
    writer.writeInt(coordinate.id);
    writer.writeDouble(coordinate.latitude);
    writer.writeDouble(coordinate.longitude);
  }

}
