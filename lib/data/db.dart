import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

const _dbPath = 'db.json';
Database _db;
Database get db => _db;

Future<void> initDb() async {
  _db = await databaseFactoryIo.openDatabase(_dbPath);
}
