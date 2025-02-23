// Make sure this file contains the showForgotPasswordDialog function.
import 'package:ez8app/home/home/showForgotPasswordDialog.dart';
import 'package:ez8app/home/home/showRegisterDialog.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

void showSignInDialog(BuildContext context, FirebaseAuth auth,
    Function(String) updateDisplayName) {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final GoogleSignIn googleSignIn = GoogleSignIn();

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        // Rounded corners for a modern look.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 5,
        child: Container(
          // Constrain the dialog width.
          constraints: BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(20),
          // Make content scrollable on small screens.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Enter your email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Enter your password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                // Google Sign-In Button
                GestureDetector(
                  onTap: () async {
                    try {
                      final GoogleSignInAccount? googleUser =
                          await googleSignIn.signIn();
                      if (googleUser == null) return; // User cancelled.
                      final GoogleSignInAuthentication googleAuth =
                          await googleUser.authentication;
                      final OAuthCredential credential =
                          GoogleAuthProvider.credential(
                        accessToken: googleAuth.accessToken,
                        idToken: googleAuth.idToken,
                      );
                      await auth.signInWithCredential(credential);
                      updateDisplayName(googleUser.displayName ?? 'User');
                      Navigator.of(context).pop(); // Close dialog

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sign In Successful! Welcome!'),
                        ),
                      );

                      // Check if admin and navigate.
                      if (auth.currentUser?.email == 'admin@gmail.com') {
                        Navigator.pushNamed(context, '/adminPage');
                      }
                    } on FirebaseAuthException catch (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Incorrect user or password'),
                        ),
                      );
                    } catch (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Incorrect user or password'),
                        ),
                      );
                    }
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/img/google.png',
                          height: 30,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Sign in with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Action buttons: Cancel and Sign In.
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog.
                      },
                      child: Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () async {
                        try {
                          await auth.signInWithEmailAndPassword(
                            email: emailController.text,
                            password: passwordController.text,
                          );
                          updateDisplayName(emailController.text.split('@')[0]);
                          Navigator.of(context).pop(); // Close dialog.
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Sign In Successful!'),
                            ),
                          );
                          // Check if admin and navigate.
                          if (emailController.text == 'admin@gmail.com') {
                            Navigator.pushNamed(context, '/adminPage');
                          }
                        } on FirebaseAuthException catch (_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Incorrect user or password'),
                            ),
                          );
                        } catch (_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Incorrect user or password'),
                            ),
                          );
                        }
                      },
                      child: Text('Sign In'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
// Row for links: Forgot Password and Register.
                Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // adjust as needed
                  children: [
                    // Forgot Password link.
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close sign in dialog.
                        showForgotPasswordDialog(context, auth);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        foregroundColor: Colors.blueAccent,
                      ),
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    // Add some spacing between the buttons if needed.
                    const SizedBox(height: 8),
                    // Register link.
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close sign in dialog.
                        showRegisterDialog(context, auth, updateDisplayName);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        foregroundColor: Colors.blueAccent,
                      ),
                      child: const Text(
                        "Don't have an account? Signup",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      );
    },
  );
}
