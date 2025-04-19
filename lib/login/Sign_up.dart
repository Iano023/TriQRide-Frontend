import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore import
import 'package:flutter_application_1/login/Login.dart';

class SignUp extends StatefulWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  TextEditingController _fullController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmpassController = TextEditingController();

  bool _obscureText1 = true;
  bool _obscureText2 = true;

  // Firebase Authentication instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance

  // Function to handle sign up
  Future<void> _signUp() async {
    if (_passwordController.text != _confirmpassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Passwords do not match!"),
        ),
      );
      return;
    }

    try {
      // Create user with email and password in Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save user details in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'full_name': _fullController.text.trim(),
        'address': _addressController.text.trim(),
        'email': _emailController.text.trim(),
        'created_at': FieldValue.serverTimestamp(), // Store the creation time
      });

      // Sign out the user immediately after registration
      await _auth.signOut();

      // Show success dialog and navigate to login page
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Account Successfully Created!"),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return Login();
                      },
                    ),
                  );
                },
                child: const Text("Close"),
              ),
            ],
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Failed to create account. Please try again."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Sign up",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Image.asset(
                "assets/images/logologin.png",
                height: 150,
                width: 150,
              ),
              SizedBox(
                height:5
              ),
              const Text(
                "Candelaria Quezon",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  height: -2,
                ),
              ),
              const SizedBox(height: 10),
              buildTextField(_fullController, 'Full Name'),
              const SizedBox(height: 20),
              buildTextField(_addressController, 'Address'),
              const SizedBox(height: 20),
              buildTextField(_emailController, 'Email',
                  hintText: 'Pedro@gmail.com'),
              const SizedBox(height: 20),
              buildPasswordField(_passwordController, 'Password', _obscureText1,
                  () {
                setState(() {
                  _obscureText1 = !_obscureText1;
                });
              }),
              const SizedBox(height: 20),
              buildPasswordField(
                  _confirmpassController, 'Confirm Password', _obscureText2, () {
                setState(() {
                  _obscureText2 = !_obscureText2;
                });
              }),
              const SizedBox(height: 30),
              OutlinedButton(
                onPressed: _signUp,
                child: const Text("Create Account"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, String labelText,
      {String? hintText}) {
    return Container(
      width: 300,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          border: UnderlineInputBorder(),
        ),
      ),
    );
  }

  Widget buildPasswordField(TextEditingController controller, String labelText,
      bool obscureText, VoidCallback toggleVisibility) {
    return Container(
      width: 300,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: labelText,
          suffixIcon: GestureDetector(
            onTap: toggleVisibility,
            child: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
          ),
          border: UnderlineInputBorder(),
        ),
      ),
    );
  }
}