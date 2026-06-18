import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MongoDatabase {
  static final String _mongoUri = dotenv.env['MONGO_URI'] ?? '';
  
  static Db? _db;

  // Get the database instance
  static Future<Db> get db async {
    if (_db == null || !_db!.isConnected) {
      _db = await Db.create(_mongoUri);
      await _db!.open();
    }
    return _db!;
  }

  // Optional: method to close connection when app terminates
  static Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
    }
  }
}
