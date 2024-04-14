/*
import 'package:sqflite/sqflite.dart';
import '../models/rollcal.dart';
import '../helper/database_helper.dart';

class RollcalRepository {
  final DatabaseHelper dbHelper = DatabaseHelper();

  //RollcalRepository dataRepository = RollcalRepository();

*/
/*  Future<void> insertData(Rollcal data) async {
    final Database db = await dbHelper.database;
    print('object');
    await db.insert('rollcals', data.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }*//*


  Future<List<Rollcal>> getRollcalsFromLocal() async {
    try {
    final Database db = await openDatabase('Rollcal1.db', version: 3);

    final List<Map<String, dynamic>> maps = await db.query('rollcals');

    return List<Rollcal>.generate(maps.length, (i) {
      return Rollcal(
        status: maps[i]['status'],
        date: maps[i]['date'],
        type: maps[i]['type'],
        time: maps[i]['time'],
        synced: maps[i]['synced']== 1,
        description: maps[i]['description'],
      );
    });
    } catch (e) {
      print('Error getting rollcals from local database: $e');
      return [];
    }
  }

*/
/*
  Future<List<Rollcal>> getData() async {
    final Database db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('rollcals');
    return List.generate(maps.length, (i) {
      return Rollcal.fromMap(maps[i]);
    });
  }
*//*


  Future<List<Rollcal>> saveRollcalsToLocal(List<dynamic> rollcalData) async {
    List<Rollcal> rollcals = [];
    final Database db = await openDatabase('database.db', version: 1,
        onCreate: (Database db, int version) async {
      await db.execute('''
          CREATE TABLE IF NOT EXISTS rollcals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            status TEXT,
            date TEXT,
            time TEXT,
            type TEXT,
            description TEXT
          )
        ''');
    });
    for (var rollcalMap in rollcalData) {
      Rollcal rollcal = Rollcal(
        status: rollcalMap['status'],
        date: rollcalMap['jalali_date'],
        time: rollcalMap['time'],
        type: rollcalMap['type'],
        synced: rollcalMap['synced'],
        description: rollcalMap['description'],
      );

      await db.insert('rollcals', rollcal.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      rollcals.add(rollcal);
    }

    return rollcals;
  }

  Future<List<Rollcal>> saveRollcalToLocal(dynamic rollcalData) async {
    List<Rollcal> rollcals = [];
    final Database db = await openDatabase('database.db', version: 1,
        onCreate: (Database db, int version) async {
      await db.execute('''
          CREATE TABLE IF NOT EXISTS rollcals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            status TEXT,
            date TEXT,
            time TEXT,
            type TEXT,
            synced INTEGER
            description TEXT
          )
        ''');

    });
    Rollcal rollcal = Rollcal(
      status: '880',
      date: '8080',
      time: '808080',
      type: 'r8080',
      synced: true,
      description: 'jty',
    );

    await db.insert('rollcals', rollcal.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    rollcals.add(rollcal);
    return rollcals;
  }
}
*/
