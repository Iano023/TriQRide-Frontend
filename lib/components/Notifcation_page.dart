import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import '../login/homepage.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_application_1/controllers/notification_provider.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    // Request permission for iOS
    _firebaseMessaging.requestPermission().then((settings) {
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('User denied notification permissions.');
      } else {
        print('Notification permission granted!');
      }
    });

    // Initialize local notifications
    _createNotificationChannel();
    _initializeLocalNotifications();

    // Listen for Firebase messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground Message received: ${message.messageId}');
      if (message.notification != null) {
        print('Message title: ${message.notification!.title}');
        print('Message body: ${message.notification!.body}');
        _showNotification(message.notification, message.data);
      } else {
        print('Received a message without a notification');
      }
    });

    // Handle notifications when the app is launched from a terminated state
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        print(
            'App launched from terminated state with message: ${message.messageId}');
        _handleNotificationNavigation(message.data);
      } else {
        print('No initial message received when app launched.');
      }
    });

    // Handle notifications when the app is opened from the background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked/opened: ${message.messageId}');
      _handleNotificationNavigation(message.data);
    });

    // Add scroll listener for refresh detection
    _scrollController.addListener(() {
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      notificationProvider.autoRefresh(_scrollController);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Function to create a notification channel
  void _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'notifications_channel_001',
      'App Notifications',
      description: 'This channel is used for app notifications.',
      importance: Importance.max,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    print('Notification channel created successfully');
  }

  // Function to initialize local notifications
  void _initializeLocalNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: IOSInitializationSettings(),
    );

    _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (String? payload) async {
      if (payload != null) {
        // Decode and handle notification payload
        Map<String, dynamic> data = jsonDecode(payload);
        print('Notification payload received: $data');
        _handleNotificationNavigation(data); // Navigates to NotificationPage
      } else {
        print('No payload received with notification');
        // Directly navigate to NotificationPage if payload is null
        Navigator.pushNamed(context, '/notificationPage');
      }
    });
    print('Local notifications initialized successfully');
  }

  // Function to show notifications
  Future<void> _showNotification(
      RemoteNotification? notification, Map<String, dynamic> data) async {
    if (notification == null) {
      print('No notification to show');
      return;
    }

    // You can now handle serverDate and serverTime passed from the backend
    String serverTime = data['serverTime'] ?? 'Unknown Time';
    String serverDate = data['serverDate'] ?? 'Unknown Date';

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'notifications_channel_001',
      'App Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      icon: 'app_icon',
      color: Color(0xFFFFA500),
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: IOSNotificationDetails(),
    );

    int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    try {
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        notification.title ?? 'No Title',
        notification.body ?? 'No Body',
        platformChannelSpecifics,
        payload: jsonEncode(data), // Pass the entire data object
      );
      print('Notification displayed: ${notification.title}');
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    if (!data.containsKey('icon')) {
      data['icon'] =
          data['attended'] == 'false' ? 'absence_icon' : 'attendance_icon';
    } else if (!data.containsKey('icon')) {
      data['icon'] =
          data['attended'] == 'false' ? 'absence_icon' : 'attendance_icon';
    }
    print('Navigating based on notification data: $data');
    Navigator.pushNamed(context, '/notificationPage', arguments: data);
  }

  Widget NotificationCard(NotificationModel notification) {
    print('Notification data received: ${notification.data}');
    IconData icon;
    Color iconColor;

    // Determine icon based on the 'icon' data field
    if (notification.data['icon'] == 'attendance_icon') {
      icon = Icons.check_circle;
      iconColor = Colors.green;
    } else if (notification.data['icon'] == 'absence_icon') {
      icon = Icons.cancel_outlined;
      iconColor = Colors.red;
    } else {
      icon = Icons.send;
      iconColor = Colors.orange;
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          notification.title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                      text: 'Date: ', style: TextStyle(color: Colors.black)),
                  TextSpan(
                      text: notification.serverDate,
                      style: TextStyle(color: Colors.red)),
                  TextSpan(
                      text: '  |  Time: ',
                      style: TextStyle(color: Colors.black)),
                  TextSpan(
                      text: notification.serverTime,
                      style: TextStyle(color: Colors.red)),
                ],
              ),
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearAllNotifications() async {
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear All Notifications'),
          content: Text(
              'Are you sure you want to clear all notifications? This cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Clear All'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed ?? false) {
      try {
        setState(() {
          _isRefreshing = true;
        });

        // Clear notifications from provider
        await notificationProvider.clearAllNotifications();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All notifications cleared successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        // Show error message if clearing fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear notifications: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } finally {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final groupedNotifications = notificationProvider.groupedNotifications;

    return Scaffold(
      appBar: AppBar(
        title: Text('Clear Notification Button'),
        actions: [
          // Only show clear button if there are notifications
          if (groupedNotifications.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear_all),
              onPressed: _clearAllNotifications,
              tooltip: 'Clear All Notifications',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/municipalhall.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: groupedNotifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No notifications',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            : ScrollbarTheme(
                data: ScrollbarThemeData(
                  thumbColor: WidgetStateProperty.all(Colors.blue),
                  trackColor: WidgetStateProperty.all(Colors.grey.shade300),
                  radius: Radius.circular(8),
                  thickness: WidgetStateProperty.all(6.0),
                ),
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _isRefreshing = true;
                    });
                    try {
                      await notificationProvider.refreshAndCleanNotifications();
                    } finally {
                      setState(() {
                        _isRefreshing = false;
                      });
                    }
                  },
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: false,
                    radius: Radius.circular(8),
                    thickness: 6.0,
                    child: ListView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (_isRefreshing)
                          Container(
                            padding: EdgeInsets.all(8.0),
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(),
                          ),
                        ...groupedNotifications.entries.map((entry) {
                          final date = entry.key;
                          final notificationsForDate = entry.value;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  date,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ),
                              ...notificationsForDate
                                  .map((notification) =>
                                      NotificationCard(notification))
                                  .toList(),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
