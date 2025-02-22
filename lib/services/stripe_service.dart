// import 'package:dio/dio.dart';
// import 'package:ez8app/consts.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
// import 'dart:html' as html; // Import for web redirection

// class StripeService {
//   StripeService._();

//   static final StripeService instance = StripeService._();

//   // bool get paymentSuccess => null;

//   //  Future<void>makePayment () async {
//   //   try {
//   //     String? result = await _createPaymentIntent(10, "usd",);
//   //   } catch (e) {
//   //     print(e);
//   //   }
//   //  }

//   // Future<bool> makePayment(int amount, String currency) async {
//   //   try {
//   //     String? clientSecret = await _createPaymentIntent(amount, currency);
//   //     if (clientSecret == null) {
//   //       print("Error: Failed to get client secret.");
//   //       return false;
//   //     }

//   //     // Initialize the payment sheet with clientSecret
//   //     await Stripe.instance.initPaymentSheet(
//   //       paymentSheetParameters: SetupPaymentSheetParameters(
//   //         paymentIntentClientSecret: clientSecret,
//   //         merchantDisplayName: "EZ8",
//   //       ),
//   //     );

//   //     // Show the payment sheet to the user
//   //     await Stripe.instance.presentPaymentSheet();

//   //     print("Payment Successful!");
//   //     return true;
//   //   } catch (e) {
//   //     print("Error during payment: $e");
//   //     return false;
//   //   }
//   // }

//   Future<void> makePayment(double amount, String currency) async {
//     try {
//       String? checkoutUrl = await _createCheckoutSession(amount, currency);
//       if (checkoutUrl != null) {
//         // Open Stripe Checkout page in a new tab
//         html.window.open(checkoutUrl, "_blank");
//       } else {
//         print("Error: Failed to get checkout URL.");
//       }
//     } catch (e) {
//       print("Error during payment: $e");
//     }
//   }

//   Future<String?> _createCheckoutSession(double amount, String currency) async {
//     try {
//       final Dio dio = Dio();
//       final response = await dio.post(
//         "https://api.stripe.com/v1/checkout/sessions",
//         options: Options(
//           headers: {
//             "Authorization": "Bearer $stripeSecretkey",
//             "Content-Type": "application/x-www-form-urlencoded",
//           },
//         ),
//         data: {
//           "success_url": "https://ez8.ch/#/success",
//           "cancel_url": "https://ez8.ch/#/cancel",
//           "payment_method_types[]": "card",
//           "mode": "payment",
//           "line_items[0][price_data][currency]": currency,
//           "line_items[0][price_data][product_data][name]": "Order Payment",
//           "line_items[0][price_data][unit_amount]": amount * 100,
//           "line_items[0][quantity]": 1,
//         },
//       );

//       if (response.statusCode == 200) {
//         return response.data["url"]; // Get checkout session URL
//       } else {
//         print("Stripe API Error: ${response.data}");
//         return null;
//       }
//     } catch (e) {
//       print("Stripe API Error: $e");
//       return null;
//     }
//   }

//   Future<String?> _createPaymentIntent(int amount, String currency) async {
//     try {
//       final Dio dio = Dio();
//       Map<String, dynamic> data = {
//         "amount": _calculateAmount(
//           amount,
//         ),
//         "currency": currency,
//       };
//       var response = await dio.post(
//         "https://api.stripe.com/v1/payment_intents",
//         data: data,
//         options: Options(
//           contentType: Headers.formUrlEncodedContentType,
//           headers: {
//             "Authorization": "Bearer $stripeSecretkey",
//             "Content-Type": 'application/x-www-format-urlencoded'
//           },
//         ),
//       );
//       if (response.data != null) {
//         print(response.data);
//         return response.data["client_secret"];
//       }
//       return null;
//     } catch (e) {
//       print("Stripe API Error: $e");
//       return null;
//     }
//   }

//   String _calculateAmount(int amount) {
//     final CalculatedAmount = amount * 100;
//     return CalculatedAmount.toString();
//   }
// }

// ------------------------------Stripe Payment for Android--------------------------------
import 'dart:io' show Platform;
import 'dart:html' as html; // For Web redirection
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:dio/dio.dart';
import 'package:dio/dio.dart';
import 'package:ez8app/consts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeService {
  StripeService._();
  static final StripeService instance = StripeService._();

  Future<bool> makePayment(double amount, String currency) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Mobile: Use Stripe Payment Sheet
        return await _startMobilePayment(amount, currency);
      } else {
        // Web: Use Stripe Checkout
        return await _startWebPayment(amount, currency);
      }
    } catch (e) {
      print("Error during payment: $e");
      return false;
    }
  }

  Future<bool> _startMobilePayment(double amount, String currency) async {
    try {
      String? clientSecret = await _createPaymentIntent(amount, currency);
      if (clientSecret == null) return false;

      // Initialize and present Stripe Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: "EZ8 Store",
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      print("Payment Successful!");
      return true;
    } catch (e) {
      print("Error during mobile payment: $e");
      return false;
    }
  }

  Future<bool> _startWebPayment(double amount, String currency) async {
    try {
      String? checkoutUrl = await _createCheckoutSession(amount, currency);
      if (checkoutUrl != null) {
        html.window.open(checkoutUrl, "_blank");
        return true;
      } else {
        print("Error: Failed to get checkout URL.");
        return false;
      }
    } catch (e) {
      print("Error during web payment: $e");
      return false;
    }
  }

  Future<String?> _createCheckoutSession(double amount, String currency) async {
    try {
      final Dio dio = Dio();
      final response = await dio.post(
        "https://api.stripe.com/v1/checkout/sessions",
        options: Options(
          headers: {
            "Authorization": "Bearer $stripeSecretkey",
            "Content-Type": "application/x-www-form-urlencoded",
          },
        ),
        data: {
          "success_url": "https://ez8.ch/#/success",
          "cancel_url": "https://ez8.ch/#/cancel",
          "payment_method_types[]": "card",
          "mode": "payment",
          "line_items[0][price_data][currency]": currency,
          "line_items[0][price_data][product_data][name]": "Order Payment",
          "line_items[0][price_data][unit_amount]": (amount * 100).toInt(),
          "line_items[0][quantity]": 1,
        },
      );

      if (response.statusCode == 200) {
        return response.data["url"];
      } else {
        print("Stripe API Error: ${response.data}");
        return null;
      }
    } catch (e) {
      print("Stripe API Error: $e");
      return null;
    }
  }

  Future<String?> _createPaymentIntent(double amount, String currency) async {
    try {
      final Dio dio = Dio();
      final response = await dio.post(
        "https://api.stripe.com/v1/payment_intents",
        options: Options(
          headers: {
            "Authorization": "Bearer $stripeSecretkey",
            "Content-Type": "application/x-www-form-urlencoded",
          },
        ),
        data: {
          "amount": (amount * 100).toInt().toString(),
          "currency": currency,
        },
      );

      if (response.data != null) {
        return response.data["client_secret"];
      }
      return null;
    } catch (e) {
      print("Stripe API Error: $e");
      return null;
    }
  }
}
