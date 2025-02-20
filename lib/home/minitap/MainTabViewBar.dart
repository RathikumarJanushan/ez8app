import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home/mycart/cart.dart';
import '../home/home.dart';
import '../home/account/account.dart';
import '../home/showSignInDialog.dart';

class MainTabViewBar extends StatefulWidget {
  @override
  _MainTabViewBarState createState() => _MainTabViewBarState();
}

class _MainTabViewBarState extends State<MainTabViewBar> {
  // Default selected tab is the Home tab (index 1)
  int _currentIndex = 1;

  // List of pages corresponding to each tab.
  final List<Widget> _pages = [
    CartPage(), // Index 0: Cart
    HomePage(), // Index 1: Home
    AccountPage(), // Index 2: Account
  ];

  // FirebaseAuth instance for authentication checks.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Handles tab selection. If the user taps on Cart (index 0) or Account (index 2)
  /// and is not logged in, prompt them to sign in.
  void _selectPage(int index) {
    if ((index == 0 || index == 2) && _auth.currentUser == null) {
      // Prompt sign in if not already logged in.
      showSignInDialog(context, _auth, (String name) {
        // After successful sign-in, switch to the selected tab.
        setState(() {
          _currentIndex = index;
        });
      });
    } else {
      // If already logged in or the Home tab is tapped, simply switch to that tab.
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        onTap: (int index) => _selectPage(index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
