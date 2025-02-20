import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:ez8app/home/home/custom_app_bar.dart';
import 'package:ez8app/home/home/hotals/MenuPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../translations/translations.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Track selected dish names for filtering.
  Set<String> _selectedDishNames = {};

  @override
  void initState() {
    super.initState();
    // Rebuild when the language changes.
    Translations.currentLanguage.addListener(_languageChanged);
  }

  void _languageChanged() {
    setState(() {}); // Trigger a rebuild on language change.
  }

  @override
  void dispose() {
    Translations.currentLanguage.removeListener(_languageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Using a limit to reduce initial data load. Adjust as needed.
    return Scaffold(
      appBar: const CustomAppBar(automaticallyImplyLeading: false),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('menus')
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(Translations.text('errorLoadingMenus')));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final menus = snapshot.data!.docs;

          // Build a mapping from dish name to a list of image URLs.
          final Map<String, List<String>> dishImageMapping = {};
          for (var doc in menus) {
            final data = doc.data() as Map<String, dynamic>;
            final dishName = data['foodCategory'] as String? ?? '';
            final imageUrl = data['imageUrl'] as String? ?? '';
            if (dishName.isNotEmpty && imageUrl.isNotEmpty) {
              dishImageMapping.putIfAbsent(dishName, () => []).add(imageUrl);
            }
          }

          // Get unique dish names.
          final Set<String> allDishNames = menus
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['foodCategory'] as String? ?? '';
              })
              .where((name) => name.isNotEmpty)
              .toSet();

          // Filter the menus based on selected dish names.
          List<QueryDocumentSnapshot> filteredMenus = _selectedDishNames.isEmpty
              ? menus
              : menus.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final dishName = data['foodCategory'] as String? ?? '';
                  return _selectedDishNames.contains(dishName);
                }).toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Horizontal list of dish chips.
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: allDishNames.map((dishName) {
                      final isSelected = _selectedDishNames.contains(dishName);
                      // Pick a random thumbnail from available images.
                      String? thumbnailUrl;
                      if (dishImageMapping.containsKey(dishName) &&
                          dishImageMapping[dishName]!.isNotEmpty) {
                        final images = dishImageMapping[dishName]!;
                        thumbnailUrl = images[Random().nextInt(images.length)];
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (thumbnailUrl != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundImage: CachedNetworkImageProvider(
                                        thumbnailUrl),
                                    backgroundColor: Colors.grey[300],
                                  ),
                                ),
                              Text(dishName),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedDishNames.add(dishName);
                              } else {
                                _selectedDishNames.remove(dishName);
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 16),
                // Grid displaying menu items.
                Expanded(
                  child: GridView.builder(
                    itemCount: filteredMenus.length,
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 320,
                      mainAxisExtent: 380,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemBuilder: (context, index) {
                      final menuDoc = filteredMenus[index];
                      final menuData = menuDoc.data() as Map<String, dynamic>;
                      final imageUrl = menuData['imageUrl'] ?? '';
                      final dishName =
                          menuData['dishName'] ?? Translations.text('noDish');
                      final hotelId = menuData['hotelId'] ?? '';
                      final hotelName =
                          menuData['hotelName'] ?? Translations.text('noHotel');
                      final price = menuData['price'] != null
                          ? menuData['price'].toString()
                          : '0';

                      return Card(
                        elevation: 4,
                        child: InkWell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Display the menu image using CachedNetworkImage.
                                Container(
                                  height: 130,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                  ),
                                  child: imageUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Center(
                                              child:
                                                  CircularProgressIndicator()),
                                          errorWidget: (context, url, error) =>
                                              Center(child: Icon(Icons.error)),
                                        )
                                      : Center(
                                          child: Icon(
                                            Icons.fastfood,
                                            size: 80,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                ),
                                SizedBox(height: 8),
                                // Dish name.
                                Text(
                                  dishName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 4),
                                // Hotel name and address.
                                Column(
                                  children: [
                                    Text(
                                      hotelName,
                                      style: TextStyle(fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                    // Use a separate widget to load the hotel address.
                                    HotelAddress(hotelId: hotelId),
                                  ],
                                ),
                                SizedBox(height: 4),
                                // Price.
                                Text(
                                  "${Translations.text('price')}: \CHF${price}",
                                  style: TextStyle(fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                                Spacer(),
                                // Order Now button.
                                AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  width: 200,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: InkWell(
                                    // Your onTap function:
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MenuPage(
                                            hotelId: hotelId,
                                            hotelName: hotelName,
                                          ),
                                        ),
                                      );
                                    },

                                    child: Center(
                                      child: Text(
                                        Translations.text('orderNow'),
                                        style: TextStyle(
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
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// A separate widget to asynchronously load and display the hotel address.
class HotelAddress extends StatelessWidget {
  final String hotelId;
  const HotelAddress({Key? key, required this.hotelId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('hotels').doc(hotelId).get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error',
              style: TextStyle(fontSize: 12), textAlign: TextAlign.center);
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text('Loading address...',
              style: TextStyle(fontSize: 12), textAlign: TextAlign.center);
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Text('',
              style: TextStyle(fontSize: 12), textAlign: TextAlign.center);
        }
        final address = snapshot.data!['address'] ?? '';
        return Text(
          address,
          style: TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        );
      },
    );
  }
}
