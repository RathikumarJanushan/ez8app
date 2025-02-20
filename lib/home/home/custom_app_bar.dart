import 'package:ez8app/home/home/mycart/cart.dart';
import 'package:ez8app/home/home/showRegisterDialog.dart';
import 'package:ez8app/home/home/showSignInDialog.dart';
import 'package:ez8app/home/translations/translations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool automaticallyImplyLeading;
  const CustomAppBar({Key? key, this.automaticallyImplyLeading = true})
      : super(key: key);

  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// This will display either:
  /// - "Sign In / Register" if no user is signed in
  /// - "Welcome <displayName>" if user is signed in
  String? displayStatus;

  @override
  void initState() {
    super.initState();
    // Listen to auth changes to update sign-in status.
    _auth.authStateChanges().listen((user) {
      setState(() {
        if (user == null) {
          displayStatus = Translations.text('signInRegister');
        } else {
          final name = user.email?.split('@')[0] ?? 'User';
          displayStatus = '${Translations.text('welcome')} $name';
        }
      });
    });

    // Handle initial state if user is already signed in.
    final user = _auth.currentUser;
    if (user != null) {
      final name = user.email?.split('@')[0] ?? 'User';
      displayStatus = '${Translations.text('welcome')} $name';
    } else {
      displayStatus = Translations.text('signInRegister');
    }

    // Rebuild when language changes
    Translations.currentLanguage.addListener(_languageListener);
  }

  void _languageListener() {
    setState(() {});
  }

  @override
  void dispose() {
    Translations.currentLanguage.removeListener(_languageListener);
    super.dispose();
  }

  /// Returns the flag asset for the *full language name*.
  /// E.g. "German" -> 'assets/flags/de.png'
  ///      "French" -> 'assets/flags/fr.png'
  ///      "English" -> 'assets/flags/en.png'
  String _flagAssetForLanguage(String language) {
    switch (language) {
      case 'German':
        return 'assets/flags/de.png';
      case 'French':
        return 'assets/flags/fr.png';
      case 'English':
      default:
        return 'assets/flags/en.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    // This is the *current* language as a full string, e.g. "English"
    final currentLang = Translations.currentLanguage.value;
    // We'll display just its flag
    final currentFlagPath = _flagAssetForLanguage(currentLang);

    return AppBar(
      automaticallyImplyLeading: widget.automaticallyImplyLeading,
      backgroundColor: Colors.white,
      elevation: 0,
      // Black icons in AppBar
      iconTheme: const IconThemeData(color: Colors.black),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Logo or any other item
          Row(
            children: [
              Image.asset(
                'assets/img/quickrunez8.png',
                height: 40,
              ),
              const SizedBox(width: 20),
            ],
          ),

          // Right: Two icons: (1) Flag for language, (2) Profile icon
          Row(
            children: [
              // (1) Language selection popup (flag only)
              PopupMenuButton<String>(
                tooltip: Translations.text('languageSelection'),
                icon: Image.asset(
                  currentFlagPath,
                  height: 24,
                  width: 24,
                ),
                onSelected: (value) {
                  setState(() {
                    // Update the language in your system
                    Translations.currentLanguage.value = value;
                  });
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'English',
                    child: Row(
                      children: [
                        Image.asset('assets/flags/en.png', height: 20),
                        const SizedBox(width: 8),
                        const Text('English', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'German',
                    child: Row(
                      children: [
                        Image.asset('assets/flags/de.png', height: 20),
                        const SizedBox(width: 8),
                        const Text('German', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'French',
                    child: Row(
                      children: [
                        Image.asset('assets/flags/fr.png', height: 20),
                        const SizedBox(width: 8),
                        const Text('French', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),

              // (2) Profile icon with a dropdown
              PopupMenuButton<String>(
                tooltip: Translations.text('profileMenu'),
                icon: const Icon(Icons.person, color: Colors.black),
                onSelected: (value) => _handleProfileSelection(value),
                itemBuilder: (context) => [
                  // First item is the sign-in status (disabled)
                  PopupMenuItem<String>(
                    enabled: false,
                    value: 'STATUS',
                    child: Text(
                      displayStatus ?? Translations.text('signInRegister'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  // Draw the dotted/solid line below it
                  const PopupMenuDivider(),

                  // My Order
                  PopupMenuItem<String>(
                    value: 'MyOrder',
                    child: Text(
                      Translations.text('myOrder'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),

                  // If user not signed in -> Show Sign In & Register
                  // else -> Show Sign Out
                  if (_auth.currentUser == null) ...[
                    PopupMenuItem<String>(
                      value: 'SignIn',
                      child: Text(
                        Translations.text('signIn'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'Register',
                      child: Text(
                        Translations.text('register'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ] else
                    PopupMenuItem<String>(
                      value: 'SignOut',
                      child: Text(
                        Translations.text('signOut'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Handle selections in the profile icon popup
  void _handleProfileSelection(String value) {
    switch (value) {
      case 'MyOrder':
        if (_auth.currentUser == null) {
          // If not signed in, prompt sign in
          showSignInDialog(context, _auth, (name) {
            setState(() {
              displayStatus = '${Translations.text('welcome')} $name';
            });
          });
        } else {
          // Navigate to MyOrder page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CartPage()),
          );
        }
        break;

      case 'SignIn':
        showSignInDialog(context, _auth, (name) {
          setState(() {
            displayStatus = '${Translations.text('welcome')} $name';
          });
        });
        break;

      case 'Register':
        showRegisterDialog(context, _auth, (name) {
          setState(() {
            displayStatus = '${Translations.text('welcome')} $name';
          });
        });
        break;

      case 'SignOut':
        _auth.signOut();
        setState(() {
          displayStatus = Translations.text('signInRegister');
        });
        break;

      // The disabled "STATUS" item won't trigger onSelected anyway
      default:
        break;
    }
  }
}
