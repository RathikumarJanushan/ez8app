import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ez8app/home/home/checkout/shipping_address/shipping_address.dart';
import 'package:ez8app/home/home/custom_app_bar.dart';

import 'package:ez8app/home/home/showSignInDialog.dart';

import 'package:ez8app/home/translations/translations.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // For date formatting

class MenuPage extends StatefulWidget {
  final String hotelId;
  final String hotelName;

  const MenuPage({Key? key, required this.hotelId, required this.hotelName})
      : super(key: key);

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Future to fetch the hotel's document (with image, status, opening times, etc.).
  late Future<DocumentSnapshot> hotelFuture;

  @override
  void initState() {
    super.initState();
    // Listen for language changes so we rebuild this page.
    Translations.currentLanguage.addListener(_languageChanged);

    // Listen for auth state changes so that cart count updates automatically.
    _auth.userChanges().listen((user) {
      setState(() {}); // Rebuild to show/hide cart items.
    });

    // Initialize the Future for hotel data.
    hotelFuture = _firestore.collection('hotels').doc(widget.hotelId).get();
  }

  void _languageChanged() {
    setState(() {
      // Rebuild the UI when language changes.
    });
  }

  @override
  void dispose() {
    Translations.currentLanguage.removeListener(_languageChanged);
    super.dispose();
  }

  /// Launches WhatsApp chat to the specified phone number.
  Future<void> openWhatsApp() async {
    final whatsappUrl = "https://wa.me/94766241965";
    if (await canLaunch(whatsappUrl)) {
      await launch(whatsappUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.text('whatsappError'))),
      );
    }
  }

  /// Helper function to check if the shop is currently "on" (open) or "off" (closed).
  Future<bool> _checkShopStatus() async {
    final doc = await _firestore.collection('hotels').doc(widget.hotelId).get();
    if (!doc.exists) return false;

    final hotelData = doc.data() as Map<String, dynamic>;
    final status = (hotelData['status'] as String? ?? "").toLowerCase();
    return status == "on";
  }

  /// Shows a pop-up dialog telling the user the shop is closed.
  void _showClosedMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Shop Closed"),
          content: const Text("Please come again Opening time."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  /// Adds a menu item to the cart collection in Firestore.
  /// The [selectedOptions] parameter contains any additional options the user selected.
  Future<void> addToCart(String dishName, double price, int quantity,
      {List<Map<String, dynamic>> selectedOptions = const []}) async {
    // 1. First check if the shop is open.
    final isShopOpen = await _checkShopStatus();
    if (!isShopOpen) {
      // If closed, show dialog and return.
      _showClosedMessage();
      return;
    }

    // 2. If user not signed in, prompt sign in dialog.
    if (_auth.currentUser == null) {
      showSignInDialog(context, _auth, (String name) {
        setState(() {}); // Update UI once signed in.
        // After sign-in is complete, re-attempt addToCart.
        addToCart(dishName, price, quantity, selectedOptions: selectedOptions);
      });
      return;
    }

    final String uid = _auth.currentUser!.uid;

    // Check if a cart document for this dish already exists for the user & hotel.
    final QuerySnapshot query = await _firestore
        .collection('carts')
        .where('userId', isEqualTo: uid)
        .where('hotelId', isEqualTo: widget.hotelId)
        .where('dishName', isEqualTo: dishName)
        .get();

    if (query.docs.isNotEmpty) {
      final DocumentSnapshot doc = query.docs.first;
      int currentQuantity = doc['quantity'];
      await doc.reference.update({
        'quantity': currentQuantity + quantity,
        'options': selectedOptions,
      });
    } else {
      await _firestore.collection('carts').add({
        'userId': uid,
        'hotelId': widget.hotelId,
        'dishName': dishName,
        'price': price,
        'quantity': quantity,
        'options': selectedOptions,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Translations.text('addedToChat', params: {
            'quantity': quantity,
            'dishName': dishName,
          }),
        ),
      ),
    );
  }

  /// Returns a stream of cart items for the current user and hotel.
  Stream<QuerySnapshot> cartStream() {
    if (_auth.currentUser == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('carts')
        .where('userId', isEqualTo: _auth.currentUser!.uid)
        .where('hotelId', isEqualTo: widget.hotelId)
        .snapshots();
  }

  /// Shows the saved cart items in a bottom sheet.
  void showCart() async {
    // If not logged in, show sign-in dialog first.
    if (_auth.currentUser == null) {
      showSignInDialog(context, _auth, (String name) {
        setState(() {}); // Update UI once signed in.
      });
      return;
    }

    // If logged in, proceed with the cart bottom sheet.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.8, // Bottom sheet takes 80% of screen height.
          child: StreamBuilder<QuerySnapshot>(
            stream: cartStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(Translations.text('errorLoadingChat')),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final cartDocs = snapshot.data!.docs;
              if (cartDocs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(Translations.text('yourChatEmpty')),
                );
              }

              // Calculate total including extra option prices.
              double total = 0;
              for (var doc in cartDocs) {
                final data = doc.data() as Map<String, dynamic>;
                double basePrice = 0.0;
                if (data['price'] is String) {
                  basePrice = double.tryParse(data['price'].toString()) ?? 0.0;
                } else if (data['price'] is num) {
                  basePrice = (data['price'] as num).toDouble();
                }
                int quantity = 0;
                if (data['quantity'] is int) {
                  quantity = data['quantity'];
                } else {
                  quantity = int.tryParse(data['quantity'].toString()) ?? 0;
                }
                double optionsExtra = 0.0;
                if (data['options'] != null && data['options'] is List) {
                  List<dynamic> options = data['options'] as List<dynamic>;
                  for (var opt in options) {
                    double optPrice = 0.0;
                    if (opt['price'] is num) {
                      optPrice = (opt['price'] as num).toDouble();
                    } else {
                      optPrice =
                          double.tryParse(opt['price'].toString()) ?? 0.0;
                    }
                    optionsExtra += optPrice;
                  }
                }
                total += (basePrice + optionsExtra) * quantity;
              }

              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Text(
                    "${widget.hotelName} - ${Translations.text('yourChat')}",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // List each cart item.
                  ...cartDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    double basePrice = 0.0;
                    if (data['price'] is String) {
                      basePrice =
                          double.tryParse(data['price'].toString()) ?? 0.0;
                    } else if (data['price'] is num) {
                      basePrice = (data['price'] as num).toDouble();
                    }
                    int quantity = 0;
                    if (data['quantity'] is int) {
                      quantity = data['quantity'];
                    } else {
                      quantity = int.tryParse(data['quantity'].toString()) ?? 0;
                    }
                    double optionsExtra = 0.0;
                    List<dynamic> options = [];
                    if (data['options'] != null && data['options'] is List) {
                      options = data['options'] as List<dynamic>;
                      for (var opt in options) {
                        double optPrice = 0.0;
                        if (opt['price'] is num) {
                          optPrice = (opt['price'] as num).toDouble();
                        } else {
                          optPrice =
                              double.tryParse(opt['price'].toString()) ?? 0.0;
                        }
                        optionsExtra += optPrice;
                      }
                    }
                    double lineTotal = (basePrice + optionsExtra) * quantity;

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(data['dishName']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Quantity selector row.
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () async {
                                    if (quantity > 1) {
                                      await doc.reference
                                          .update({'quantity': quantity - 1});
                                    }
                                  },
                                ),
                                Text("$quantity"),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () async {
                                    await doc.reference
                                        .update({'quantity': quantity + 1});
                                  },
                                ),
                              ],
                            ),
                            // Show selected options, if any.
                            if (options.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: options.map((opt) {
                                  final optName =
                                      opt['option'] as String? ?? '';
                                  double optPrice = 0.0;
                                  if (opt['price'] is num) {
                                    optPrice = (opt['price'] as num).toDouble();
                                  } else {
                                    optPrice = double.tryParse(
                                            opt['price'].toString()) ??
                                        0.0;
                                  }
                                  return Text(
                                    "$optName (+ CHF ${optPrice.toStringAsFixed(2)})",
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  );
                                }).toList(),
                              )
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "CHF ${lineTotal.toStringAsFixed(2)}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await doc.reference.delete();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const Divider(),
                  ListTile(
                    title: Text(
                      Translations.text('total'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      "CHF ${total.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 60,
                          vertical: 30,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () async {
                        // Check shop status before proceeding.
                        final isShopOpen = await _checkShopStatus();
                        if (!isShopOpen) {
                          Navigator.of(context)
                              .pop(); // Close bottom sheet first
                          _showClosedMessage();
                          return;
                        }

                        // If open, proceed.
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShippingAddressPage(
                              hotelId: widget.hotelId,
                              hotelName: widget.hotelName,
                              cartItems: cartDocs
                                  .map((doc) =>
                                      doc.data() as Map<String, dynamic>)
                                  .toList(),
                              total: total,
                            ),
                          ),
                        );
                      },
                      child: Text(Translations.text('orderNow')),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Override the system back button so that we explicitly go to the home page.
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamed(context, '/');
        return false;
      },
      child: Scaffold(
        appBar: CustomAppBar(),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // WhatsApp Floating Action Button.
            FloatingActionButton(
              heroTag: "whatsapp",
              onPressed: openWhatsApp,
              backgroundColor: Colors.green,
              child: Image.asset(
                'assets/img/whatsapp.png',
                height: 32,
                width: 32,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            // Cart Floating Action Button with badge.
            StreamBuilder<QuerySnapshot>(
              stream: cartStream(),
              builder: (context, snapshot) {
                int totalQuantity = 0;
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  totalQuantity = snapshot.data!.docs.fold<int>(0, (prev, doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    int quantity;
                    if (data['quantity'] is int) {
                      quantity = data['quantity'];
                    } else if (data['quantity'] is String) {
                      quantity = int.tryParse(data['quantity'].toString()) ?? 0;
                    } else {
                      quantity = 0;
                    }
                    return prev + quantity;
                  });
                }
                return FloatingActionButton(
                  heroTag: "chat",
                  onPressed: showCart,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.shopping_cart),
                      if (totalQuantity > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$totalQuantity',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //------------------------------------------------------------
              // 1) HOTEL IMAGE (with fixed ratio logic 3:6 or pinned 3"x6")
              //------------------------------------------------------------
              FutureBuilder<DocumentSnapshot>(
                future: hotelFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(Translations.text('errorLoadingMenuItems')),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (!snapshot.data!.exists) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(Translations.text('noMenuItemsFound')),
                    );
                  }

                  final hotelData =
                      snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  final homeImageUrl =
                      hotelData['homeImageUrl'] as String? ?? '';

                  // Calculate screen width in "inches" approximately.
                  // 160 logical pixels = 1 inch on Android's mdpi baseline.
                  final deviceWidthDp = MediaQuery.of(context).size.width;
                  final deviceWidthInches = deviceWidthDp / 160.0;

                  // If screen is more than 6 inches wide, fix the image to 3"x6" on the right side.
                  // Otherwise, use a 3:6 (height:width) ratio container that fills the width.
                  if (deviceWidthInches > 6) {
                    // 6 inches wide => 6*160 dp, 3 inches high => 3*160 dp
                    final fixedWidth = 6 * 160.0;
                    final fixedHeight = 3 * 160.0;

                    return SizedBox(
                      height: fixedHeight,
                      width: double.infinity,
                      child: Row(
                        children: [
                          // The left side fixed 3"x6" frame for the image
                          Container(
                            width: fixedWidth,
                            height: fixedHeight,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              image: homeImageUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(homeImageUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: homeImageUrl.isEmpty
                                ? Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 70,
                                      color: Colors.grey[700],
                                    ),
                                  )
                                : null,
                          ),
                          // The rest is white
                          Expanded(
                            child: Container(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Screen <= 6 inches: ratio 3:6 => height = width/2
                    final containerHeight = deviceWidthDp / 2;
                    return SizedBox(
                      width: double.infinity,
                      height: containerHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          image: homeImageUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(homeImageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: homeImageUrl.isEmpty
                            ? Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 70,
                                  color: Colors.grey[700],
                                ),
                              )
                            : null,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              //------------------------------------------------------------
              // 2) MENU ITEMS (from "menus" collection), grouped by category
              //------------------------------------------------------------
              FutureBuilder<QuerySnapshot>(
                future: _firestore
                    .collection('menus')
                    .where('hotelId', isEqualTo: widget.hotelId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(Translations.text('errorLoadingMenuItems')),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allMenus = snapshot.data!.docs;
                  if (allMenus.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(Translations.text('noMenuItemsFound')),
                      ),
                    );
                  }

                  // Group menu items by category.
                  final Map<String, List<QueryDocumentSnapshot>>
                      groupedByCategory = {};
                  for (var doc in allMenus) {
                    final data = doc.data() as Map<String, dynamic>;
                    final category =
                        data['menuCategory'] as String? ?? 'Uncategorized';
                    if (!groupedByCategory.containsKey(category)) {
                      groupedByCategory[category] = [];
                    }
                    groupedByCategory[category]!.add(doc);
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with hotel name, shop status, and opening times.
                        FutureBuilder<DocumentSnapshot>(
                          future: hotelFuture,
                          builder: (context, snapshot) {
                            // Default header values.
                            String hotelHeader =
                                "${widget.hotelName} ${Translations.text('menu')}";
                            String shopStatus = "";
                            Color statusColor = Colors.black;
                            String timeRange = "";
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final hotelData = snapshot.data!.data()
                                      as Map<String, dynamic>? ??
                                  {};
                              final status =
                                  (hotelData['status'] as String? ?? "")
                                      .toLowerCase();
                              String startTimeString = "";
                              String endTimeString = "";

                              // Convert start_time.
                              if (hotelData['start_time'] is Timestamp) {
                                final startTimestamp =
                                    hotelData['start_time'] as Timestamp;
                                startTimeString = DateFormat('HH:mm')
                                    .format(startTimestamp.toDate());
                              } else if (hotelData['start_time'] is String) {
                                startTimeString =
                                    hotelData['start_time'] as String;
                              }
                              // Convert end_time.
                              if (hotelData['end_time'] is Timestamp) {
                                final endTimestamp =
                                    hotelData['end_time'] as Timestamp;
                                endTimeString = DateFormat('HH:mm')
                                    .format(endTimestamp.toDate());
                              } else if (hotelData['end_time'] is String) {
                                endTimeString = hotelData['end_time'] as String;
                              }

                              // Determine shop status and color.
                              if (status == "on") {
                                shopStatus = "shop - open";
                                statusColor = Colors.green;
                              } else if (status == "off") {
                                shopStatus = "shop - close";
                                statusColor = Colors.red;
                              }
                              timeRange = "$startTimeString - $endTimeString";
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hotelHeader,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  shopStatus,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Always display the opening time.
                                Text(
                                  "Opening time: $timeRange",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // For each category, show a heading and a List of items.
                        ...groupedByCategory.entries.map((entry) {
                          final category = entry.key;
                          final docsInCategory = entry.value;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category heading.
                              Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // List of items for this category.
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: docsInCategory.length,
                                itemBuilder: (context, index) {
                                  final menuDoc = docsInCategory[index];
                                  final menuData =
                                      menuDoc.data() as Map<String, dynamic>;
                                  final dishName =
                                      menuData['dishName'] as String? ??
                                          Translations.text('dish');
                                  final imageUrl =
                                      menuData['imageUrl'] as String? ?? '';
                                  final description =
                                      menuData['description'] as String? ?? '';
                                  final dynamic priceValue = menuData['price'];

                                  double price;
                                  if (priceValue is String) {
                                    price = double.tryParse(priceValue) ?? 0.0;
                                  } else if (priceValue is num) {
                                    price = priceValue.toDouble();
                                  } else {
                                    price = 0.0;
                                  }

                                  // Get any additional options (if available)
                                  final List<dynamic> options =
                                      (menuData['options'] as List<dynamic>?) ??
                                          [];

                                  return MenuItemCard(
                                    dishName: dishName,
                                    imageUrl: imageUrl,
                                    price: price,
                                    description: description,
                                    options: options,
                                    onAdd: (int quantity,
                                        List<Map<String, dynamic>>
                                            selectedOptions) {
                                      addToCart(dishName, price, quantity,
                                          selectedOptions: selectedOptions);
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

///
/// A stateful widget representing each menu item row with a quantity selector.
/// The image is on the right side, while the text and actions are on the left.
/// If the dish has additional options (with extra price), the user can select one
/// or more of them in the "details" dialog and they will be saved in the cart.
///
class MenuItemCard extends StatefulWidget {
  final String dishName;
  final String imageUrl;
  final double price;
  final String description;
  final List<dynamic> options; // Each option should be a Map<String, dynamic>
  final Function(int quantity, List<Map<String, dynamic>> selectedOptions)
      onAdd;

  const MenuItemCard({
    Key? key,
    required this.dishName,
    required this.imageUrl,
    required this.price,
    required this.description,
    required this.options,
    required this.onAdd,
  }) : super(key: key);

  @override
  _MenuItemCardState createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<MenuItemCard> {
  int quantity = 1;

  void increase() {
    setState(() => quantity++);
  }

  void decrease() {
    if (quantity > 1) {
      setState(() => quantity--);
    }
  }

  /// Show all details in a dialog, including the full description,
  /// an image (if available), quantity selector, and if available, a list of option checkboxes.
  void _showDetailsDialog(BuildContext context) {
    // We'll keep a local copy of quantity inside the dialog so the user can adjust it there.
    int dialogQuantity = quantity;
    // Prepare selection flags for each available option.
    List<bool> selectedFlags = List<bool>.filled(widget.options.length, false);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Build options selection UI if any options exist.
            Widget optionsWidget = Container();
            if (widget.options.isNotEmpty) {
              optionsWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Select Options:"),
                  Column(
                    children: List.generate(widget.options.length, (index) {
                      final option =
                          widget.options[index] as Map<String, dynamic>;
                      final optionName = option['option'] as String? ?? '';
                      final optionPrice = option['price'] as num? ?? 0;
                      return CheckboxListTile(
                        title: Text(
                            "$optionName (+ CHF ${optionPrice.toStringAsFixed(2)})"),
                        value: selectedFlags[index],
                        onChanged: (value) {
                          setStateDialog(() {
                            selectedFlags[index] = value ?? false;
                          });
                        },
                      );
                    }),
                  )
                ],
              );
            }
            return AlertDialog(
              title: Text(widget.dishName),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.imageUrl.isNotEmpty) ...[
                      Image.network(widget.imageUrl),
                      const SizedBox(height: 8),
                    ],
                    Text(widget.description),
                    const SizedBox(height: 16),
                    Text(
                      "CHF ${widget.price.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    optionsWidget,
                    const SizedBox(height: 8),
                    // Quantity selector in the dialog.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (dialogQuantity > 1) {
                              setStateDialog(() {
                                dialogQuantity--;
                              });
                            }
                          },
                          icon: const Icon(Icons.remove),
                        ),
                        Text("$dialogQuantity"),
                        IconButton(
                          onPressed: () {
                            setStateDialog(() {
                              dialogQuantity++;
                            });
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          child: const Center(
                            child: Text(
                              "Close",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          onTap: () {
                            // Build list of selected options.
                            List<Map<String, dynamic>> selectedOptions = [];
                            for (int i = 0; i < widget.options.length; i++) {
                              if (selectedFlags[i]) {
                                selectedOptions.add(
                                    widget.options[i] as Map<String, dynamic>);
                              }
                            }
                            widget.onAdd(dialogQuantity, selectedOptions);
                            setState(() {
                              quantity = dialogQuantity;
                            });
                            Navigator.pop(context);
                          },
                          child: Center(
                            child: Text(
                              Translations.text('addToChat'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            );
          },
        );
      },
    );
  }

  /// Builds a truncated description (max 3 lines) with a "Read more" link if needed.
  Widget _buildDescriptionText(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(
          text: widget.description,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        );

        final textPainter = TextPainter(
          text: textSpan,
          maxLines: 3,
          ellipsis: '...',
          textDirection: Directionality.of(context),
        );

        textPainter.layout(maxWidth: constraints.maxWidth);
        final didExceedMaxLines = textPainter.didExceedMaxLines;

        if (!didExceedMaxLines) {
          return Text(
            widget.description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.start,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.start,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _showDetailsDialog(context),
                child: Text(
                  Translations.text('readMore'),
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            blurRadius: 3,
            color: Colors.black12,
            offset: Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: dish info, price, quantity, add button
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dish name
                Text(
                  widget.dishName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                // Truncated description with "Read more" link.
                _buildDescriptionText(context),
                const SizedBox(height: 8),
                // Price
                Text(
                  "CHF ${widget.price.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Quantity row
                Row(
                  children: [
                    IconButton(
                      onPressed: decrease,
                      icon: const Icon(Icons.remove),
                      iconSize: 20,
                      splashRadius: 20,
                    ),
                    Text(
                      "$quantity",
                      style: const TextStyle(fontSize: 16),
                    ),
                    IconButton(
                      onPressed: increase,
                      icon: const Icon(Icons.add),
                      iconSize: 20,
                      splashRadius: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // "Add to Cart" button.
                SizedBox(
                  width: 150,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // If the dish has available options, show the details dialog to let user select options.
                      // Otherwise, directly call onAdd with an empty options list.
                      if (widget.options.isNotEmpty) {
                        _showDetailsDialog(context);
                      } else {
                        widget.onAdd(quantity, []);
                        setState(() => quantity = 1);
                      }
                    },
                    child: Text(
                      Translations.text('addToChat'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Right side: dish image
          SizedBox(
            width: 110,
            height: 110,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: widget.imageUrl.isNotEmpty
                  ? Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.fastfood,
                        size: 40,
                        color: Colors.grey[700],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
