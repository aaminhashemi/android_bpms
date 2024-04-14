/*
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/rollcal.dart';

class DatabaseHelper {
  static const int _version=2;
  static const String dbName = 'Rollcal1.db';

  static Future<Database> _getDB() async {
    return openDatabase(join(await getDatabasesPath(),dbName),
    onCreate: (db,version) async=>await db.execute("CREATE TABLE rollcals (id INTEGER PRIMARY KEY AUTOINCREMENT,status TEXT, date TEXT, time TEXT, type TEXT,stat TEXT, synced INTEGER, description TEXT);"),version: _version
    );
  }

  static Future<int> addRollcal(Rollcal rollcal) async{
    final db=await _getDB();
    return await db.insert("Rollcal", rollcal.toJson(),conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> updateRollcal(Rollcal rollcal) async{
    final db=await _getDB();
    return await db.update("Rollcal", rollcal.toJson(),where: 'id=?',whereArgs: [rollcal.id],conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int>deleteRollcal(Rollcal rollcal) async{
    final db=await _getDB();
    return await db.delete("Rollcal", where: 'id=?',whereArgs: [rollcal.id]);
  }

  static Future<List<Rollcal>?> getAllRollcals(Rollcal rollcal) async {
    final db=await _getDB();
    final List<Map<String,dynamic>> maps=await db.query("rollcals");
    if(maps.isEmpty){
      return null;
    }
    return List.generate(maps.length, (index) => Rollcal.fromJson(maps[index]));
  }

}
*/
