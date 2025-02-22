// // import 'package:flutter_stripe/flutter_stripe.dart';
// // import 'package:medlearning_mobile/core/configs/api_config.dart';

// // class StripeService {
// //   StripeService._();

// //   static final StripeService instance = StripeService._();
// //   ApiBaseRequsets apiBaseRequsets = ApiBaseRequsets();

// //   Future<void> makePayment(
// //       {required String userId, required String courseID}) async {
// //     // try {
// //     String? paymentIntentClientSecret =
// //         await _createPaymentIntent(userId: userId, courseID: courseID);
// //     print('uuuuuuu secrter id : $paymentIntentClientSecret');
// //     if (paymentIntentClientSecret == null) return;
// //     await Stripe.instance.initPaymentSheet(
// //       paymentSheetParameters: SetupPaymentSheetParameters(
// //         paymentIntentClientSecret: paymentIntentClientSecret,
// //         merchantDisplayName: "Testing",
// //       ),
// //     );
// //     await _processPayment();
// //     // } catch (e) {
// //     //   print(e);
// //     // }
// //   }

// //   Future<String?> _createPaymentIntent(
// //       {required String userId, required String courseID}) async {
// //     // try {
// //     // Prepare the data to send in the API request
// //     Map<String, dynamic> data = {
// //       'courseId': courseID,
// //       'userId': userId,
// //     };

// //     // Make the POST request to your backend API
// //     var response = await apiBaseRequsets.post('/stripe/create-checkout-session',
// //         data: data);

// //     // Check if the response contains data
// //     if (response != null && response['data'] != null) {
// //       // Return the client_secret from the response data
// //       return response['data']["clientSecret"];
// //     }

// //     // Return null if no client_secret is found in the response
// //     return null;
// //     // } catch (e) {
// //     //   print('Error in ClientSecterget : $e');
// //     // }
// //     // return null;
// //   }

// //   Future<void> _processPayment() async {
// //     try {
// //       await Stripe.instance.presentPaymentSheet();
// //       await Stripe.instance.confirmPaymentSheetPayment();
// //     } catch (e) {
// //       print(e);
// //     }
// //   }
// // }

// // ignore_for_file: use_build_context_synchronously

// // import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
// // import 'package:medlearning_mobile/core/configs/api_config.dart';
// // import 'package:medlearning_mobile/core/configs/env_config.dart';
// // import 'package:medlearning_mobile/core/theme_data/storage.dart';
// // import 'package:medlearning_mobile/modules/home/presenters/controllers/home_controller.dart';
// // import 'package:medlearning_mobile/modules/user_dashboard/presenters/course_view_controller.dart';

// // String stripeSecretKey = AppConfig.stripeSecretKey;
// //sk_test_51PaWcILdBBR8ZARMbp2wqQmWz2BNDCVc6yc9SF5iQpDTP9tsVV18K9cGTLPAdFWEbZMQEDxsm0sHZaGjCCrx0dXo00rQ3pdK1w

// class StripeService {
//   StripeService._();
//   static final StripeService instance = StripeService._();

//   String? paymentIntentClientSecret;
//   // HomeController homeController = HomeController();
//   // CourseViewController courseViewController = CourseViewController();
//   // ApiBaseRequsets apiBaseRequsets = ApiBaseRequsets();

//   Future<void> makePayment({
//     required String courseId,
//     required String userId,
//     required BuildContext context,
//     required double payment,
//     required String courseName,
//   }) async {
//     try {
//       final userDetails = await _getUserDetails();
//       if (userDetails == null) return;

//       paymentIntentClientSecret =
//           await _createPaymentIntent(userId: userId, courseID: courseId);

//       // paymentIntentClientSecret = await _createPaymentIntent(
//       //   amount: payment,
//       //   currency: "usd",
//       //   userName: userDetails["name"]!,
//       //   userEmail: userDetails["email"]!,
//       // );

//       if (paymentIntentClientSecret == null) return;

//       await _initializePaymentSheet(context);
//       await _processPayment(
//         courseId: courseId,
//         userId: userId,
//         context: context,
//         courseName: courseName,
//       );
//     } catch (e) {
//       _showErrorDialog(
//           context, "Payment initialization failed. Please try again.");
//     }
//   }

//   Future<Map<String, String>?> _getUserDetails() async {
//     // final name = await SecureStorageHelper().read("user_name");
//     // final email = await SecureStorageHelper().read("user_email");
//   //   if (email == null) {
//   //     if (kDebugMode) {
//   //       print("Error: User details are missing in secure storage.");
//   //     }
//   //     return null;
//   //   }
//   //   return {"name": name ?? "Unknown", "email": email};
//   // }

//   Future<String?> _createPaymentIntent(
//       {required String userId, required String courseID}) async {
//     // try {
//     // Prepare the data to send in the API request
//     Map<String, dynamic> data = {
//       "userId": userId,
//       "courseId": courseID,
//       "purchaseType": "single"
//     };

//     // Make the POST request to your backend API
//     var response =
//         await apiBaseRequsets.post('/stripe/create-payment-intent', data: data);

//     // Check if the response contains data
//     if (response != null && response['client_secret'] != null) {
//       // Return the client_secret from the response data
//       return response['client_secret'];
//     }

//     // Return null if no client_secret is found in the response
//     return null;
//     // } catch (e) {
//     //   print('Error in ClientSecterget : $e');
//     // }
//     // return null;
//   }

//   // Future<String?> _createPaymentIntent({
//   //   required double amount,
//   //   required String currency,
//   //   required String userName,
//   //   required String userEmail,
//   // }) async {
//   //   try {
//   //     final customerId = await _createCustomer(userName, userEmail);
//   //     if (customerId == null) return null;

//   //     final response = await Dio().post(
//   //       "https://api.stripe.com/v1/payment_intents",
//   //       data: {
//   //         "amount": _calculateAmount(amount),
//   //         "currency": currency,
//   //         "customer": customerId,
//   //         "payment_method_types[]": "card",
//   //       },
//   //       options: Options(headers: {
//   //         "Authorization": "Bearer $stripeSecretKey",
//   //         "Content-Type": 'application/x-www-form-urlencoded',
//   //       }),
//   //     );

//   //     return response.data?["client_secret"];
//   //   } catch (e) {
//   //     if (kDebugMode) {
//   //       print("Error during _createPaymentIntent: $e");
//   //     }
//   //     return null;
//   //   }
//   // }

//   // Future<String?> _createCustomer(String name, String email) async {
//   //   try {
//   //     final response = await Dio().post(
//   //       "https://api.stripe.com/v1/customers",
//   //       data: {"name": name, "email": email},
//   //       options: Options(headers: {
//   //         "Authorization": "Bearer $stripeSecretKey",
//   //         "Content-Type": 'application/x-www-form-urlencoded',
//   //       }),
//   //     );
//   //     return response.data?["id"];
//   //   } catch (e) {
//   //     if (kDebugMode) {
//   //       print("Error during _createCustomer: $e");
//   //     }
//   //     return null;
//   //   }
//   // }

//   Future<void> _initializePaymentSheet(BuildContext context) async {
//     await Stripe.instance.initPaymentSheet(
//       paymentSheetParameters: SetupPaymentSheetParameters(
//         paymentIntentClientSecret: paymentIntentClientSecret!,
//         merchantDisplayName: "Med Learning",
//       ),
//     );
//     if (kDebugMode) {
//       print('Payment Sheet initialized successfully.');
//     }
//   }

//   Future<void> _processPayment({
//     required String courseId,
//     required String userId,
//     required BuildContext context,
//     required String courseName,
//   }) async {
//     try {
//       await Stripe.instance.presentPaymentSheet();
//       print("Payment completed successfully.");
//       await _postPayment(
//           courseId: courseId,
//           userId: userId,
//           context: context,
//           courseName: courseName);
//     } catch (e) {
//       if (e.toString().contains('Canceled')) {
//         print("Payment was canceled by the user.");
//       } else {
//         _showErrorDialog(context, "Payment failed. Please try again.");
//       }
//     }
//   }

//   Future<void> _postPayment({
//     required String courseId,
//     required String userId,
//     required BuildContext context,
//     required String courseName,
//   }) async {
//     await courseViewController.patchPayment(
//       courseId: courseId,
//       userId: userId,
//       context: context,
//       piKey: paymentIntentClientSecret!.split('secret')[0],
//       courseName: courseName,
//     );
//     homeController.entrollCourse(
//         courseId: courseId, userId: userId, context: context);
//   }

//   void _showErrorDialog(BuildContext context, String message) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text("Payment Error"),
//           content: Text(message),
//           actions: [
//             TextButton(
//               child: const Text("OK"),
//               onPressed: () => Navigator.of(context).pop(),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   String _calculateAmount(double amount) => (amount * 100).toInt().toString();
// }