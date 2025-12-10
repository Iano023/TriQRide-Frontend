import 'dart:async';
import '../components/Qr_scanner.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/Fare_list_page.dart';
import '../components/Notifcation_page.dart';
import 'package:flutter_application_1/login/Login.dart';

void main() {
  runApp(const MyApp());
}

void _logout(BuildContext context) async {
  // Firebase sign out example
  await FirebaseAuth.instance.signOut();

  // Navigate back to login screen or clear stack
  Navigator.of(context).popUntil((route) => route.isFirst);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: homepage(),
    );
  }
}

class homepage extends StatefulWidget {
  const homepage({super.key});

  @override
  _MainStateHomepage createState() => _MainStateHomepage();
}

class _MainStateHomepage extends State<homepage> with TickerProviderStateMixin {
  int _currentIndex = 1;
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _offsetAnimations;

  final List<Widget> _children = [
    FarePriceListPage(),
    QRScannerPage(),
    NotificationPage(),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
    });

    _offsetAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0, -0.1),
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _controllers[index].forward().then((_) {
      _controllers[index].reverse();
    });
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut(); // Log out from Firebase
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (context) => Login()), // Replace with your Login page
        (Route<dynamic> route) => false, // Remove all routes from stack
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log out. Please try again.'),
        ),
      );
    }
  }

  void _showEmergencyContacts() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Emergency Contacts'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                        text: 'Police: ',
                        style: TextStyle(fontWeight: FontWeight.normal)),
                    TextSpan(
                        text: '0947-347-8094 (SMART)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                        text: 'MDRRMO: ',
                        style: TextStyle(fontWeight: FontWeight.normal)),
                    TextSpan(
                        text: '0920-209-7070 (SMART)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                        text: 'Hospitals: ',
                        style: TextStyle(fontWeight: FontWeight.normal)),
                    TextSpan(
                        text: '(042)-585-4281',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.contact_emergency_sharp),
          onPressed: _showEmergencyContacts,
          tooltip: 'Emergency Hotline',
          color: Colors.white,
        ),
        actions: [
          TextButton(
            onPressed: () => _logout(context),
            child: Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _children[_currentIndex],
      bottomNavigationBar: Container(
        color: Colors.deepOrange,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.money, "Fare Price List", 0),
              _buildNavItem(Icons.qr_code_scanner_sharp, "QR Scanner", 1),
              _buildNavItem(
                  Icons.notifications_active_outlined, "Notification", 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    return GestureDetector(
      onTap: () => onTabTapped(index),
      child: SlideTransition(
        position: _offsetAnimations[index],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Icon(
                icon,
                color:
                    _currentIndex == index ? Colors.deepOrange : Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: _currentIndex == index
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationModel {
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String serverTime;
  final String serverDate;

  NotificationModel({
    required this.title,
    required this.body,
    required this.data,
    required this.serverTime,
    required this.serverDate,
  });
}
