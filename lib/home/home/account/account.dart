// account.dart
import 'package:ez8app/home/translations/translations.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For timestamp formatting
import '../custom_app_bar.dart'; // Adjust the import as needed.

class AccountPage extends StatefulWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  // Default selected order status is Pending (index 0)
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Listen for changes in the current language and rebuild when it changes.
    Translations.currentLanguage.addListener(_languageChanged);
  }

  void _languageChanged() {
    setState(() {}); // Trigger rebuild when language changes.
  }

  @override
  void dispose() {
    Translations.currentLanguage.removeListener(_languageChanged);
    super.dispose();
  }

  /// Helper widget to build an order status icon and label.
  Widget _buildOrderStatusItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool selected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 40,
            color: selected ? Colors.red : Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: selected ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget to build an order status icon with a count badge.
  Widget _buildStatusIconWithCount({
    required int index,
    required IconData icon,
    required String label,
    required String status,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildOrderStatusItem(index: index, icon: icon, label: label),
        // Position the badge at the top-right corner of the icon.
        Positioned(
          top: -4,
          right: -4,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('BillOrder')
                .where('userId',
                    isEqualTo:
                        FirebaseAuth.instance.currentUser?.uid ?? 'unknown')
                .where('status', isEqualTo: status)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                int count = snapshot.data!.docs.length;
                return Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ),
      ],
    );
  }

  /// Helper widget to build an order card displaying order details.
  Widget _buildOrderCard(DocumentSnapshot orderDoc) {
    final data = orderDoc.data() as Map<String, dynamic>;
    final hotelName = data['hotelName'] ?? '';
    final orderId = orderDoc.id;
    final total =
        data['total'] is num ? (data['total'] as num).toDouble() : 0.0;
    final shippingAddress = data['shippingAddress'] ?? {};
    final paymentMethod = data['paymentMethod'] ?? '';
    final timestamp = data['timestamp'] as Timestamp?;
    final formattedTimestamp = timestamp != null
        ? DateFormat('yyyy-MM-dd – kk:mm').format(timestamp.toDate())
        : Translations.text('notAvailable');

    // Delivery Time (only shown if not in Pending tab)
    final deliveryTimeTimestamp = data['delivery_time'] as Timestamp?;
    final formattedDeliveryTime = deliveryTimeTimestamp != null
        ? DateFormat('yyyy-MM-dd – kk:mm')
            .format(deliveryTimeTimestamp.toDate())
        : Translations.text('notAvailable');

    // Build a table for the cart items.
    final cartItems = data['cartItems'] as List<dynamic>? ?? [];
    final List<DataRow> dataRows = cartItems.map<DataRow>((item) {
      final dishName = item['dishName'] ?? Translations.text('dish');
      final quantity = item['quantity'] ?? 1;
      final price =
          item['price'] is num ? (item['price'] as num).toDouble() : 0.0;
      final itemTotal = quantity * price;
      return DataRow(cells: [
        DataCell(Text(dishName)),
        DataCell(Text('x$quantity')),
        DataCell(Text("CHF ${itemTotal.toStringAsFixed(2)}")),
      ]);
    }).toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotel (bold)
            Text("${Translations.text('hotel')}: $hotelName",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Order ID
            Text("${Translations.text('orderID')}: $orderId",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            // Timestamp
            Text("${Translations.text('timestamp')}: $formattedTimestamp",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            // Shipping Address
            Text(
                "${Translations.text('shippingAddress')}: ${shippingAddress['address'] ?? ''}",
                style: const TextStyle(fontSize: 16)),
            // Delivery Time (new row below Shipping Address if not Pending)
            if (_selectedIndex != 0) ...[
              const SizedBox(height: 8),
              Text(
                  "${Translations.text('deliveryTime')}: $formattedDeliveryTime",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  )),
            ],
            const SizedBox(height: 16),
            // Items header
            Text("${Translations.text('cartItems')}:",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DataTable(
              columns: [
                DataColumn(label: Text(Translations.text('dish'))),
                DataColumn(label: Text(Translations.text('qty'))),
                DataColumn(label: Text(Translations.text('price'))),
              ],
              rows: dataRows,
            ),
            const SizedBox(height: 16),
            // Total (bold)
            Text(
                "${Translations.text('total')}: CHF ${total.toStringAsFixed(2)}",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Payment
            Text("${Translations.text('payment')}: $paymentMethod",
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  /// Builds a stream of orders for the given status.
  Widget _buildOrdersForStatus(String status) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text(Translations.text('noUserLoggedIn')));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('BillOrder')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text(Translations.text('noOrdersFound')));
        }
        return Column(
          children:
              snapshot.data!.docs.map((doc) => _buildOrderCard(doc)).toList(),
        );
      },
    );
  }

  /// Returns the content widget based on the selected order status.
  Widget _buildOrderContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildOrdersForStatus("pending");
      case 1:
        return _buildOrdersForStatus("kitchen");
      case 2:
        return _buildOrdersForStatus(
            "ready"); // Shipped orders have status "ready"
      case 3:
        return _buildOrdersForStatus(
            "delivered"); // Complete orders have status "delivered"
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve the user's email from Firebase Auth.
    final String userEmail = FirebaseAuth.instance.currentUser?.email ??
        Translations.text('yourAccount');

    return Scaffold(
      appBar: const CustomAppBar(
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Welcome message
          Text("${Translations.text('welcome')}, $userEmail",
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          // "My Order" heading
          Text(Translations.text('myOrder'),
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Row of order status icons with count badges.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatusIconWithCount(
                index: 0,
                icon: Icons.pending,
                label: Translations.text('pending'),
                status: 'pending',
              ),
              _buildStatusIconWithCount(
                index: 1,
                icon: Icons.kitchen,
                label: Translations.text('kitchen'),
                status: 'kitchen',
              ),
              _buildStatusIconWithCount(
                index: 2,
                icon: Icons.local_shipping,
                label: Translations.text('shipped'),
                status: 'ready',
              ),
              _buildStatusIconWithCount(
                index: 3,
                icon: Icons.check_circle,
                label: Translations.text('complete'),
                status: 'delivered',
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Display the content for the selected order status below the icons.
          _buildOrderContent(),
        ],
      ),
    );
  }
}
