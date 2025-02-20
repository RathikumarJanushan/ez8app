// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:ez8app/home/minitap/MainTabViewBar.dart';

void main() async {
  // Ensure that plugin services are initialized so that you can use them later.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the default options.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run the app after Firebase has been initialized.
  runApp(MyApp());
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
