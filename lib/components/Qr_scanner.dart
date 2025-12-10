import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class QRScannerPage extends StatefulWidget {
  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String scannedData = '';
  Map<String, dynamic>? driverData;
  bool isLoading = false;

  int _rating = 0;
  double _gradedRate = 0.0;
  int _ratingCount = 0;
  bool isSubmitDisabled = false;

  // Add Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _reporterName = '';

  final TextEditingController _reportController = TextEditingController();
  Timer? _timer;
  int _remainingTime = 0;

  @override
  void dispose() {
    controller?.dispose();
    _reportController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // Add function to get reporter name
  Future<String> _getReporterName() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          return userData['full_name'] ?? '';
        }
      }
      return '';
    } catch (e) {
      print('Error fetching reporter name: $e');
      return '';
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      setState(() {
        scannedData = scanData.code ?? '';
        print('QR Code scanned: $scannedData');
      });

      if (scannedData.isNotEmpty) {
        await fetchDriverData(scannedData);
      }
    });
  }

  Future<void> fetchDriverData(String qrCode) async {
    setState(() {
      isLoading = true;
    });
    try {
      final Uri uri = Uri.parse(qrCode);
      final String id = uri.queryParameters['id'] ?? '';

      if (id.isEmpty) {
        _showErrorDialog(context, 'Invalid QR code. No ID found.');
        return;
      }

      final response = await http.get(
        Uri.parse('https://triqride.onrender.com/api/list/$id'),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);

        String driverName = data['Driver_name'] ?? 'Unknown';
        String plateNumber = data['Plate_number'].toString();
        String barangay = data['Barangay'] ?? 'N/A';
        String imageUrl = data['Image'] ?? '';

        double overallRating = data['overallRating'] is String
            ? double.tryParse(data['overallRating']) ?? 0.0
            : (data['overallRating'] ?? 0.0);

        int numberOfViolations = data['totalViolations'] is String
            ? int.tryParse(data['totalViolations']) ?? 0
            : (data['totalViolations'] ?? 0);

        int ratingCount = data['ratingCount'] is String
            ? int.tryParse(data['ratingCount']) ?? 0
            : (data['ratingCount'] ?? 0);

        driverData = {
          'id': data['id'].toString(),
          'Driver_name': driverName,
          'Plate_number': plateNumber,
          'Barangay': barangay,
          'image': imageUrl,
          'Overall_rating': overallRating,
          'Violations': numberOfViolations,
          'Rating_count': ratingCount,
        };

        await _checkCooldown(driverData!['id']);
        setState(() {});
      } else {
        _showErrorDialog(
            context, 'Failed to load driver data. Please try again.');
      }
    } catch (e) {
      _showErrorDialog(context, 'Error fetching data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _submitReport(String driverId, String report, String plate,
      String driverName, String barangay, int rating) async {
    if (report.isEmpty && rating > 0) {
      print('Submitting only rating without a report');
    } else if (report.isNotEmpty && rating > 0) {
      print('Submitting rating with a report, violations will increase');
    }

    setState(() {
      isSubmitDisabled = true;
    });

    String? fcmToken = await getFcmToken();
    print('FCM Token: $fcmToken');

    // Fetch reporter's name before submitting
    String reporterName = await _getReporterName();
    print('Reporter Name: $reporterName'); // Debug print

    final String apiUrl = 'https://triqride.onrender.com/api/report/$driverId';

    final Map<String, String> requestBody = {
      'plate': plate,
      'driver': driverName,
      'brgy': barangay,
      'report': report,
      'fcm_token': fcmToken ?? '',
      'ratings': rating.toString(),
      'reporter_name': reporterName, // Add reporter's name to request
    };

    print('Submitting report for Driver ID: $driverId');
    print('Report data: $requestBody');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        print('Report and rating submitted successfully');
        _showSuccessDialog(context);

        final prefs = await SharedPreferences.getInstance();
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        await prefs.setInt('lastReportTime_$driverId', currentTime);

        _startCooldownTimer();

        setState(() {
          isSubmitDisabled = true;
          driverData = null;
        });
      } else {
        print('Failed to submit, Status Code: ${response.statusCode}');
        print('Response body: ${response.body}');
        _showErrorDialog(context, 'Failed to submit report. Please try again.');

        setState(() {
          isSubmitDisabled = false;
        });
      }
    } catch (e) {
      print('Error submitting report: $e');
      _showErrorDialog(context, 'Error submitting report. Please try again.');

      setState(() {
        isSubmitDisabled = false;
      });
    }
  }

  Future<String?> getFcmToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    print('FCM Token obtained: $token'); // Print FCM token
    return token;
  }

  Future<void> _checkCooldown(String driverId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastReportTime = prefs.getInt('lastReportTime_$driverId') ?? 0;

    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final timeDifference = currentTime - lastReportTime;

    if (timeDifference < 3 * 60 * 60 * 1000) {
      setState(() {
        _remainingTime = (3 * 60 * 60 * 1000 - timeDifference) ~/ 1000;
      });
      _startCooldownTimer();
    } else {
      _remainingTime = 0;
    }
  }

  void _startCooldownTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _timer!.cancel(); // Stop the timer when it reaches 0
        }
      });
    });
  }

  String _formatRemainingTime() {
    final hours = _remainingTime ~/ 3600;
    final minutes = (_remainingTime % 3600) ~/ 60;
    final seconds = _remainingTime % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<bool> _canSubmitReport(String driverId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastReportTime = prefs.getInt('lastReportTime_$driverId') ?? 0;

    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final timeDifference = currentTime - lastReportTime;

    // Return true if more than 1 minute has passed
    return timeDifference > 3 * 60 * 60 * 1000; // 24 hours in milliseconds
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text('Your report has been submitted successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          driverData == null ? buildQRScanner() : buildDriverDetailsUI(),
        ],
      ),
    );
  }

  Widget buildQRScanner() {
    return Stack(
      children: [
        QRView(
          key: qrKey,
          onQRViewCreated: _onQRViewCreated,
          overlay: QrScannerOverlayShape(
            borderColor: Colors.deepOrange,
            borderRadius: 10,
            borderLength: 30,
            borderWidth: 10,
            cutOutSize: 300,
          ),
        ),
        Center(
          child: isLoading
              ? CircularProgressIndicator()
              : Text(
                  'Scan a QR code',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
        ),
      ],
    );
  }

  Widget buildDriverDetailsUI() {
    return FutureBuilder<bool>(
      future: _canSubmitReport(driverData!['id']),
      builder: (context, snapshot) {
        final canSubmitReport = snapshot.data ?? false;

        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/municipalhall.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
              ),
              child: Column(
                children: [
                  AppBar(
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () {
                        setState(() {
                          driverData = null; // Reset to scanning mode
                        });
                      },
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                  ),
                  SizedBox(height: 16),
                  // Driver Image
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors
                        .grey[300], // Add background color for placeholder
                    backgroundImage: driverData?['image'] != null &&
                            driverData!['image'].isNotEmpty
                        ? NetworkImage(driverData!['image'])
                        : AssetImage('assets/images/placeholder.jpg')
                            as ImageProvider,
                  ),
                  SizedBox(height: 16),
                  // Driver Name
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center, // Center-aligns the text
                      text: TextSpan(
                        text: 'Franchise Owner: ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                        children: [
                          TextSpan(
                            text: driverData?['Driver_name'] ?? 'Unknown',
                            style: TextStyle(
                              color: driverData?['Driver_name'] != null
                                  ? Colors.white
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  // Overall Rating and Count Display
                  if (driverData?['Overall_rating'] != null &&
                      driverData?['Rating_count'] != null)
                    RichText(
                      text: TextSpan(
                        text: 'Overall Rating: ',
                        style:
                            TextStyle(fontSize: 18, color: Colors.deepOrange),
                        children: [
                          WidgetSpan(
                            child: Icon(
                              Icons.star, // Star icon
                              color: Colors.yellow, // Star color
                              size: 18, // Icon size to match text
                            ),
                          ),
                          TextSpan(
                            text:
                                ' ${driverData!['Overall_rating'].toStringAsFixed(2)} / ',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          TextSpan(
                            text: '(${driverData!['Rating_count']})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // Highlight color
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 30),
                  // Barangay
                  RichText(
                    text: TextSpan(
                      text: 'Barangay: ',
                      style: TextStyle(fontSize: 18, color: Colors.deepOrange),
                      children: <TextSpan>[
                        TextSpan(
                          text: '${driverData?['Barangay'] ?? 'N/A'}',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold, // Highlighted text is bold
                            color: Colors.white, // Choose a highlight color
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Franchise Plate Number
                  RichText(
                    text: TextSpan(
                      text: 'Franchise: ',
                      style: TextStyle(fontSize: 18, color: Colors.deepOrange),
                      children: <TextSpan>[
                        TextSpan(
                          text: '${driverData?['Plate_number'] ?? 'N/A'}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  // Number of Violations Display
                  if (driverData?['Violations'] != null)
                    Text(
                      '(Number of Violations: ${driverData!['Violations']})',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  SizedBox(height: 32),

                  // Report submission disabled message
                  if (!canSubmitReport)
                    Center(
                      child: Text(
                        'Report submission disabled for 3 hours\nRemaining time: ${_formatRemainingTime()}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),

                  SizedBox(height: 16),
                  // Report button
                  ElevatedButton(
                    onPressed: !isSubmitDisabled && canSubmitReport
                        ? () {
                            _showReportDialog(context);
                          }
                        : null, // Disable button if already submitted or cooldown is active
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.report_problem, size: 20),
                        SizedBox(width: 4),
                        Text(
                          'Leave a Report',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          // To manage state inside the dialog
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Leave a Report'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Note or instructions with icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Only Leave a Report if there's an incident that occurred.",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Report Text Field
                  TextField(
                    controller: _reportController,
                    decoration:
                        InputDecoration(hintText: 'Describe the incident'),
                  ),
                  SizedBox(height: 16),
                  // Rating section
                  Text(
                    'Rate Tricycle Driver',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _rating = index + 1;
                          });
                        },
                        child: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          size: 24,
                          color: index < _rating ? Colors.yellow : Colors.grey,
                        ),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _reportController.clear();
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    String reportText = _reportController.text;

                    // Allow submitting only the rating without a report
                    if (reportText.isEmpty && _rating == 0) {
                      _showErrorDialog(
                          context, 'Please provide a report or a rating.');
                      return;
                    }

                    String driverId = driverData?['id'] ?? '';
                    String plate = driverData?['Plate_number'] ?? 'Unknown';
                    String driverName =
                        driverData?['Driver_name'] ?? 'Unknown Driver';
                    String barangay = driverData?['Barangay'] ?? 'N/A';

                    if (driverId.isEmpty) {
                      _showErrorDialog(context, 'Driver ID is not available.');
                      return;
                    }

                    // Submit the report and rating, even if reportText is empty
                    _submitReport(driverId, reportText, plate, driverName,
                        barangay, _rating);

                    _reportController.clear();
                    Navigator.of(context).pop();
                  },
                  child: Text('Submit'),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Rating'),
          content: Text('Thank you for rating this driver.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
