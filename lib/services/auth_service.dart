import 'package:mongo_dart/mongo_dart.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../db.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final db = await MongoDatabase.db;
      final collection = db.collection('users');
      
      final user = await collection.findOne(where.eq('email', email));
      
      if (user == null) {
        return {'success': false, 'message': 'Invalid credentials'};
      }

      final isMatch = DBCrypt().checkpw(password, user['password']);
      
      if (isMatch) {
        // Retrieve the static app-level auth token from .env
        final String appAuthToken = dotenv.env['AUTH_TOKEN'] ?? '';
        
        // Save the user's email AND the app-level auth token to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userEmail', email);
        await prefs.setString('authToken', appAuthToken);
        
        // Return success
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Invalid credentials'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password, String location) async {
    try {
      final db = await MongoDatabase.db;
      final collection = db.collection('users');

      final existingUser = await collection.findOne(where.eq('email', email));
      if (existingUser != null) {
        return {'success': false, 'message': 'Email already exists'};
      }

      final salt = DBCrypt().gensaltWithRounds(10);
      final hashedPassword = DBCrypt().hashpw(password, salt);

      await collection.insertOne({
        'name': name,
        'email': email,
        'password': hashedPassword,
        'location': location,
        'date': DateTime.now().toIso8601String(),
        'lastNotificationSent': null,
      });

      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userEmail');
    await prefs.remove('authToken');
  }

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

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('userEmail');
  }
}
