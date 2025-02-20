// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// class MapPickerSheet extends StatefulWidget {
//   const MapPickerSheet({Key? key}) : super(key: key);

//   @override
//   State<MapPickerSheet> createState() => _MapPickerSheetState();
// }

// class _MapPickerSheetState extends State<MapPickerSheet> {
//   late GoogleMapController _controller;
//   // Set an initial position (e.g., some city in Switzerland)
//   LatLng _pickedPosition = const LatLng(46.8182, 8.2275);

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       // Use SafeArea so that the map isn't overlapped by system UI
//       child: Column(
//         children: [
//           Expanded(
//             child: GoogleMap(
//               initialCameraPosition: CameraPosition(
//                 target: _pickedPosition,
//                 zoom: 6.5,
//               ),
//               onMapCreated: (controller) => _controller = controller,
//               // Update _pickedPosition while moving the camera
//               onCameraMove: (CameraPosition position) {
//                 setState(() {
//                   _pickedPosition = position.target;
//                 });
//               },
//               // Or pick final on camera idle
//               onCameraIdle: () {},
//               // You can add markers if you want
//               markers: {
//                 Marker(
//                   markerId: const MarkerId('selected-marker'),
//                   position: _pickedPosition,
//                 ),
//               },
//             ),
//           ),

//           // Confirm Button
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: ElevatedButton(
//               onPressed: () {
//                 // Return the chosen LatLng to the caller
//                 Navigator.of(context).pop(_pickedPosition);
//               },
//               child: const Text("Confirm Location"),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
