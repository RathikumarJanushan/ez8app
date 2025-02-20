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

  const MenuPage({
    Key? key,
    required this.hotelId,
    required this.hotelName,
  }) : super(key: key);

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      builder: (context) => AlertDialog(
        title: const Text("Shop Closed"),
        content: const Text("Please come again Opening time."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// Adds a menu item to the cart collection in Firestore.
  Future<void> addToCart(String dishName, double price, int quantity) async {
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
        setState(() {});
        // After sign-in is complete, re-attempt addToCart.
        addToCart(dishName, price, quantity);
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
      await doc.reference.update({'quantity': currentQuantity + quantity});
    } else {
      await _firestore.collection('carts').add({
        'userId': uid,
        'hotelId': widget.hotelId,
        'dishName': dishName,
        'price': price,
        'quantity': quantity,
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
        setState(() {});
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
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Error loading cart"),
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
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Your cart is empty"),
                );
              }

              // Calculate total using fold.
              final double total = cartDocs.fold(
                0.0,
                (sum, doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return sum + (data['price'] * data['quantity']);
                },
              );

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
                    return ListTile(
                      title: Text(data['dishName']),
                      subtitle: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () async {
                              int currentQty = data['quantity'];
                              if (currentQty > 1) {
                                await doc.reference
                                    .update({'quantity': currentQty - 1});
                              }
                            },
                          ),
                          Text("${data['quantity']}"),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () async {
                              int currentQty = data['quantity'];
                              await doc.reference
                                  .update({'quantity': currentQty + 1});
                            },
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "CHF ${(data['price'] * data['quantity']).toStringAsFixed(2)}",
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await doc.reference.delete();
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const Divider(),
                  ListTile(
                    title: const Text(
                      "Total",
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                          Navigator.of(context).pop();
                          _showClosedMessage();
                          return;
                        }

                        // If open, proceed → ShippingAddressPage
                        Navigator.of(context).pop(); // close bottom sheet

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
        appBar: const CustomAppBar(),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // WhatsApp Floating Action Button
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
            // Cart Floating Action Button with badge
            StreamBuilder<QuerySnapshot>(
              stream: cartStream(),
              builder: (context, snapshot) {
                int totalQuantity = 0;
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  totalQuantity = snapshot.data!.docs.fold<int>(0, (prev, doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    int quantity = 0;
                    if (data['quantity'] is int) {
                      quantity = data['quantity'];
                    } else if (data['quantity'] is String) {
                      quantity = int.tryParse(data['quantity'].toString()) ?? 0;
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
        body: FutureBuilder<DocumentSnapshot>(
          future: hotelFuture,
          builder: (context, hotelSnapshot) {
            if (hotelSnapshot.hasError) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Error loading menu items"),
              );
            }
            if (!hotelSnapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (!hotelSnapshot.data!.exists) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No menu items found"),
              );
            }

            final hotelData =
                hotelSnapshot.data!.data() as Map<String, dynamic>;
            final homeImageUrl = hotelData['homeImageUrl'] as String? ?? '';

            // Process hotel status and opening times.
            final status = (hotelData['status'] as String? ?? "").toLowerCase();
            String shopStatus = "";
            Color statusColor = Colors.black;
            if (status == "on") {
              shopStatus = "shop - open";
              statusColor = Colors.green;
            } else if (status == "off") {
              shopStatus = "shop - close";
              statusColor = Colors.red;
            }
            String startTimeString = "";
            String endTimeString = "";
            if (hotelData['start_time'] is Timestamp) {
              startTimeString = DateFormat('HH:mm')
                  .format((hotelData['start_time'] as Timestamp).toDate());
            } else if (hotelData['start_time'] is String) {
              startTimeString = hotelData['start_time'] as String;
            }
            if (hotelData['end_time'] is Timestamp) {
              endTimeString = DateFormat('HH:mm')
                  .format((hotelData['end_time'] as Timestamp).toDate());
            } else if (hotelData['end_time'] is String) {
              endTimeString = hotelData['end_time'] as String;
            }
            final timeRange = "$startTimeString - $endTimeString";

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1) Hotel Image
                  Container(
                    height: 250,
                    width: double.infinity,
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
                  const SizedBox(height: 16),

                  // 2) Hotel Header (name, status, opening time).
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${widget.hotelName} ${Translations.text('menu')}",
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
                        Text(
                          "Opening time: $timeRange",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),

                  // 3) Menu Items
                  FutureBuilder<QuerySnapshot>(
                    future: _firestore
                        .collection('menus')
                        .where('hotelId', isEqualTo: widget.hotelId)
                        .get(),
                    builder: (context, menuSnapshot) {
                      if (menuSnapshot.hasError) {
                        return Center(
                          child:
                              Text(Translations.text('errorLoadingMenuItems')),
                        );
                      }
                      if (!menuSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final allMenus = menuSnapshot.data!.docs;
                      if (allMenus.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text("No menu items found"),
                          ),
                        );
                      }
                      // Group menu items by category
                      final Map<String, List<QueryDocumentSnapshot>>
                          groupedByCategory = {};
                      for (var doc in allMenus) {
                        final data = doc.data() as Map<String, dynamic>;
                        final category =
                            data['menuCategory'] as String? ?? 'Uncategorized';
                        groupedByCategory
                            .putIfAbsent(category, () => [])
                            .add(doc);
                      }

                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: groupedByCategory.entries.map((entry) {
                            final category = entry.key;
                            final docsInCategory = entry.value;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category heading
                                Text(
                                  category,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Grid of items for this category
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 320,
                                    mainAxisExtent: 420,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
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
                                        menuData['description'] as String? ??
                                            '';
                                    final dynamic priceValue =
                                        menuData['price'];

                                    double price;
                                    if (priceValue is String) {
                                      price =
                                          double.tryParse(priceValue) ?? 0.0;
                                    } else if (priceValue is num) {
                                      price = priceValue.toDouble();
                                    } else {
                                      price = 0.0;
                                    }

                                    return MenuItemCard(
                                      dishName: dishName,
                                      imageUrl: imageUrl,
                                      price: price,
                                      description: description,
                                      onAdd: (int quantity) {
                                        addToCart(dishName, price, quantity);
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A stateful widget representing each menu item card with a quantity selector.
class MenuItemCard extends StatefulWidget {
  final String dishName;
  final String imageUrl;
  final double price;
  final String description;
  final Function(int quantity) onAdd;

  const MenuItemCard({
    Key? key,
    required this.dishName,
    required this.imageUrl,
    required this.price,
    required this.description,
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Menu image
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                image: widget.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(widget.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.imageUrl.isEmpty
                  ? Center(
                      child: Icon(
                        Icons.fastfood,
                        size: 70,
                        color: Colors.grey[700],
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            // Dish name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                widget.dishName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                widget.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            // Price
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "CHF ${widget.price.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),

            // Quantity selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: decrease,
                  icon: const Icon(Icons.remove),
                ),
                Text(
                  "$quantity",
                  style: const TextStyle(fontSize: 16),
                ),
                IconButton(
                  onPressed: increase,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const Spacer(),

            // "Add to Cart" button
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: () {
                  widget.onAdd(quantity);
                  // Reset quantity to 1 after adding.
                  setState(() => quantity = 1);
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
          ],
        ),
      ),
    );
  }
}
