import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/login/homepage.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

class NotificationProvider with ChangeNotifier {
  final List<NotificationModel> _notifications = [];

  List<NotificationModel> get notifications => _notifications;

  Map<String, List<NotificationModel>> get groupedNotifications {
    Map<String, List<NotificationModel>> grouped = {};

    // First group notifications by date
    for (var notification in _notifications) {
      try {
        final date = DateFormat('MM/dd/yyyy').parse(notification.serverDate);
        final formattedDate = DateFormat('MMMM d, yyyy').format(date);

        if (!grouped.containsKey(formattedDate)) {
          grouped[formattedDate] = [];
        }
        grouped[formattedDate]!.add(notification);
      } catch (e) {
        print("Error parsing date: ${notification.serverDate}, error: $e");
        continue;
      }
    }

    // Sort notifications within each date group by time in descending order
    for (var notificationsForDate in grouped.values) {
      notificationsForDate.sort((a, b) {
        try {
          final timeA = DateFormat('HH:mm:ss').parse(a.serverTime);
          final timeB = DateFormat('HH:mm:ss').parse(b.serverTime);
          return timeB.compareTo(timeA);  // <- Changed this line only
        } catch (e) {
          print("Error parsing time: ${a.serverTime} or ${b.serverTime}, error: $e");
          return 0;
        }
      });
    }

    // Sort dates in descending order
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => DateFormat('MMMM d, yyyy').parse(b).compareTo(DateFormat('MMMM d, yyyy').parse(a)));

    // Create new map with sorted dates
    return Map<String, List<NotificationModel>>.fromIterable(
      sortedKeys,
      key: (k) => k as String,
      value: (k) => grouped[k as String]!,
    );
  }

  NotificationProvider() {
    loadNotifications();
  }

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    saveNotifications();
    notifyListeners();
  }

  Future<void> saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> jsonList = _notifications.map((notification) => jsonEncode({
          'title': notification.title,
          'body': notification.body,
          'data': notification.data,
          'serverTime': notification.serverTime,
          'serverDate': notification.serverDate,
        })).toList();
    await prefs.setStringList('notifications', jsonList);
  }

  Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? jsonList = prefs.getStringList('notifications');
    if (jsonList != null) {
      _notifications.clear();
      _notifications.addAll(jsonList.map((jsonItem) {
        final data = jsonDecode(jsonItem);
        return NotificationModel(
          title: data['title'],
          body: data['body'],
          data: Map<String, dynamic>.from(data['data']),
          serverTime: data['serverTime'],
          serverDate: data['serverDate'],
        );
      }).toList());
      notifyListeners();
    }
  }

  // Add this method to handle automatic refresh when scrolling up
  Future<void> autoRefresh(ScrollController scrollController) async {
    // Check if scroll position is at the top with a small threshold
    if (scrollController.position.pixels < -50) {
      await refreshAndCleanNotifications();
    }
  }

  // Add this method to clean flood notifications
  Future<void> refreshAndCleanNotifications() async {
    if (_notifications.isEmpty) return;

    // Create a map to track unique notifications based on title and time window
    final Map<String, NotificationModel> uniqueNotifications = {};
    
    for (var notification in _notifications) {
      try {
        // Create a key combining title and a 5-minute time window
        final DateTime notificationTime = DateFormat('MM/dd/yyyy HH:mm:ss')
            .parse('${notification.serverDate} ${notification.serverTime}');
        
        // Round to nearest 5 minutes to group similar notifications
        final windowTime = DateTime(
          notificationTime.year,
          notificationTime.month,
          notificationTime.day,
          notificationTime.hour,
          (notificationTime.minute ~/ 5) * 5,
        );
        
        final String key = '${notification.title}_${windowTime.toString()}';
        
        // Keep only the latest notification in each 5-minute window
        if (!uniqueNotifications.containsKey(key)) {
          uniqueNotifications[key] = notification;
        }
      } catch (e) {
        print("Error processing notification: $e");
      }
    }

    // Update notifications list with cleaned data
    _notifications.clear();
    _notifications.addAll(uniqueNotifications.values);

    // Save the cleaned notifications
    await saveNotifications();
    notifyListeners();
  }

  // Add the clear all notifications functionality
  Future<void> clearAllNotifications() async {
    try {
      // Clear all notifications from memory
      _notifications.clear();

      // Clear notifications from shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('notifications');

      // Cancel all pending local notifications if using flutter_local_notifications
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      await flutterLocalNotificationsPlugin.cancelAll();

      // Notify listeners to rebuild the UI
      notifyListeners();
      
      print('All notifications cleared successfully');
    } catch (e) {
      print('Error clearing notifications: $e');
      throw e; // Rethrow the error to be handled by the UI
    }
  }
}