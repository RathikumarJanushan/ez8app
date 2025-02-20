import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ez8app/home/home/checkout/shipping_address/shipping_address.dart';
import 'package:ez8app/home/home/custom_app_bar.dart';
import 'package:ez8app/home/home/showSignInDialog.dart';
import 'package:ez8app/home/translations/translations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// Helper function: Opens the “cart” bottom sheet for a given hotel.
/// It displays a header with a small hotel photo (if available) and the hotel name,
/// then shows the cart items for that hotel and an "Order Now" button with the
/// desired UI styling.
/// ---------------------------------------------------------------------------
Future<void> showCartForHotel(BuildContext context, String hotelId) async {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  // If not signed in, prompt for sign in.
  if (auth.currentUser == null) {
    showSignInDialog(context, auth, (String name) {
      showCartForHotel(context, hotelId);
    });
    return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return FractionallySizedBox(
        heightFactor: 0.8,
        child: StreamBuilder<QuerySnapshot>(
          stream: firestore
              .collection('carts')
              .where('userId', isEqualTo: auth.currentUser!.uid)
              .where('hotelId', isEqualTo: hotelId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(""), // Fallback in case translation fails.
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
                child: Text(Translations.text('cartEmpty')),
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
            // Use a FutureBuilder to load hotel details (name, photo, status).
            return FutureBuilder<DocumentSnapshot>(
              future: firestore.collection('hotels').doc(hotelId).get(),
              builder: (context, hotelSnapshot) {
                String hotelName = hotelId;
                String photoUrl = '';
                if (hotelSnapshot.hasData && hotelSnapshot.data!.exists) {
                  final hotelData =
                      hotelSnapshot.data!.data() as Map<String, dynamic>;
                  hotelName = hotelData['name'] as String? ?? hotelId;
                  photoUrl = hotelData['photoUrl'] as String? ?? '';
                  final status =
                      (hotelData['status'] as String? ?? "").toLowerCase();
                  if (status != "on") {
                    // If the shop is closed, display a message.
                    return Center(
                      child: Text(
                        Translations.text('shopClosed'),
                        style: const TextStyle(
                            fontSize: 18, color: Colors.redAccent),
                      ),
                    );
                  }
                }
                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Header: a Row with a small hotel photo and the hotel name.
                    Row(
                      children: [
                        // Show a circular avatar if photoUrl is available.
                        if (photoUrl.isNotEmpty)
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(photoUrl),
                          )
                        else
                          const CircleAvatar(
                            radius: 20,
                            child: Icon(Icons.hotel),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "$hotelName - ${Translations.text('yourCart')}",
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
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
                            Text(
                                "${data['quantity']} ${Translations.text('quantity')}"),
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
                    // Total row.
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
                    // "Order Now" button with the desired styling.
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
                              horizontal: 60, vertical: 30),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () async {
                          // Re-check the shop status.
                          final hotelDoc = await firestore
                              .collection('hotels')
                              .doc(hotelId)
                              .get();
                          if (!hotelDoc.exists) {
                            Navigator.of(context).pop();
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(Translations.text('shopClosed')),
                                content: Text(
                                    Translations.text('shopClosedMessage')),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(Translations.text('ok')),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }
                          final hotelData =
                              hotelDoc.data() as Map<String, dynamic>;
                          final status = (hotelData['status'] as String? ?? "")
                              .toLowerCase();
                          if (status != "on") {
                            Navigator.of(context).pop();
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(Translations.text('shopClosed')),
                                content: Text(
                                    Translations.text('shopClosedMessage')),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(Translations.text('ok')),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShippingAddressPage(
                                hotelId: hotelId,
                                hotelName: hotelName,
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
            );
          },
        ),
      );
    },
  );
}

/// ---------------------------------------------------------------------------
/// CartPage: Groups cart items by hotel and adds a “Show Cart” button for each.
/// When the button is pressed, the helper [showCartForHotel] is called to open
/// the detailed cart bottom sheet (which now includes the hotel photo and an
/// "Order Now" button with updated UI).
/// ---------------------------------------------------------------------------
class CartPage extends StatelessWidget {
  const CartPage({Key? key}) : super(key: key);

  /// Returns a stream of all cart items for the current user.
  Stream<QuerySnapshot> getCartStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('carts')
        .where('userId', isEqualTo: user.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Translations.currentLanguage,
      builder: (context, currentLang, child) {
        // The build method here will be triggered every time the language changes.
        return Scaffold(
          appBar: const CustomAppBar(automaticallyImplyLeading: false),
          body: StreamBuilder<QuerySnapshot>(
            stream: getCartStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(Translations.text('errorLoadingCartItems')),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final cartDocs = snapshot.data!.docs;
              if (cartDocs.isEmpty) {
                return Center(child: Text(Translations.text('cartEmpty')));
              }

              // Group the cart documents by hotelId.
              final Map<String, List<QueryDocumentSnapshot>> groupedByHotel =
                  {};
              for (var doc in cartDocs) {
                final data = doc.data() as Map<String, dynamic>;
                final hotelId = data['hotelId'] as String? ?? 'Unknown Hotel';
                groupedByHotel.putIfAbsent(hotelId, () => []).add(doc);
              }

              return ListView.builder(
                itemCount: groupedByHotel.length,
                itemBuilder: (context, index) {
                  final hotelId = groupedByHotel.keys.elementAt(index);
                  final items = groupedByHotel[hotelId]!;
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ExpansionTile(
                      // Display the hotel name (and optionally a small photo) in the header.
                      title: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('hotels')
                            .doc(hotelId)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final hotelData =
                                snapshot.data!.data() as Map<String, dynamic>;
                            final hotelName =
                                hotelData['name'] as String? ?? hotelId;
                            final photoUrl =
                                hotelData['photoUrl'] as String? ?? '';
                            return Row(
                              children: [
                                if (photoUrl.isNotEmpty)
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: NetworkImage(photoUrl),
                                  )
                                else
                                  const CircleAvatar(
                                    radius: 16,
                                    child: Icon(Icons.hotel, size: 16),
                                  ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    hotelName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                ),
                              ],
                            );
                          }
                          return Text(hotelId);
                        },
                      ),
                      children: [
                        // List each cart item for this hotel.
                        ...items.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(data['dishName']),
                            subtitle: Text(
                              '${Translations.text('quantity')}: ${data['quantity']}',
                            ),
                            trailing: Text(
                              "CHF ${(data['price'] * data['quantity']).toStringAsFixed(2)}",
                            ),
                          );
                        }).toList(),
                        // “Show Cart” button for this hotel.
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 20),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              // Call your helper function to show the detailed cart.
                              showCartForHotel(context, hotelId);
                            },
                            child: Text(Translations.text('showCart')),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
