// import 'package:ez8/home/custom_app_bar.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class ShippingAddressPage extends StatefulWidget {
//   const ShippingAddressPage({Key? key}) : super(key: key);

//   @override
//   State<ShippingAddressPage> createState() => _ShippingAddressPageState();
// }

// class _ShippingAddressPageState extends State<ShippingAddressPage> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // Replace with your valid Google Geocoding API key
//   final String _gMapsApiKey = "AIzaSyD0N_-gaH44ULCwOZ3lya3IyyWscM2wldA";

//   List<Map<String, dynamic>> _addresses = [];
//   Map<String, dynamic>? _selectedAddress;

//   @override
//   void initState() {
//     super.initState();
//     _fetchAddresses();
//   }

//   // -----------------------------------------------------------------------
//   // 1) Fetch addresses from Firestore
//   // -----------------------------------------------------------------------
//   Future<void> _fetchAddresses() async {
//     final user = _auth.currentUser;
//     if (user == null) return;

//     final snapshot = await _firestore
//         .collection('users')
//         .doc(user.uid)
//         .collection('addresses')
//         .orderBy('createdAt', descending: false)
//         .get();

//     final list = snapshot.docs.map((doc) {
//       return {
//         'id': doc.id,
//         ...doc.data(),
//       };
//     }).toList();

//     setState(() {
//       _addresses = list;
//     });
//   }

//   // -----------------------------------------------------------------------
//   // 2) Select + Confirm an address
//   // -----------------------------------------------------------------------
//   void _selectAddress(Map<String, dynamic> address) {
//     setState(() {
//       _selectedAddress = address;
//     });
//   }

//   void _confirmSelection() {
//     if (_selectedAddress != null) {
//       Navigator.pop(context, _selectedAddress);
//     } else {
//       Navigator.pop(context); // or show a warning
//     }
//   }

//   // -----------------------------------------------------------------------
//   // 3) Show dialog to Add a new address
//   // -----------------------------------------------------------------------
//   void _showAddAddressDialog() {
//     // Default fields
//     String tempCountry = "Switzerland";
//     String tempContactName = "";
//     String tempContactMobile = "";

//     // Filled via map or reverse geocoding
//     String tempCity = "";
//     String tempPostal = "";
//     String tempStreet = "";
//     String tempHouseNo = "";

//     showDialog(
//       context: context,
//       builder: (dialogCtx) {
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             // Dynamically rebuild the dialog with the updated address preview
//             final addressPreview =
//                 (tempStreet.isNotEmpty || tempCity.isNotEmpty)
//                     ? "$tempStreet $tempHouseNo, $tempPostal $tempCity"
//                     : "(No address selected)";

//             return AlertDialog(
//               title: const Text("Add New Shipping Address"),
//               content: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // Country
//                     TextFormField(
//                       initialValue: tempCountry,
//                       decoration: const InputDecoration(labelText: 'Country'),
//                       onChanged: (val) =>
//                           setStateDialog(() => tempCountry = val),
//                     ),
//                     // Contact Name
//                     TextFormField(
//                       decoration:
//                           const InputDecoration(labelText: 'Contact Name'),
//                       onChanged: (val) =>
//                           setStateDialog(() => tempContactName = val),
//                     ),
//                     // Mobile Number
//                     TextFormField(
//                       decoration:
//                           const InputDecoration(labelText: 'Mobile Number'),
//                       keyboardType: TextInputType.phone,
//                       onChanged: (val) =>
//                           setStateDialog(() => tempContactMobile = val),
//                     ),
//                     const SizedBox(height: 10),
//                     // Address preview + "Pick from Map"
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Expanded(
//                           child: Text("Address:\n$addressPreview"),
//                         ),
//                         ElevatedButton(
//                           onPressed: () async {
//                             // 1) Pick lat/lng from map
//                             final result = await _pickAddressFromMap(dialogCtx);
//                             if (result != null) {
//                               // 2) Reverse geocode to fill city, postal, etc.
//                               final lat = result['lat']!;
//                               final lng = result['lng']!;
//                               final revData = await _reverseGeocode(lat, lng);

//                               // 3) Update the local variables
//                               setStateDialog(() {
//                                 tempCity = revData['city'] ?? "";
//                                 tempPostal = revData['postalCode'] ?? "";
//                                 tempStreet = revData['street'] ?? "";
//                                 tempHouseNo = revData['houseNo'] ?? "";
//                               });
//                             }
//                           },
//                           child: const Text("Pick from Map"),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(dialogCtx),
//                   child: const Text("Cancel"),
//                 ),
//                 ElevatedButton(
//                   onPressed: () async {
//                     final user = _auth.currentUser;
//                     if (user == null) {
//                       Navigator.pop(dialogCtx);
//                       return;
//                     }

//                     final newAddress = {
//                       'country': tempCountry.trim(),
//                       'contactName': tempContactName.trim(),
//                       'contactMobile': tempContactMobile.trim(),
//                       'city': tempCity.trim(),
//                       'postalCode': tempPostal.trim(),
//                       'streetName': tempStreet.trim(),
//                       'houseNo': tempHouseNo.trim(),
//                       'createdAt': FieldValue.serverTimestamp(),
//                     };

//                     final docRef = await _firestore
//                         .collection('users')
//                         .doc(user.uid)
//                         .collection('addresses')
//                         .add(newAddress);

//                     newAddress['id'] = docRef.id;

//                     setState(() {
//                       _addresses.add(newAddress);
//                       _selectedAddress = newAddress; // auto-select
//                     });

//                     Navigator.pop(dialogCtx);
//                   },
//                   child: const Text("Save"),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   // -----------------------------------------------------------------------
//   // 4) Show dialog to Edit an existing address
//   // -----------------------------------------------------------------------
//   void _showEditAddressDialog(Map<String, dynamic> address) {
//     // Pre-fill with existing data
//     String tempCountry = address['country'] ?? "Switzerland";
//     String tempContactName = address['contactName'] ?? "";
//     String tempContactMobile = address['contactMobile'] ?? "";
//     String tempCity = address['city'] ?? "";
//     String tempPostal = address['postalCode'] ?? "";
//     String tempStreet = address['streetName'] ?? "";
//     String tempHouseNo = address['houseNo'] ?? "";

//     showDialog(
//       context: context,
//       builder: (dialogCtx) {
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             final addressPreview =
//                 (tempStreet.isNotEmpty || tempCity.isNotEmpty)
//                     ? "$tempStreet $tempHouseNo, $tempPostal $tempCity"
//                     : "(No address selected)";

//             return AlertDialog(
//               title: const Text("Edit Shipping Address"),
//               content: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     TextFormField(
//                       initialValue: tempCountry,
//                       decoration: const InputDecoration(labelText: 'Country'),
//                       onChanged: (val) =>
//                           setStateDialog(() => tempCountry = val),
//                     ),
//                     TextFormField(
//                       initialValue: tempContactName,
//                       decoration:
//                           const InputDecoration(labelText: 'Contact Name'),
//                       onChanged: (val) =>
//                           setStateDialog(() => tempContactName = val),
//                     ),
//                     TextFormField(
//                       initialValue: tempContactMobile,
//                       decoration:
//                           const InputDecoration(labelText: 'Mobile Number'),
//                       keyboardType: TextInputType.phone,
//                       onChanged: (val) =>
//                           setStateDialog(() => tempContactMobile = val),
//                     ),
//                     const SizedBox(height: 10),
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Expanded(
//                           child: Text("Address:\n$addressPreview"),
//                         ),
//                         ElevatedButton(
//                           onPressed: () async {
//                             final result = await _pickAddressFromMap(dialogCtx);
//                             if (result != null) {
//                               final lat = result['lat']!;
//                               final lng = result['lng']!;
//                               final revData = await _reverseGeocode(lat, lng);
//                               setStateDialog(() {
//                                 tempCity = revData['city'] ?? "";
//                                 tempPostal = revData['postalCode'] ?? "";
//                                 tempStreet = revData['street'] ?? "";
//                                 tempHouseNo = revData['houseNo'] ?? "";
//                               });
//                             }
//                           },
//                           child: const Text("Pick from Map"),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(dialogCtx),
//                   child: const Text("Cancel"),
//                 ),
//                 ElevatedButton(
//                   onPressed: () async {
//                     final user = _auth.currentUser;
//                     if (user == null) {
//                       Navigator.pop(dialogCtx);
//                       return;
//                     }

//                     final docId = address['id'];
//                     final updateData = {
//                       'country': tempCountry.trim(),
//                       'contactName': tempContactName.trim(),
//                       'contactMobile': tempContactMobile.trim(),
//                       'city': tempCity.trim(),
//                       'postalCode': tempPostal.trim(),
//                       'streetName': tempStreet.trim(),
//                       'houseNo': tempHouseNo.trim(),
//                     };

//                     await _firestore
//                         .collection('users')
//                         .doc(user.uid)
//                         .collection('addresses')
//                         .doc(docId)
//                         .update(updateData);

//                     // Update local list
//                     final idx = _addresses.indexWhere((a) => a['id'] == docId);
//                     if (idx != -1) {
//                       // Keep the original createdAt, etc.
//                       _addresses[idx] = {
//                         ..._addresses[idx],
//                         ...updateData,
//                       };
//                     }

//                     setState(() {});
//                     Navigator.pop(dialogCtx);
//                   },
//                   child: const Text("Save"),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   // -----------------------------------------------------------------------
//   // 5) Delete an existing address
//   // -----------------------------------------------------------------------
//   Future<void> _deleteAddress(Map<String, dynamic> address) async {
//     final user = _auth.currentUser;
//     if (user == null) return;

//     final docId = address['id'];
//     await _firestore
//         .collection('users')
//         .doc(user.uid)
//         .collection('addresses')
//         .doc(docId)
//         .delete();

//     setState(() {
//       _addresses.removeWhere((a) => a['id'] == docId);
//       if (_selectedAddress != null && _selectedAddress!['id'] == docId) {
//         _selectedAddress = null;
//       }
//     });
//   }

//   // -----------------------------------------------------------------------
//   // 6) Pick Address from Map (no autocomplete, just direct geocoding)
//   //    Marker is updated both on search and map tap.
//   // -----------------------------------------------------------------------
//   Future<Map<String, double>?> _pickAddressFromMap(BuildContext context) async {
//     return showDialog<Map<String, double>>(
//       context: context,
//       builder: (ctx) {
//         // Default center in Switzerland
//         LatLng selectedLatLng = const LatLng(46.8182, 8.2275);
//         late GoogleMapController mapController;

//         // For the search bar
//         TextEditingController searchController = TextEditingController();

//         // Move marker + camera, then rebuild
//         void _updateMarker(
//             LatLng newLatLng, void Function(void Function()) sb) {
//           sb(() {
//             selectedLatLng = newLatLng;
//           });
//           mapController.animateCamera(
//             CameraUpdate.newLatLngZoom(newLatLng, 14),
//           );
//         }

//         // On user searching an address => direct geocode
//         Future<void> _searchLocation(
//             String query, void Function(void Function()) sb) async {
//           if (query.isEmpty) return;
//           final latLng = await _geocodeAddress(query);
//           if (latLng != null) {
//             _updateMarker(latLng, sb);
//           }
//         }

//         return StatefulBuilder(
//           builder: (BuildContext context, setStateDialog) {
//             return AlertDialog(
//               insetPadding: EdgeInsets.zero,
//               contentPadding: EdgeInsets.zero,
//               content: SizedBox(
//                 width: MediaQuery.of(context).size.width * 0.9,
//                 height: MediaQuery.of(context).size.height * 0.8,
//                 child: Column(
//                   children: [
//                     // Search row
//                     Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: TextField(
//                               controller: searchController,
//                               decoration: InputDecoration(
//                                 hintText: "Search address...",
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                               ),
//                               onSubmitted: (value) async {
//                                 await _searchLocation(value, setStateDialog);
//                               },
//                             ),
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.search),
//                             onPressed: () async {
//                               await _searchLocation(
//                                   searchController.text, setStateDialog);
//                             },
//                           ),
//                         ],
//                       ),
//                     ),

//                     // The Google Map
//                     Expanded(
//                       child: GoogleMap(
//                         initialCameraPosition: CameraPosition(
//                           target: selectedLatLng,
//                           zoom: 6,
//                         ),
//                         onMapCreated: (ctrl) => mapController = ctrl,
//                         onTap: (latLng) {
//                           _updateMarker(latLng, setStateDialog);
//                         },
//                         markers: {
//                           Marker(
//                             markerId: const MarkerId('picked'),
//                             position: selectedLatLng,
//                           ),
//                         },
//                       ),
//                     ),

//                     // Bottom row: Cancel + Confirm
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         TextButton(
//                           onPressed: () => Navigator.pop(ctx),
//                           child: const Text("Cancel"),
//                         ),
//                         ElevatedButton(
//                           onPressed: () {
//                             Navigator.pop<Map<String, double>>(ctx, {
//                               'lat': selectedLatLng.latitude,
//                               'lng': selectedLatLng.longitude,
//                             });
//                           },
//                           child: const Text("Confirm"),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   /// Direct geocoding: "address string" => LatLng?
//   Future<LatLng?> _geocodeAddress(String address) async {
//     final url = Uri.parse('https://maps.googleapis.com/maps/api/geocode/json'
//         '?address=${Uri.encodeComponent(address)}'
//         '&key=$_gMapsApiKey'
//         // &components=country:ch  // if you want to restrict to Switzerland
//         );
//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final jsonBody = json.decode(response.body);
//         if (jsonBody['status'] == 'OK') {
//           final location = jsonBody['results'][0]['geometry']['location'];
//           final lat = location['lat'];
//           final lng = location['lng'];
//           return LatLng(lat, lng);
//         }
//       }
//     } catch (e) {
//       print("Error in _geocodeAddress: $e");
//     }
//     return null;
//   }

//   // -----------------------------------------------------------------------
//   // 7) Reverse geocode lat/lng => city, postalCode, street, houseNo
//   // -----------------------------------------------------------------------
//   Future<Map<String, String>> _reverseGeocode(double lat, double lng) async {
//     final url = Uri.parse(
//       'https://maps.googleapis.com/maps/api/geocode/json'
//       '?latlng=$lat,$lng'
//       '&key=$_gMapsApiKey',
//     );

//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final jsonBody = json.decode(response.body);
//         if (jsonBody['status'] == 'OK') {
//           final results = jsonBody['results'] as List;
//           if (results.isNotEmpty) {
//             final components =
//                 results[0]['address_components'] as List<dynamic>;
//             String city = "";
//             String postalCode = "";
//             String street = "";
//             String houseNo = "";

//             for (var c in components) {
//               final List types = c['types'];
//               if (types.contains('locality')) {
//                 city = c['long_name'];
//               } else if (types.contains('postal_code')) {
//                 postalCode = c['long_name'];
//               } else if (types.contains('route')) {
//                 street = c['long_name'];
//               } else if (types.contains('street_number')) {
//                 houseNo = c['long_name'];
//               }
//             }

//             return {
//               'city': city,
//               'postalCode': postalCode,
//               'street': street,
//               'houseNo': houseNo,
//             };
//           }
//         }
//       }
//     } catch (e) {
//       print("Reverse geocoding error: $e");
//     }
//     return {};
//   }

//   // -----------------------------------------------------------------------
//   // 8) Build UI
//   // -----------------------------------------------------------------------
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CustomAppBar(),
//       body: Row(
//         children: [
//           // Left side: addresses + Add button
//           Expanded(
//             flex: 3,
//             child: Container(
//               color: Colors.grey.shade50,
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   // Add Address
//                   ElevatedButton.icon(
//                     onPressed: _showAddAddressDialog,
//                     icon: const Icon(Icons.add),
//                     label: const Text("Add Shipping Address"),
//                   ),
//                   const SizedBox(height: 16),
//                   // List addresses
//                   Expanded(
//                     child: _addresses.isEmpty
//                         ? const Center(
//                             child: Text("No saved addresses found."),
//                           )
//                         : ListView.builder(
//                             itemCount: _addresses.length,
//                             itemBuilder: (context, index) {
//                               final address = _addresses[index];
//                               final isSelected = (_selectedAddress != null &&
//                                   _selectedAddress!['id'] == address['id']);

//                               return Card(
//                                 margin: const EdgeInsets.symmetric(vertical: 8),
//                                 child: ListTile(
//                                   title: Text(
//                                     address['contactName'] ?? 'No Name',
//                                     style: TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       color: isSelected
//                                           ? Colors.blue
//                                           : Colors.black,
//                                     ),
//                                   ),
//                                   subtitle: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         "Mobile: ${address['contactMobile'] ?? ''}",
//                                       ),
//                                       Text(
//                                         "Country: ${address['country'] ?? ''}",
//                                       ),
//                                       Text(
//                                         "Address: "
//                                         "${address['streetName'] ?? ''} "
//                                         "${address['houseNo'] ?? ''}, "
//                                         "${address['postalCode'] ?? ''}, "
//                                         "${address['city'] ?? ''}",
//                                       ),
//                                     ],
//                                   ),
//                                   trailing: Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       // Select or checkmark
//                                       isSelected
//                                           ? const Icon(Icons.check_circle,
//                                               color: Colors.blue)
//                                           : OutlinedButton(
//                                               onPressed: () {
//                                                 _selectAddress(address);
//                                               },
//                                               child: const Text("Select"),
//                                             ),
//                                       // Edit button
//                                       IconButton(
//                                         icon: const Icon(Icons.edit),
//                                         onPressed: () {
//                                           _showEditAddressDialog(address);
//                                         },
//                                       ),
//                                       // Delete button
//                                       IconButton(
//                                         icon: const Icon(Icons.delete),
//                                         onPressed: () {
//                                           _deleteAddress(address);
//                                         },
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           // Right side: confirm button
//           Expanded(
//             flex: 1,
//             child: Center(
//               child: ElevatedButton(
//                 onPressed: _selectedAddress == null
//                     ? null
//                     : () {
//                         _confirmSelection();
//                       },
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 30,
//                     vertical: 16,
//                   ),
//                 ),
//                 child: const Text(
//                   "Confirm Selection",
//                   style: TextStyle(fontSize: 16),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
