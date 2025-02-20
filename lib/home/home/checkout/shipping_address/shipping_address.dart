import 'package:ez8app/home/home/checkout/checkout.dart';
import 'package:ez8app/home/home/checkout/shipping_address/address_dialog/address_dialog.dart';
import 'package:ez8app/home/home/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShippingAddressPage extends StatefulWidget {
  final String hotelId;
  final String hotelName;
  final List<Map<String, dynamic>> cartItems;
  final double total;

  const ShippingAddressPage({
    Key? key,
    required this.hotelId,
    required this.hotelName,
    required this.cartItems,
    required this.total,
  }) : super(key: key);

  @override
  State<ShippingAddressPage> createState() => _ShippingAddressPageState();
}

class _ShippingAddressPageState extends State<ShippingAddressPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _addresses = [];
  Map<String, dynamic>? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .orderBy('createdAt', descending: false)
        .get();

    final list = snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();

    setState(() {
      _addresses = list;
    });
  }

  void _selectAddress(Map<String, dynamic> address) {
    setState(() {
      _selectedAddress = address;
    });
  }

  void _showAddAddressDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AddressDialog(
          isEdit: false,
          onSave: (address) {
            _saveNewAddress(address);
          },
        );
      },
    );
  }

  Future<void> _saveNewAddress(Map<String, dynamic> address) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .add(address);

    address['id'] = docRef.id;

    setState(() {
      _addresses.add(address);
      _selectedAddress = address;
    });
  }

  void _showEditAddressDialog(Map<String, dynamic> address) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AddressDialog(
          isEdit: true,
          existingAddress: address,
          onSave: (updatedAddress) {
            _updateAddress(address['id'], updatedAddress);
          },
        );
      },
    );
  }

  Future<void> _updateAddress(
      String docId, Map<String, dynamic> updatedAddress) async {
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('addresses')
        .doc(docId)
        .update(updatedAddress);

    setState(() {
      final idx = _addresses.indexWhere((a) => a['id'] == docId);
      if (idx != -1) {
        _addresses[idx] = {
          ..._addresses[idx],
          ...updatedAddress,
        };
      }
    });
  }

  Future<void> _deleteAddress(Map<String, dynamic> address) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docId = address['id'];
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .doc(docId)
        .delete();

    setState(() {
      _addresses.removeWhere((a) => a['id'] == docId);
      if (_selectedAddress != null && _selectedAddress!['id'] == docId) {
        _selectedAddress = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Column(
        children: [
          // Add Address Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _showAddAddressDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Add Shipping Address",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // Address List
          Expanded(
            child: _addresses.isEmpty
                ? const Center(
                    child: Text(
                      "No saved addresses found.",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  )
                : ListView.builder(
                    itemCount: _addresses.length,
                    itemBuilder: (context, index) {
                      final address = _addresses[index];
                      final isSelected = (_selectedAddress != null &&
                          _selectedAddress!['id'] == address['id']);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            address['contactName'] ?? 'No Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isSelected
                                  ? const Color.fromARGB(255, 125, 120, 120)
                                  : Colors.black,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Mobile: ${address['contactMobile'] ?? ''}"),
                              Text("Country: ${address['country'] ?? ''}"),
                              Text(
                                "Address: ${address['streetName'] ?? ''} ${address['houseNo'] ?? ''}, "
                                "${address['postalCode'] ?? ''}, ${address['city'] ?? ''}",
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Color.fromARGB(255, 14, 139, 80)),
                                onPressed: () {
                                  _showEditAddressDialog(address);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Color.fromARGB(255, 180, 53, 53)),
                                onPressed: () {
                                  _deleteAddress(address);
                                },
                              ),
                              isSelected
                                  ? const Icon(Icons.check_circle,
                                      color: Color.fromARGB(255, 25, 116, 201))
                                  : ElevatedButton(
                                      onPressed: () {
                                        _selectAddress(address);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(
                                            255, 41, 99, 201),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        "Select",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Confirm Selection Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _selectedAddress == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutPage(
                            hotelId: widget.hotelId,
                            hotelName: widget.hotelName,
                            cartItems: widget.cartItems,
                            total: widget.total,
                            // Pass the selected address:
                            selectedAddress: _selectedAddress,
                          ),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Confirm Selection",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
