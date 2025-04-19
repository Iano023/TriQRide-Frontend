import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_application_1/controllers/auth_service.dart';
import 'package:flutter_application_1/controllers/crud_service.dart';


class PushNotifications {
  static final _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Request notification permission
  static Future<void> init() async {
    try {
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );
    } catch (e) {
      print("Error requesting notification permissions: $e");
    }
  }

  // Get the FCM device token
  static Future<String?> getDeviceToken({int maxRetries = 3}) async {
    try {
      String? token;
      if (kIsWeb) {
        // Get the device FCM token for web
        token = await _firebaseMessaging.getToken(
          vapidKey:
              "BPA9r_00LYvGIV9GPqkpCwfIl3Es4IfbGqE9CSrm6oeYJslJNmicXYHyWOZQMPlORgfhG8RNGe7hIxmbLXuJ92k",
        );
        print("Web device token: $token");
      } else {
        // Get the device FCM token for Android/iOS
        token = await _firebaseMessaging.getToken();
        print("Android/iOS device token: $token");
      }

      if (token != null) {
        await saveTokentoFirestore(token: token);
      } else {
        print("Failed to retrieve device token.");
      }

      return token;
    } catch (e) {
      print("Failed to get device token: $e");
      if (maxRetries > 0) {
        print("Retrying to get token after 10 seconds...");
        await Future.delayed(Duration(seconds: 10));
        return getDeviceToken(maxRetries: maxRetries - 1);
      } else {
        print("Max retries reached. Could not get device token.");
        return null;
      }
    }
  }

  // Save or update the FCM token in Firestore
  static Future<void> saveTokentoFirestore({required String token}) async {
    try {
      bool isUserLoggedIn = await AuthService.isLoggedIn();
      print("User is logged in: $isUserLoggedIn");

      if (isUserLoggedIn) {
        await CRUDService.saveUserToken(token);
        print("Token saved to Firestore successfully.");
      } else {
        print("User is not logged in. Token not saved.");
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print("Token refreshed: $newToken");
        if (isUserLoggedIn) {
          await CRUDService.saveUserToken(newToken);
          print("Updated token saved to Firestore.");
        } else {
          print("User not logged in during token refresh. Token not saved.");
        }
      });
    } catch (e) {
      print("Error saving token to Firestore: $e");
    }
  }
}
