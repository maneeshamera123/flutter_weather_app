import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../db.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initPushNotifications() async {
    // Request permission for iOS
    await _firebaseMessaging.requestPermission();
    
    // Get FCM Token
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await saveFcmToken(token);
    }
    
    // Listen for token updates
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      saveFcmToken(newToken);
    });
  }

  Future<void> saveFcmToken(String fcmToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('userEmail');
      if (email == null) return;

      final db = await MongoDatabase.db;
      final collection = db.collection('users');
      await collection.updateOne(
        where.eq('email', email),
        modify.set('fcmToken', fcmToken),
      );
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  Future<bool> sendWeatherAlert(String userFcmToken, String userCity) async {
    try {
      // NOTE: You need to place your Firebase Service Account JSON file in assets/service_account.json
      // and declare it in pubspec.yaml for this to work.
      // This allows the app to act as an admin to send the notification.
      final serviceAccountJson = await rootBundle.loadString('assets/service_account.json');
      final Map<String, dynamic> serviceAccountMap = jsonDecode(serviceAccountJson);
      
      final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      final authClient = await clientViaServiceAccount(accountCredentials, scopes);

      final projectId = serviceAccountMap['project_id'];
      final url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final response = await authClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': {
            'token': userFcmToken,
            'notification': {
              'title': 'Weather Alert!',
              'body': 'Check the latest weather updates in $userCity.',
            },
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            }
          }
        }),
      );

      authClient.close();
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }
}
