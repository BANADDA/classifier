import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class PredictionDatabaseHelper implements Exception {
  static final _databaseName = "assets/predictions.db";
  static final _databaseVersion = 1;

  static final table = 'predictions';
  static final columnId = 'id';
  static final columnImagePath = 'imagePath';
  static final columnPrediction = 'prediction';
  static final columnSymptoms = 'symptoms';
  static final columnRemedies = 'remedies';
  static final columnDate = 'date';

  PredictionDatabaseHelper._privateConstructor();
  static final PredictionDatabaseHelper instance =
      PredictionDatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    try {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      String path = join(appDocumentDir.path, _databaseName);

      // Create the directory if it doesn't exist
      await Directory(dirname(path)).create(recursive: true);

      // Open the database
      _database = await openDatabase(path, version: _databaseVersion,
          onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY,
            $columnImagePath TEXT NOT NULL,
            $columnPrediction TEXT NOT NULL,
            $columnSymptoms TEXT,
            $columnRemedies TEXT,
            $columnDate TEXT NOT NULL
          )
          ''');
      });

      print('Database opened successfully');
    } catch (e) {
      print('Error opening database because: $e');
    }
  }

  Future<int> insertPrediction(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllPredictions() async {
    Database db = await instance.database;
    return await db.query(table);
  }

  Future<int> updatePrediction(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> deletePrediction(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }
}
