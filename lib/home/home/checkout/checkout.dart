import 'dart:async';
import 'dart:convert';

import 'package:ez8app/home/home/custom_app_bar.dart';
import 'package:ez8app/home/home/hotals/MenuPage.dart';
import 'package:ez8app/home/translations/translations.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'shipping_address/shipping_address.dart';

import 'package:ez8app/services/stripe_service.dart';
import 'package:ez8app/home/home/loading_page.dart';

class CheckoutPage extends StatefulWidget {
  final String hotelId;
  final String hotelName;
  final List<Map<String, dynamic>> cartItems;
  final double total;

  // Add this parameter
  final Map<String, dynamic>? selectedAddress;

  const CheckoutPage({
    Key? key,
    required this.hotelId,
    required this.hotelName,
    required this.cartItems,
    required this.total,
    this.selectedAddress, // optional if not always passed
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Payment
  String _selectedPaymentMethod = 'card';

  // Addresses
  Map<String, dynamic>? _shippingAddress;
  String? _hotelAddress;

  // Store the route distance as a string (e.g., "10.3 km")
  String? _routeDistance;

  // Google Distance Matrix API Key (REPLACE WITH YOUR ACTUAL KEY)
  static const String _googleApiKey = 'AIzaSyDZ4hbmbThC3zLmVOCC6VyVgCEnip-Tmxw';

  @override
  void initState() {
    super.initState();

    // Listen for language changes
    Translations.currentLanguage.addListener(_onLanguageChanged);

    // If the user already selected an address from previous page
    if (widget.selectedAddress != null) {
      _shippingAddress = widget.selectedAddress;
    } else {
      // Otherwise, fetch the default from Firestore
      _fetchDefaultShippingAddress();
    }

    // Fetch the hotel address
    _fetchHotelAddress();
  }

  /// Trigger a rebuild when the language changes
  void _onLanguageChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    // Remove language listener to avoid memory leaks
    Translations.currentLanguage.removeListener(_onLanguageChanged);
    super.dispose();
  }

  // -------------------------------------------------------------------
  // 1) Firestore Data Fetching
  // -------------------------------------------------------------------

  /// Load the user's default shipping address from: users/UID/addresses
  Future<void> _fetchDefaultShippingAddress() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .orderBy('createdAt', descending: false)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      setState(() {
        _shippingAddress = {
          'id': doc.id,
          ...doc.data(),
        };
      });
    }

    // After fetching the address, try to calculate the distance if possible
    _updateRouteDistanceIfPossible();
  }

  /// Load the hotel's address from: hotels/hotelId
  Future<void> _fetchHotelAddress() async {
    try {
      final docSnap =
          await _firestore.collection('hotels').doc(widget.hotelId).get();
      if (docSnap.exists && docSnap.data() != null) {
        final data = docSnap.data()!;
        setState(() {
          _hotelAddress = data['address'] ?? "";
        });
      }
    } catch (e) {
      print("Error fetching hotel address: $e");
    }

    // After fetching the hotel address, try to calculate the distance if possible
    _updateRouteDistanceIfPossible();
  }

  /// Once we have both `_hotelAddress` and `_shippingAddress`, compute distance.
  void _updateRouteDistanceIfPossible() {
    if (_hotelAddress != null &&
        _hotelAddress!.isNotEmpty &&
        _shippingAddress != null) {
      _calculateRouteDistance();
    }
  }

  // -------------------------------------------------------------------
  // 2) Calculate Distance Between Two Addresses (Google Distance Matrix)
  // -------------------------------------------------------------------

  Future<void> _calculateRouteDistance() async {
    try {
      // Make sure we have valid addresses
      final shippingFullAddress =
          "${_shippingAddress!['streetName'] ?? ''} ${_shippingAddress!['houseNo'] ?? ''}, "
          "${_shippingAddress!['postalCode'] ?? ''} ${_shippingAddress!['city'] ?? ''}, "
          "${_shippingAddress!['country'] ?? ''}";

      final hotelFullAddress = _hotelAddress ?? "";

      if (shippingFullAddress.trim().isEmpty ||
          hotelFullAddress.trim().isEmpty) {
        return;
      }

      // Construct the request URL
      final uri = Uri.parse(
        "https://maps.googleapis.com/maps/api/distancematrix/json"
        "?units=metric"
        "&origins=${Uri.encodeComponent(hotelFullAddress)}"
        "&destinations=${Uri.encodeComponent(shippingFullAddress)}"
        "&key=$_googleApiKey",
      );

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' &&
            data['rows'] != null &&
            data['rows'].length > 0 &&
            data['rows'][0]['elements'] != null &&
            data['rows'][0]['elements'].length > 0 &&
            data['rows'][0]['elements'][0]['status'] == 'OK') {
          final distanceText =
              data['rows'][0]['elements'][0]['distance']['text'];
          // Example of distanceText = "10.5 km" or "1,234 km"

          setState(() {
            _routeDistance = distanceText;
          });
        } else {
          print("Distance Matrix error: $data");
        }
      } else {
        print("Distance Matrix HTTP error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error calculating route distance: $e");
    }
  }

  // -------------------------------------------------------------------
  // 3) Shipping Address Page Navigation
  // -------------------------------------------------------------------

  Future<void> _navigateToShippingAddressPage() async {
    final selectedAddress = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ShippingAddressPage(
          hotelId: widget.hotelId,
          hotelName: widget.hotelName,
          cartItems: widget.cartItems,
          total: widget.total,
        ),
      ),
    );

    if (selectedAddress != null) {
      setState(() {
        _shippingAddress = selectedAddress;
      });
      // Recalculate distance if possible
      _updateRouteDistanceIfPossible();
    }
  }

//----------------------KVP : save order for Cash on delevery &  stripe Changes for order confirmation-------------------------------------------

  Future<void> _saveOrder() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.text('userNotAuthenticated'))),
      );
      return;
    }

    if (_shippingAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.text('selectShippingAddressFirst')),
        ),
      );
      return;
    }

    double totalAmount = widget.total;
    String currency = "CHF";

    if (_selectedPaymentMethod == "card") {
      bool paymentSuccess =
          await StripeService.instance.makePayment(totalAmount, currency);

      if (paymentSuccess) {
        // Show the loading dialog immediately after payment succeeds
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const LoadingPage(),
        );

        await _processOrder(); //  Save order only after successful payment
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Card Payment failed. Please try again.")),
        );
      }
    } else {
      await _processOrder(); //  Save order for Cash on Delivery
    }
  }

  Future<void> _processOrder() async {
    String newOrderId = await _generateNextOrderId();
    if (newOrderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.text('errorGeneratingOrderID'))),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    final orderData = {
      'userId': user.uid,
      'hotelId': widget.hotelId,
      'hotelName': widget.hotelName,
      'hotelAddress': _hotelAddress ?? "",
      'cartItems': widget.cartItems,
      'total': widget.total,
      'status': 'pending',
      'shippingAddress': {
        'name': _shippingAddress!['contactName'] ?? '',
        'mobile': _shippingAddress!['contactMobile'] ?? '',
        'country': _shippingAddress!['country'] ?? '',
        'address':
            "${_shippingAddress!['streetName'] ?? ''} ${_shippingAddress!['houseNo'] ?? ''}, "
                "${_shippingAddress!['postalCode'] ?? ''} ${_shippingAddress!['city'] ?? ''}",
      },
      'paymentMethod': _selectedPaymentMethod,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      //  Save order in Firestore
      await _firestore.collection('BillOrder').doc(newOrderId).set(orderData);

      //  Remove cart items after order is saved
      final cartQuery = await _firestore
          .collection('carts')
          .where('userId', isEqualTo: user.uid)
          .where('hotelId', isEqualTo: widget.hotelId)
          .get();

      for (var doc in cartQuery.docs) {
        await doc.reference.delete();
      }

      setState(() {
        widget.cartItems.clear();
      });

      //  Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.text('orderPlaced'))),
      );

      //  Navigate to MenuPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MenuPage(
            hotelId: widget.hotelId,
            hotelName: widget.hotelName,
          ),
        ),
      );

      print(
          " Order successfully saved in Firestore with Order ID: $newOrderId");
    } catch (e) {
      print(" Error saving order to Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.text('errorPlacingOrder'))),
      );
    }
  }

  Future<String> _generateNextOrderId() async {
    try {
      final snapshot = await _firestore.collection('BillOrder').get();
      final pattern = RegExp(r'^AJ(\d+)$');
      int maxNum = 0;

      for (final doc in snapshot.docs) {
        final docId = doc.id;
        if (pattern.hasMatch(docId)) {
          final match = pattern.firstMatch(docId);
          final numericPart = int.parse(match!.group(1)!);
          if (numericPart > maxNum) {
            maxNum = numericPart;
          }
        }
      }

      maxNum++;
      return "AJ${maxNum.toString().padLeft(4, '0')}";
    } catch (e) {
      print("Error generating order ID: $e");
      return "";
    }
  }

  // -------------------------------------------------------------------
  // 5) Build the Checkout UI
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final containerWidth =
              constraints.maxWidth < 800 ? constraints.maxWidth * 0.95 : 800.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Container(
                width: containerWidth,
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // (B) Bill Details
                        Text(
                          Translations.text('billDetails'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "${Translations.text('hotel')}: ${widget.hotelName}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        if (_hotelAddress != null && _hotelAddress!.isNotEmpty)
                          Text(
                            "${Translations.text('address')}: $_hotelAddress",
                            style: const TextStyle(fontSize: 15),
                          )
                        else
                          Text(
                            "${Translations.text('address')}: ${Translations.text('loadingOrNotFound')}",
                            style: const TextStyle(fontSize: 15),
                          ),
                        const SizedBox(height: 20),

                        // (C) Shipping Address
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${Translations.text('shippingAddress')}:",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _navigateToShippingAddressPage,
                              icon: Icon(
                                Icons.edit,
                                color: Colors.blue.shade700,
                              ),
                              label: Text(
                                _shippingAddress == null
                                    ? Translations.text('addAddress')
                                    : Translations.text('change'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                backgroundColor: Colors.blue.shade50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _shippingAddress == null
                            ? Text(
                                Translations.text('noShippingAddressFound'),
                                style: TextStyle(color: Colors.grey.shade700),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${Translations.text('name')}: ${_shippingAddress!['contactName'] ?? ''}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      "${Translations.text('mobile')}: ${_shippingAddress!['contactMobile'] ?? ''}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      "${Translations.text('country')}: ${_shippingAddress!['country'] ?? ''}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      "${Translations.text('address')}: "
                                      "${_shippingAddress!['streetName'] ?? ''} "
                                      "${_shippingAddress!['houseNo'] ?? ''}, "
                                      "${_shippingAddress!['postalCode'] ?? ''} "
                                      "${_shippingAddress!['city'] ?? ''}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                        const SizedBox(height: 20),

                        // (D) Your Items + Distance
                        Text(
                          Translations.text('yourItems'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Divider(height: 20),
                        // Display route distance if available
                        if (_routeDistance != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Text(
                                  "${Translations.text('distance')}: ",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _routeDistance!,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        widget.cartItems.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Text(
                                    Translations.text('noItemsInCart'),
                                    style:
                                        TextStyle(color: Colors.grey.shade700),
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  ...widget.cartItems.map((item) {
                                    final dishName =
                                        item['dishName'] as String? ?? 'Dish';
                                    final quantity =
                                        item['quantity'] as int? ?? 1;
                                    final price =
                                        (item['price'] as num?)?.toDouble() ??
                                            0.0;
                                    final totalPrice = price * quantity;
                                    return Column(
                                      children: [
                                        ListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(
                                            dishName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          subtitle: Text(
                                            "${Translations.text('qty')}: $quantity",
                                          ),
                                          trailing: Text(
                                            "CHF ${totalPrice.toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Divider(),
                                      ],
                                    );
                                  }).toList(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${Translations.text('total')}:",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        "CHF ${widget.total.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                        const SizedBox(height: 20),

                        // (E) Payment Method
                        Text(
                          Translations.text('paymentMethod'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Divider(height: 20),
                        RadioListTile<String>(
                          title: Text(Translations.text('card')),
                          value: 'card',
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) {
                            setState(() => _selectedPaymentMethod = value!);
                          },
                        ),
                        RadioListTile<String>(
                          title: Text(Translations.text('cashOnDelivery')),
                          value: 'cash',
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) {
                            setState(() => _selectedPaymentMethod = value!);
                          },
                        ),
                        const SizedBox(height: 20),

                        // (F) Confirm Payment Button
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: _saveOrder,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 16,
                              ),
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              Translations.text('confirmPayment'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
