import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/controllers/store_service.dart'; 
import 'package:flutter_application_1/controllers/crud_service.dart';
import 'package:flutter_application_1/login/Sign_up.dart';
import 'package:flutter_application_1/login/frpass.dart';
import 'package:flutter_application_1/login/homepage.dart';



class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to handle login
  Future<void> _login() async {
    try {
      // Sign in with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(code: 'user-not-found', message: 'User not found.');
      }

      // Check if the user's email is verified
      if (!user.emailVerified) {
        await user.sendEmailVerification();

        // Show alert dialog informing the user to verify their email
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Email Verification Required"),
              content: Text("A verification email has been sent to ${user.email}. Please verify your email before logging in."),
              actions: [
                TextButton(
                  child: Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
              ],
            );
          },
        );

        return; // Exit the login process
      }

      // Fetch and save device token
      String? token = await PushNotifications.getDeviceToken();
      if (token != null) {
        await CRUDService.saveUserToken(token); // Ensure this method is implemented to save the token
        print("Device token fetched and saved successfully: $token");
      } else {
        print("Failed to fetch or save device token.");
      }

      // Show success message and navigate to homepage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => homepage()), // Ensure this is your correct home page
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login Successfully!"),
        ),
      );
    } on FirebaseAuthException catch (e) {
      // Handle Firebase authentication exceptions
      String errorMessage;

      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        default:
          errorMessage = 'Failed to log in. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    } catch (e) {
      // Handle other exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 90.0, horizontal: 15.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/images/logologin.png",
                  width: 175,
                ),
                const Text(
                  "TriQRide Candelaria",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),
                Container(
                  width: 300, // Set your desired width here
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'DelaCruz@gmail.com',
                      prefixIconColor: Colors.red,
                      prefixIcon: const Icon(Icons.person_2_outlined),
                      border: OutlineInputBorder(), // Use OutlineInputBorder
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Container(
                  width: 300, // Set your desired width here
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      prefixIconColor: Colors.red,
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                        child: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                      ),
                      border: OutlineInputBorder(), // Use OutlineInputBorder
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _login,
                  child: Text('Login'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0.0),
                    ),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return ForgotPassword();
                      }),
                    );
                  },
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(color: Colors.black, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(21.0),
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) {
                            return SignUp();
                          }),
                        );
                      },
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}