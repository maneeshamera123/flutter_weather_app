import 'package:mongo_dart/mongo_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db.dart';

class UserService {
  Future<String?> getUserLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('userEmail');
      
      if (email == null) return null;

      final db = await MongoDatabase.db;
      final collection = db.collection('users');
      final user = await collection.findOne(where.eq('email', email));
      
      return user?['location'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isAdmin') ?? false;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final db = await MongoDatabase.db;
      final collection = db.collection('users');
      final users = await collection.find().toList();
      return users;
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }
}
