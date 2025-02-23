import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Standard style constants
const kDialogTitleStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
);

// Change from const to final to avoid invoking a method in a constant expression.
final kInputDecoration = InputDecoration(
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

class EmailVerificationScreen extends StatefulWidget {
  final FirebaseAuth auth;

  const EmailVerificationScreen({Key? key, required this.auth})
      : super(key: key);

  @override
  _EmailVerificationScreenState createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool isEmailVerified = false;
  bool canResendEmail = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    // Check if the user's email is already verified.
    isEmailVerified = widget.auth.currentUser?.emailVerified ?? false;

    // If not verified, send a verification email and start periodic checks.
    if (!isEmailVerified) {
      sendVerificationEmail();
      timer = Timer.periodic(
          const Duration(seconds: 3), (_) => checkEmailVerified());
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> sendVerificationEmail() async {
    try {
      final user = widget.auth.currentUser;
      await user?.sendEmailVerification();
      setState(() {
        canResendEmail = false;
      });
      // Wait for a short duration before enabling the resend button.
      await Future.delayed(const Duration(seconds: 5));
      setState(() {
        canResendEmail = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error pls try again !')),
      );
    }
  }

  Future<void> checkEmailVerified() async {
    // Force a reload of the user's data.
    await widget.auth.currentUser?.reload();
    setState(() {
      isEmailVerified = widget.auth.currentUser?.emailVerified ?? false;
    });
    if (isEmailVerified) {
      timer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verified!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isEmailVerified
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Your email has been verified! You can now access the app.',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: kElevatedButtonStyle,
                      onPressed: () {
                        // Navigate to your main app or sign in page.
                        // Make sure you have defined the '/home' route in your MaterialApp.
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'A verification email has been sent to your email address. Please check your inbox and click the link to verify your account.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: kElevatedButtonStyle,
                    onPressed: sendVerificationEmail,
                    child: const Text('Resend Email'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () async {
                      await widget.auth.signOut();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  )
                ],
              ),
      ),
    );
  }
}
