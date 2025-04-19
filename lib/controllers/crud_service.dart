import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CRUDService {
  // Save FCM token to Firestore
  static Future<void> saveUserToken(String token) async {
    User? user = FirebaseAuth.instance.currentUser;

    // Check if user is logged in
    if (user == null) {
      print("No user is currently logged in.");
      return;
    }

    // Prepare the data to be saved
    Map<String, dynamic> data = {
      "email": user.email,
      "token": token,
    };

    try {
      // Save the token to Firestore
      await FirebaseFirestore.instance
          .collection("user_data")
          .doc(user.uid)
          .set(data, SetOptions(merge: true)); // Using merge to avoid overwriting existing fields

      print("Document Added/Updated for user: ${user.uid}");
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth specific exceptions
      print("Firebase Auth Error: ${e.message}");
    } on FirebaseException catch (e) {
      // Handle Firestore specific exceptions
      print("Firestore Error: ${e.message}");
    } on Exception catch (e) {
      // Handle general exceptions
      print("General Error: ${e.toString()}");
    }
  }
}
