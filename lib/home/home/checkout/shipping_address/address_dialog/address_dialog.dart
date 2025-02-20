import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;

typedef OnSaveCallback = void Function(Map<String, dynamic> address);

const String kGoogleApiKey = "AIzaSyAH7Ak5RYY0Mj9KtpvCbQOEb3VZhbs23qk";

// Helper function to fetch postal code suggestions using the CORS Anywhere proxy.
Future<List<Map<String, dynamic>>> fetchPostalSuggestions(String input) async {
  if (input.isEmpty) return [];

  // URL encode the input.
  final encodedInput = Uri.encodeComponent(input);

  // Prepend the CORS Anywhere proxy URL.
  final url =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedInput&key=$kGoogleApiKey&language=en&components=country:ch';

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final predictions = jsonResponse['predictions'] as List<dynamic>;
      return predictions.map((p) => p as Map<String, dynamic>).toList();
    } else {
      print('Error fetching postal suggestions: ${response.body}');
      return [];
    }
  } catch (e) {
    print('Exception in fetchPostalSuggestions: $e');
    return [];
  }
}

// Helper function to fetch street suggestions using the same CORS proxy.
Future<List<Map<String, dynamic>>> fetchStreetSuggestions(String input) async {
  if (input.isEmpty) return [];

  final encodedInput = Uri.encodeComponent(input);
  final url =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedInput&key=$kGoogleApiKey&language=en&components=country:ch';

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final predictions = jsonResponse['predictions'] as List<dynamic>;
      return predictions.map((p) => p as Map<String, dynamic>).toList();
    } else {
      print('Error fetching street suggestions: ${response.body}');
      return [];
    }
  } catch (e) {
    print('Exception in fetchStreetSuggestions: $e');
    return [];
  }
}

class AddressDialog extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? existingAddress;
  final OnSaveCallback onSave;

  const AddressDialog({
    Key? key,
    this.isEdit = false,
    this.existingAddress,
    required this.onSave,
  }) : super(key: key);

  @override
  _AddressDialogState createState() => _AddressDialogState();
}

class _AddressDialogState extends State<AddressDialog> {
  // Fields
  late String tempCountry;
  late String tempContactName;
  late String tempContactMobile;
  late String tempPostal;
  late String tempCity;
  late String tempStreet;
  late String tempHouseNo;

  // Controllers
  late TextEditingController postalCodeController;
  late TextEditingController streetController;
  late TextEditingController contactNameController;
  late TextEditingController contactMobileController;
  late TextEditingController houseNoController;
  late TextEditingController cityController;

  @override
  void initState() {
    super.initState();

    if (widget.isEdit && widget.existingAddress != null) {
      tempCountry = widget.existingAddress!['country'] ?? 'Switzerland';
      tempContactName = widget.existingAddress!['contactName'] ?? '';
      tempContactMobile = widget.existingAddress!['contactMobile'] ?? '';
      tempPostal = widget.existingAddress!['postalCode'] ?? '';
      tempCity = widget.existingAddress!['city'] ?? '';
      tempStreet = widget.existingAddress!['streetName'] ?? '';
      tempHouseNo = widget.existingAddress!['houseNo'] ?? '';
    } else {
      tempCountry = 'Switzerland';
      tempContactName = '';
      tempContactMobile = '';
      tempPostal = '';
      tempCity = '';
      tempStreet = '';
      tempHouseNo = '';
    }

    postalCodeController = TextEditingController(text: tempPostal);
    streetController = TextEditingController(text: tempStreet);
    contactNameController = TextEditingController(text: tempContactName);
    contactMobileController = TextEditingController(text: tempContactMobile);
    houseNoController = TextEditingController(text: tempHouseNo);
    cityController = TextEditingController(text: tempCity);

    // Enforce that only numbers are typed in the postal code field.
    postalCodeController.addListener(() {
      final currentText = postalCodeController.text;
      final digitsOnly = currentText.replaceAll(RegExp(r'\D'), '');
      if (currentText != digitsOnly) {
        postalCodeController.text = digitsOnly;
        postalCodeController.selection = TextSelection.fromPosition(
          TextPosition(offset: digitsOnly.length),
        );
      }
    });
  }

  @override
  void dispose() {
    postalCodeController.dispose();
    streetController.dispose();
    contactNameController.dispose();
    contactMobileController.dispose();
    houseNoController.dispose();
    cityController.dispose();
    super.dispose();
  }

  // Save Address function
  Future<void> _saveAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (tempContactName.isEmpty ||
        tempContactMobile.isEmpty ||
        tempPostal.isEmpty ||
        tempCity.isEmpty ||
        tempStreet.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final address = {
      'country': tempCountry.trim(),
      'contactName': tempContactName.trim(),
      'contactMobile': tempContactMobile.trim(),
      'postalCode': tempPostal.trim(),
      'city': tempCity.trim(),
      'streetName': tempStreet.trim(),
      'houseNo': tempHouseNo.trim(),
      'createdAt': widget.isEdit
          ? widget.existingAddress!['createdAt']
          : FieldValue.serverTimestamp(),
    };

    widget.onSave(address);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.isEdit ? "Edit Shipping Address" : "Add New Shipping Address"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Country (Read-only)
            TextFormField(
              initialValue: tempCountry,
              decoration: const InputDecoration(
                labelText: 'Country',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 10),

            // Contact Name
            TextFormField(
              controller: contactNameController,
              decoration: const InputDecoration(
                labelText: 'Contact Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => tempContactName = val),
            ),
            const SizedBox(height: 10),

            // Mobile Number
            TextFormField(
              controller: contactMobileController,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (val) => setState(() => tempContactMobile = val),
            ),
            const SizedBox(height: 10),

            // Postal Code Autocomplete using TypeAheadField
            TypeAheadField<Map<String, dynamic>>(
              controller: postalCodeController,
              debounceDuration: const Duration(milliseconds: 300),
              suggestionsCallback: (pattern) async {
                return await fetchPostalSuggestions(pattern);
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion['description'] ?? ''),
                );
              },
              onSelected: (suggestion) {
                final fullDesc = suggestion['description'] as String;
                final commaSplit = fullDesc.split(",");
                final mainPart = commaSplit[0].trim();
                final parts = mainPart.split(" ");
                if (parts.length >= 2) {
                  final postal = parts[0];
                  final city = parts.sublist(1).join(" ");
                  final formatted = "$postal - $city";
                  setState(() {
                    tempPostal = postal;
                    tempCity = city;
                    postalCodeController.text = formatted;
                    cityController.text = city;
                  });
                } else {
                  setState(() {
                    tempPostal = fullDesc;
                    postalCodeController.text = fullDesc;
                  });
                }
              },
              builder: (context, controller, focusNode) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Postal Code',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                );
              },
              emptyBuilder: (context) => const ListTile(
                title: Text('No data'),
              ),
            ),
            const SizedBox(height: 10),

            // City (Read-only, Auto-filled from Postal Code)
            TextFormField(
              controller: cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 10),

            // Street Name Autocomplete – only show the street name.
            TypeAheadField<Map<String, dynamic>>(
              controller: streetController,
              debounceDuration: const Duration(milliseconds: 300),
              suggestionsCallback: (pattern) async {
                // Only perform street lookup if a postal code has been selected.
                if (tempPostal.isEmpty) return [];
                // Bias the query using the postal code.
                final query = "$pattern, $tempPostal";
                return await fetchStreetSuggestions(query);
              },
              itemBuilder: (context, suggestion) {
                final fullDescription = suggestion['description'] as String;
                // Get the first part before the first comma.
                final firstPart = fullDescription.split(',').first;
                // Use a regex to capture everything up to the first occurrence of a digit.
                final regex = RegExp(r'^(.*?)(?=\s*\d|$)');
                final match = regex.firstMatch(firstPart);
                final streetName = match?.group(1)?.trim() ?? firstPart.trim();
                return ListTile(
                  title: Text(streetName),
                );
              },
              onSelected: (suggestion) {
                final fullDescription = suggestion['description'] as String;
                final firstPart = fullDescription.split(',').first;
                final regex = RegExp(r'^(.*?)(?=\s*\d|$)');
                final match = regex.firstMatch(firstPart);
                final streetName = match?.group(1)?.trim() ?? firstPart.trim();
                setState(() {
                  tempStreet = streetName;
                  streetController.text = streetName;
                });
              },
              builder: (context, controller, focusNode) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Street Name',
                    border: OutlineInputBorder(),
                  ),
                );
              },
              emptyBuilder: (context) => const ListTile(
                title: Text('No data'),
              ),
            ),

            const SizedBox(height: 10),

            // House Number
            TextFormField(
              controller: houseNoController,
              decoration: const InputDecoration(
                labelText: 'No',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => tempHouseNo = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.redAccent,
          ),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _saveAddress,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text(
            "Save",
            style: TextStyle(
                fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
