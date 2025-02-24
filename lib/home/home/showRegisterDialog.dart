import 'package:ez8app/home/home/showSignInDialog.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'email_verification_screen.dart'; // <-- Import your verification screen
import 'package:ez8app/home/translations/translations.dart';

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
  foregroundColor: Colors.grey,
  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
);

// Email validation using RegExp.
bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  return emailRegex.hasMatch(email);
}

void showRegisterDialog(
  BuildContext context,
  FirebaseAuth auth,
  Function(String) updateDisplayName,
) {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  /// Updated: Remove the explicit `clientId`.
  /// On Android & iOS, the client ID typically comes from google-services.json
  /// (Android) or GoogleService-Info.plist (iOS).
  Future<void> handleGoogleSignIn() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return; // User canceled Google Sign-In.

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await auth.signInWithCredential(credential);

      // Update the display name from the Google user (if available).
      updateDisplayName(
          userCredential.user?.displayName ?? Translations.text('googleUser'));

      Navigator.of(context).pop(); // Close dialog.

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.text('googleSignInSuccessful')),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.text('googleSignInError',
                params: {'error': e.toString()}),
          ),
        ),
      );
    }
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 5,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dialog title: "Register"
                Text(Translations.text('register'), style: kDialogTitleStyle),
                const SizedBox(height: 20),
                // Email TextField.
                TextField(
                  controller: emailController,
                  decoration: kInputDecoration.copyWith(
                    labelText: Translations.text('enterYourEmail'),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                // Password TextField.
                TextField(
                  controller: passwordController,
                  decoration: kInputDecoration.copyWith(
                    labelText: Translations.text('enterYourPassword'),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                // "Or register with Google:" text.
                Text(
                  Translations.text('orRegisterWithGoogle'),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                // Google Sign-In option.
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
                      child: Text(Translations.text('cancel')),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: kElevatedButtonStyle,
                      onPressed: () async {
                        final email = emailController.text.trim();

                        if (!isValidEmail(email)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  Translations.text('pleaseEnterValidEmail')),
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
                              content:
                                  Text(Translations.text('emailAlreadyInUse')),
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
                          // Update display name to something more user-friendly.
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
                                  Translations.text('registrationSuccessful')),
                            ),
                          );
                        } on FirebaseAuthException catch (e) {
                          if (e.code == 'email-already-in-use') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    Translations.text('emailAlreadyInUse')),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      '${Translations.text('error')}: ${e.message}')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('${Translations.text('error')}: $e')),
                          );
                        }
                      },
                      child: Text(Translations.text('register')),
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
                  child: Text(Translations.text('alreadyHaveAccountSignIn')),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
