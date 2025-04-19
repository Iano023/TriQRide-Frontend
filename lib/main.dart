import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/login/Login.dart';
import 'package:provider/provider.dart';
import 'controllers/notification_provider.dart';
import 'controllers/qr_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_application_1/login/homepage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Background message handler must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  try {
    final prefs = await SharedPreferences.getInstance();
    List<String> existingNotifications = prefs.getStringList('notifications') ?? [];

    final notificationData = {
      'title': message.notification?.title ?? 'No Title',
      'body': message.notification?.body ?? 'No Body',
      'data': message.data,
      'serverTime': message.data['serverTime'] ?? DateTime.now().toString(),
      'serverDate': message.data['serverDate'] ?? DateTime.now().toString(),
    };

    existingNotifications.insert(0, jsonEncode(notificationData));
    await prefs.setStringList('notifications', existingNotifications);
  } catch (e) {
    print('Error saving background notification: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final fcm = FirebaseMessaging.instance;
  await fcm.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  String? token = await fcm.getToken();
  print('FCM Token: $token');

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await fcm.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QRProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
  }

  void _setupFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.notification != null) {
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        notificationProvider.addNotification(NotificationModel(
          title: message.notification?.title ?? 'No Title',
          body: message.notification?.body ?? 'No Body',
          data: message.data,
          serverTime: message.data['serverTime'] ?? DateTime.now().toString(),
          serverDate: message.data['serverDate'] ?? DateTime.now().toString(),
        ));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      notificationProvider.addNotification(NotificationModel(
        title: message.notification?.title ?? 'No Title',
        body: message.notification?.body ?? 'No Body',
        data: message.data,
        serverTime: message.data['serverTime'] ?? DateTime.now().toString(),
        serverDate: message.data['serverDate'] ?? DateTime.now().toString(),
      ));

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/notificationPage',
        (route) => route.settings.name != '/notificationPage',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/home': (context) => homepage(),
        '/notificationPage': (context) => NotificationPage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    await Future.delayed(Duration(seconds: 2));
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => homepage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logologin.png', 
              width: 150,
            ),
            SizedBox(height: 20),
            Text(
              "Welcome to TriQRide Candelaria!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}