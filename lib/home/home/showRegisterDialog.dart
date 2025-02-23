import 'package:ez8app/home/home/showSignInDialog.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'email_verification_screen.dart'; // <-- Import the verification screen

// Standard style constants
const kDialogTitleStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
);

const kInputDecoration = InputDecoration(
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
);

final kElevatedButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: Colors.redAccent,
  foregroundColor: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
);

final kCancelButtonStyle = TextButton.styleFrom(
  foregroundColor: Colors.grey[700],
  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
);

// Email validation using RegExp.
bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  return emailRegex.hasMatch(email);
}

void showRegisterDialog(BuildContext context, FirebaseAuth auth,
    Function(String) updateDisplayName) {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Future<void> handleGoogleSignIn() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId:
            '517860411324-ufornbtjobhjds68519mdb9g0q276enk.apps.googleusercontent.com',
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        UserCredential userCredential =
            await auth.signInWithCredential(credential);
        updateDisplayName(userCredential.user?.displayName ?? "Google User");
        Navigator.of(context).pop(); // Close dialog.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In Successful! Welcome!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In Error: ${e.toString()}')),
      );
    }
  }

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 5,
        child: Container(
          constraints: BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Register', style: kDialogTitleStyle),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Enter your email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Enter your password',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                Text(
                  'Or register with Google:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: handleGoogleSignIn,
                  child: Image.asset(
                    'assets/img/google.png',
                    height: 40,
                  ),
                ),
                const SizedBox(height: 20),
                // Action buttons: Cancel and Register.
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: kCancelButtonStyle,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: kElevatedButtonStyle,
                      onPressed: () async {
                        final email = emailController.text.trim();
                        if (!isValidEmail(email)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Please enter a valid email address.'),
                            ),
                          );
                          return;
                        }
                        // Check if the email is already in use.
                        final signInMethods =
                            await auth.fetchSignInMethodsForEmail(email);
                        if (signInMethods.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'This email is already in use. Please use a different email address.'),
                            ),
                          );
                          return;
                        }
                        try {
                          UserCredential userCredential =
                              await auth.createUserWithEmailAndPassword(
                            email: email,
                            password: passwordController.text,
                          );
                          // Send verification email.
                          if (userCredential.user != null) {
                            await userCredential.user!.sendEmailVerification();
                          }
                          updateDisplayName(email.split('@')[0]);
                          Navigator.of(context).pop(); // Close register dialog.

                          // Navigate to the Email Verification Screen.
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  EmailVerificationScreen(auth: auth),
                            ),
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Registration Successful! A verification email has been sent. Please verify your email.'),
                            ),
                          );
                        } on FirebaseAuthException catch (e) {
                          if (e.code == 'email-already-in-use') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'This email is already in use. Please use a different email address.')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.message}')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }
                      },
                      child: Text('Register'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Link back to Sign In dialog.
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showSignInDialog(context, auth, updateDisplayName);
                  },
                  child: Text("Already have an account? Sign In"),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
