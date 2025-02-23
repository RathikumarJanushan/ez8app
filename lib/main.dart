// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:ez8app/home/minitap/MainTabViewBar.dart';

import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Ensure that plugin services are initialized so that you can use them later.
  WidgetsFlutterBinding.ensureInitialized();
//---------------Old one--------------
  // // Initialize Firebase with the default options.
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  // // Run the app after Firebase has been initialized.
  // runApp(MyApp());

  try {
    Stripe.publishableKey =
        "pk_live_51Qvc73KKxmTEO1fzu4l5E0T3rhnhMO7eRtZCA39TnLa8fnq1rm84lOlcEZV7Mv6czQAhME1FDGXj43l2yg1APkD5000nYwiJKt";

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    runApp(MyApp());
  } catch (e) {
    // runApp(ErrorApp()); // Show error UI if initialization fails
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Tab Navigation',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainTabViewBar(),
    );
  }
}
