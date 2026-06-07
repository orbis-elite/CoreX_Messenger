// import 'dart:convert';
// import 'dart:developer';
// import 'package:corexchat/src/screens/subscription/payment/web/payment_webview.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:hive/hive.dart';
// import 'package:http/http.dart' as http;
// import 'package:corexchat/src/global/api_helper.dart';
// import 'package:corexchat/src/screens/subscription/payment/subscription_response.dart';

// class PaymentService {
//   static const String paymentBaseUrl = ApiHelper.baseUrl;
//   static const String apiBaseUrl = ApiHelper.baseUrl;
//   static const String successUrl = "corex://subscription-success";
//   static const String failureUrl = "corex://subscription-failure";

//   // Initiates subscription payment process
//   static Future<SubscriptionPaymentResponse> startSubscription({
//     required double amount,
//     required int durationInMonths,
//     required BuildContext context,
//   }) async {
//     try {
//       // Get user name from Hive
//       final userName = Hive.box('userdata').get('userName') ?? 'User';

//       final response = await http.post(
//         Uri.parse('$paymentBaseUrl/start-subscription'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer ${Hive.box('userdata').get('authToken')}',
//         },
//         body: json.encode({
//           'name': userName,
//           'email': 'primocys@gmail.com', // Static email as requested
//           'is_authenticated': true,
//           'amount': (amount * 100).toInt(), // Convert to smallest currency unit
//           'success_return_url': successUrl,
//           'failure_return_url': failureUrl,
//           'duration_in_months': durationInMonths,
//         }),
//       );

//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         return SubscriptionPaymentResponse(
//           success: true,
//           message: responseData['message'],
//           recurringId: responseData['recurring_id'],
//           customerId: responseData['customer_id'],
//           actionUrl: responseData['action_url'],
//         );
//       } else {
//         final responseData = json.decode(response.body);
//         return SubscriptionPaymentResponse(
//           success: false,
//           errorMessage:
//               responseData['message'] ?? 'Failed to start subscription process',
//         );
//       }
//     } catch (e) {
//       return SubscriptionPaymentResponse(
//         success: false,
//         errorMessage: 'Error: ${e.toString()}',
//       );
//     }
//   }

//   // Confirm subscription after successful payment
//   static Future<bool> confirmSubscription({
//     required String recurringId,
//     required String customerId,
//     required int subscriptionTypeId,
//     required int durationInMonths,
//   }) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$apiBaseUrl/confirm-subscription'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer ${Hive.box('userdata').get('authToken')}',
//         },
//         body: json.encode({
//           'recurring_id': recurringId,
//           'csutomer_id': customerId,
//           'subscription_type_id': subscriptionTypeId,
//           'duration_in_months': durationInMonths,
//         }),
//       );
//       log('HTTP status: ${response.statusCode}');
//       log('HTTP headers: ${response.headers}');
//       log('HTTP body: ${response.body}');

//       // if (response.statusCode == 200) {
//       //   final responseData = json.decode(response.body);
//       //   return responseData['success'] == true;
//       // } else {
//       //   return false;
//       // }
//       if (response.statusCode == 200) {
//         // Since we're getting a successful status and a message confirming subscription,
//         // we should return true regardless of whether there's a 'success' field
//         return true;
//       } else {
//         return false;
//       }
//     } catch (e) {
//       print('Error confirming subscription: ${e.toString()}');
//       return false;
//     }
//   }

//   // Handles the entire payment flow
//   static Future<bool> processPayment({
//     required double amount,
//     required int durationInMonths,
//     required int subscriptionTypeId,
//     required BuildContext context,
//     Function? onPaymentStarted,
//     Function? onPaymentCompleted,
//     Function(String)? onError,
//   }) async {
//     try {
//       String? recurringId;
//       String? customerId;

//       // Notify payment started
//       if (onPaymentStarted != null) {
//         onPaymentStarted();
//       }

//       // Start subscription process
//       final paymentResponse = await startSubscription(
//         amount: amount,
//         durationInMonths: durationInMonths,
//         context: context,
//       );

//       // Check if payment initialization was successful
//       if (!paymentResponse.success || paymentResponse.actionUrl == null) {
//         if (onError != null) {
//           onError(
//               paymentResponse.errorMessage ?? 'Failed to initialize payment');
//         }
//         return false;
//       }

//       // Store IDs for confirmation later
//       recurringId = paymentResponse.recurringId;
//       customerId = paymentResponse.customerId;

//       // Open WebView with the payment URL
//       final paymentResult = await Get.to(
//         () => PaymentWebView(
//           initialUrl: paymentResponse.actionUrl!,
//           successUrl: successUrl,
//           failureUrl: failureUrl,
//         ),
//       );

//       // Notify payment completed
//       if (onPaymentCompleted != null) {
//         onPaymentCompleted();
//       }

//       // If payment was successful, confirm the subscription
//       if (paymentResult == true && recurringId != null && customerId != null) {
//         final confirmResult = await confirmSubscription(
//           recurringId: recurringId,
//           customerId: customerId,
//           subscriptionTypeId: subscriptionTypeId,
//           durationInMonths: durationInMonths,
//         );

//         if (!confirmResult && onError != null) {
//           onError(
//               'Payment was successful but subscription confirmation failed. Please contact support.');
//         }

//         return confirmResult;
//       }

//       // Return payment result (true if successful)
//       return paymentResult == true;
//     } catch (e) {
//       if (onError != null) {
//         onError('Error processing payment: ${e.toString()}');
//       }
//       return false;
//     }
//   }

//   // Shows success dialog and handles navigation
//   static void showPaymentSuccessDialog(
//       BuildContext context, Widget destination) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Payment Successful'),
//           content: const Text(
//             'Your subscription has been activated successfully. You can now enjoy all premium features.',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 // Close dialog and navigate to destination
//                 Navigator.of(context).pop();
//                 Get.offAll(() => destination);
//               },
//               child: const Text('Okay'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// import 'dart:convert';
// import 'dart:developer' as dev;
// import 'dart:math';
// import 'package:corexchat/src/screens/normal_badge_request/badge_request_screen.dart';
// import 'package:corexchat/src/screens/subscription/payment/web/payment_webview.dart';
// import 'package:corexchat/src/screens/subscription/verification_request/submit_form.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:hive/hive.dart';
// import 'package:http/http.dart' as http;
// import 'package:corexchat/src/global/api_helper.dart';
// import 'package:corexchat/src/screens/subscription/payment/subscription_response.dart';

// class PaymentService {
//   static const String paymentBaseUrl = ApiHelper.baseUrl;
//   static const String apiBaseUrl = ApiHelper.baseUrl;
//   static const String successUrl = "corex://subscription-success";
//   static const String failureUrl = "corex://subscription-failure";

//   // Initiates subscription payment process
//   static Future<SubscriptionPaymentResponse> startSubscription({
//     required double amount,
//     required int durationInMonths,
//     required BuildContext context,
//   }) async {
//     try {
//       // Get user name from Hive
//       final userName = Hive.box('userdata').get('userName') ?? 'User';

//       final response = await http.post(
//         Uri.parse('$paymentBaseUrl/start-subscription'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer ${Hive.box('userdata').get('authToken')}',
//         },
//         body: json.encode({
//           'name': userName,
//           'email': 'primocys@gmail.com', // Static email as requested
//           'is_authenticated': true,
//           'amount': (amount * 100).toInt(), // Convert to smallest currency unit
//           'success_return_url': successUrl,
//           'failure_return_url': failureUrl,
//           'duration_in_months': durationInMonths,
//         }),
//       );

//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         return SubscriptionPaymentResponse(
//           success: true,
//           message: responseData['message'],
//           recurringId: responseData['recurring_id'],
//           customerId: responseData['customer_id'],
//           actionUrl: responseData['action_url'],
//         );
//       } else {
//         final responseData = json.decode(response.body);
//         return SubscriptionPaymentResponse(
//           success: false,
//           errorMessage:
//               responseData['message'] ?? 'Failed to start subscription process',
//         );
//       }
//     } catch (e) {
//       return SubscriptionPaymentResponse(
//         success: false,
//         errorMessage: 'Error: ${e.toString()}',
//       );
//     }
//   }

//   // Confirm subscription after successful payment
//   static Future<bool> confirmSubscription({
//     required String recurringId,
//     required String customerId,
//     required int subscriptionTypeId,
//     required int durationInMonths,
//   }) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$apiBaseUrl/confirm-subscription'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer ${Hive.box('userdata').get('authToken')}',
//         },
//         body: json.encode({
//           'recurring_id': recurringId,
//           'csutomer_id': customerId,
//           'subscription_type_id': subscriptionTypeId,
//           'duration_in_months': durationInMonths,
//         }),
//       );
//       dev.log('HTTP status: ${response.statusCode}');
//       dev.log('HTTP headers: ${response.headers}');
//       dev.log('HTTP body: ${response.body}');

//       if (response.statusCode == 200) {
//         // Since we're getting a successful status and a message confirming subscription,
//         // we should return true regardless of whether there's a 'success' field
//         return true;
//       } else {
//         return false;
//       }
//     } catch (e) {
//       print('Error confirming subscription: ${e.toString()}');
//       return false;
//     }
//   }

//   // Handles the entire payment flow
//   static Future<bool> processPayment({
//     required double amount,
//     required int durationInMonths,
//     required int subscriptionTypeId,
//     required BuildContext context,
//     Function? onPaymentStarted,
//     Function? onPaymentCompleted,
//     Function(String)? onError,
//   }) async {
//     try {
//       String? recurringId;
//       String? customerId;

//       // Notify payment started
//       if (onPaymentStarted != null) {
//         onPaymentStarted();
//       }

//       // Start subscription process
//       final paymentResponse = await startSubscription(
//         amount: amount,
//         durationInMonths: durationInMonths,
//         context: context,
//       );

//       // Check if payment initialization was successful
//       if (!paymentResponse.success || paymentResponse.actionUrl == null) {
//         if (onError != null) {
//           onError(
//               paymentResponse.errorMessage ?? 'Failed to initialize payment');
//         }
//         return false;
//       }

//       // Store IDs for confirmation later
//       recurringId = paymentResponse.recurringId;
//       customerId = paymentResponse.customerId;

//       // Open WebView with the payment URL
//       final paymentResult = await Get.to(
//         () => PaymentWebView(
//           initialUrl: paymentResponse.actionUrl!,
//           successUrl: successUrl,
//           failureUrl: failureUrl,
//         ),
//       );

//       // Notify payment completed
//       if (onPaymentCompleted != null) {
//         onPaymentCompleted();
//       }

//       // If payment was successful, confirm the subscription
//       if (paymentResult == true && recurringId != null && customerId != null) {
//         final confirmResult = await confirmSubscription(
//           recurringId: recurringId,
//           customerId: customerId,
//           subscriptionTypeId: subscriptionTypeId,
//           durationInMonths: durationInMonths,
//         );

//         if (!confirmResult && onError != null) {
//           onError(
//               'Payment was successful but subscription confirmation failed. Please contact support.');
//         }

//         // If payment and confirmation were successful, direct user to Badge Request screen
//         if (confirmResult) {
//           navigateToBadgeRequestScreen(context);
//           return true;
//         }

//         return confirmResult;
//       }

//       // Return payment result (true if successful)
//       return paymentResult == true;
//     } catch (e) {
//       if (onError != null) {
//         onError('Error processing payment: ${e.toString()}');
//       }
//       return false;
//     }
//   }

//   // Navigate to badge request screen after successful payment
//   static void navigateToBadgeRequestScreen(BuildContext context) {
//     // Navigate to badge request upload screen
//     Get.to(() => const BadgeRequestUploadScreen());
//   }

//   // Shows success dialog and handles navigation
//   static void showPaymentSuccessDialog(
//       BuildContext context, Widget destination) {
//     // Use the showGeneralDialog for more customization options
//     showGeneralDialog(
//       context: context,
//       barrierDismissible: false,
//       barrierLabel: 'Payment Success',
//       transitionDuration: const Duration(milliseconds: 300),
//       pageBuilder: (context, animation1, animation2) {
//         return Container(); // Not used with transitionBuilder
//       },
//       transitionBuilder: (context, animation, secondaryAnimation, child) {
//         final curvedAnimation = CurvedAnimation(
//           parent: animation,
//           curve: Curves.easeInOutBack,
//         );

//         return ScaleTransition(
//           scale: curvedAnimation,
//           child: FadeTransition(
//             opacity: curvedAnimation,
//             child: Dialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               elevation: 8,
//               child: Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(20),
//                   gradient: const LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: [Color(0xFFE3F2FD), Colors.white],
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       blurRadius: 10,
//                       spreadRadius: 1,
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // Success icon with animation
//                     Container(
//                       width: 80,
//                       height: 80,
//                       decoration: BoxDecoration(
//                         color: Colors.green.shade100,
//                         shape: BoxShape.circle,
//                       ),
//                       child: Center(
//                         child: TweenAnimationBuilder(
//                           tween: Tween<double>(begin: 0, end: 1),
//                           duration: const Duration(milliseconds: 600),
//                           builder: (context, value, child) {
//                             return Transform.scale(
//                               scale: value,
//                               child: Icon(
//                                 Icons.check_circle,
//                                 color: Colors.green.shade700,
//                                 size: 60,
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     // Title with sliding animation
//                     TweenAnimationBuilder(
//                       tween: Tween<double>(begin: 0, end: 1),
//                       duration: const Duration(milliseconds: 700),
//                       builder: (context, value, child) {
//                         return Opacity(
//                           opacity: value,
//                           child: Transform.translate(
//                             offset: Offset(0, 20 * (1 - value)),
//                             child: const Text(
//                               'Payment Successful!',
//                               style: TextStyle(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                                 color: Color(0xFF2E7D32),
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     // Content
//                     const Text(
//                       'Your subscription has been activated successfully. You will now be directed to the verification screen.',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Color(0xFF424242),
//                         height: 1.4,
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     // Animated confetti particles
//                     SizedBox(
//                       height: 50,
//                       child: LayoutBuilder(
//                         builder: (context, constraints) {
//                           return Stack(
//                             children: List.generate(
//                               10,
//                               (index) => _buildConfettiParticle(
//                                   index, constraints.maxWidth),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     // Continue button
//                     ElevatedButton(
//                       onPressed: () {
//                         // Close dialog and navigate to badge request screen
//                         Navigator.of(context).pop();
//                         navigateToBadgeRequestScreen(context);
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF1976D2),
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 32, vertical: 12),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                         elevation: 3,
//                       ),
//                       child: const Text(
//                         'Continue',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

// // Helper method to build confetti particles
//   Widget _buildConfettiParticle(int index, double maxWidth) {
//     final random = Random();
//     final colors = [
//       Colors.blue.shade300,
//       Colors.green.shade300,
//       Colors.amber.shade300,
//       Colors.purple.shade300,
//       Colors.pink.shade300
//     ];

//     return Positioned(
//       left: random.nextDouble() * maxWidth,
//       child: TweenAnimationBuilder(
//         tween: Tween<double>(begin: 0, end: 1),
//         duration: Duration(milliseconds: 800 + random.nextInt(800)),
//         builder: (context, value, child) {
//           return Opacity(
//             opacity: value > 0.7 ? 2 - (value * 2) : value,
//             child: Transform.translate(
//               offset: Offset(
//                 sin(value * 5) * 10,
//                 -40 * value,
//               ),
//               child: Transform.rotate(
//                 angle: value * pi * 2,
//                 child: child,
//               ),
//             ),
//           );
//         },
//         child: Icon(
//           index % 2 == 0 ? Icons.star : Icons.circle,
//           color: colors[index % colors.length],
//           size: 10 + random.nextDouble() * 10,
//         ),
//       ),
//     );
//   }

// // Assuming navigateToBadgeRequestScreen is defined elsewhere
//   void navigateToBadgeRequestScreen(BuildContext context) {
//     Navigator.of(context).pushReplacement(
//       MaterialPageRoute(
//         builder: (context) => const BadgeRequestUploadScreen(),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:corexchat/src/global/global.dart';
import 'package:corexchat/src/screens/subscription/payment/web/payment_webview.dart';
import 'package:corexchat/src/screens/subscription/verification_request/submit_form.dart';
import 'package:corexchat/src/screens/subscription/payment/subscription_form.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:corexchat/src/global/api_helper.dart';
import 'package:corexchat/src/screens/subscription/payment/subscription_response.dart';

class PaymentService {
  static const String paymentBaseUrl = ApiHelper.baseUrl;
  static const String apiBaseUrl = ApiHelper.baseUrl;
  static const String successUrl = "corex://subscription-success";
  static const String failureUrl = "corex://subscription-failure";

  // Initiates subscription payment process
  static Future<SubscriptionPaymentResponse> startSubscription(
      {required double amount,
      required int durationInMonths,
      required BuildContext context,
      required String cycle,
      required String email}) async {
    try {
      // Get user name from Hive
      final userBox = Hive.box('userdata');
      print('=== User Data from Hive ===');
      print('All keys in userdata box: ${userBox.keys.toList()}');
      print('All values in userdata box: ${userBox.toMap()}');

      final userName = userBox.get('userName') ?? 'User';
      final userMobile = userBox.get('userMobile') ?? '';
      final userCountryCode = userBox.get('userCountryCode') ?? '';
      final phoneNumber = '$userCountryCode$userMobile';

      print('PaymentService>> userName: $userName');
      print('PaymentService>> userMobile: $userMobile');
      print('PaymentService>> userCountryCode: $userCountryCode');
      print('PaymentService>> combined phoneNumber: $phoneNumber');
      print('PaymentService>> combined phoneNumber: $email');

      final response = await http.post(
        Uri.parse('$paymentBaseUrl/start-subscription'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Hive.box('userdata').get('authToken')}',
        },
        body: json.encode({
          'name': userName,
          'phone_number': phoneNumber,
          'email': email,
          'is_authenticated': true,
          // 'amount': (amount * 100).toInt(),
          'amount': amount,
          'success_return_url': successUrl,
          'cycle': cycle
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return SubscriptionPaymentResponse(
          success: true,
          message: responseData['message'],
          recurringId: responseData['recurring_id'],
          customerId: responseData['customer_id'],
          actionUrl: responseData['action_url'],
        );
      } else {
        final responseData = json.decode(response.body);
        return SubscriptionPaymentResponse(
          success: false,
          errorMessage:
              responseData['message'] ?? 'Failed to start subscription process',
        );
      }
    } catch (e) {
      return SubscriptionPaymentResponse(
        success: false,
        errorMessage: 'Error: ${e.toString()}',
      );
    }
  }

  // Confirm subscription after successful payment
  static Future<bool> confirmSubscription({
    required String recurringId,
    required String customerId,
    required int subscriptionTypeId,
    required int durationInMonths,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/confirm-subscription'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Hive.box('userdata').get('authToken')}',
        },
        body: json.encode({
          'recurring_id': recurringId,
          'csutomer_id': customerId,
          'subscription_type_id': subscriptionTypeId,
          'duration_in_months': durationInMonths,
        }),
      );
      dev.log('HTTP status: ${response.statusCode}');
      dev.log('HTTP headers: ${response.headers}');
      dev.log('HTTP body: ${response.body}');

      if (response.statusCode == 200) {
        // Since we're getting a successful status and a message confirming subscription,
        // we should return true regardless of whether there's a 'success' field
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error confirming subscription: ${e.toString()}');
      return false;
    }
  }

  // Handles the entire payment flow
  static Future<bool> processPayment({
    required double amount,
    required int durationInMonths,
    required int subscriptionTypeId,
    required BuildContext context,
    required String cycle,
    required String email,
    Function? onPaymentStarted,
    Function? onPaymentCompleted,
    Function(String)? onError,
  }) async {
    try {
      String? recurringId;
      String? customerId;

      // Notify payment started
      if (onPaymentStarted != null) {
        onPaymentStarted();
      }

      // Start subscription process
      final paymentResponse = await startSubscription(
          amount: amount,
          durationInMonths: durationInMonths,
          context: context,
          cycle: cycle,
          email: email);

      // Check if payment initialization was successful
      if (!paymentResponse.success || paymentResponse.actionUrl == null) {
        if (onError != null) {
          onError(
              paymentResponse.errorMessage ?? 'Failed to initialize payment');
        }
        return false;
      }

      // Store IDs for confirmation later
      recurringId = paymentResponse.recurringId;
      customerId = paymentResponse.customerId;

      // Open WebView with the payment URL
      final paymentResult = await Get.to(
        () => PaymentWebView(
          initialUrl: paymentResponse.actionUrl!,
          successUrl: successUrl,
          failureUrl: failureUrl,
        ),
      );

      // Notify payment completed
      if (onPaymentCompleted != null) {
        onPaymentCompleted();
      }

      // If payment was successful, confirm the subscription
      if (paymentResult == true && recurringId != null && customerId != null) {
        final confirmResult = await confirmSubscription(
          recurringId: recurringId,
          customerId: customerId,
          subscriptionTypeId: subscriptionTypeId,
          durationInMonths: durationInMonths,
        );

        if (!confirmResult && onError != null) {
          onError(
              'Payment was successful but subscription confirmation failed. Please contact support.');
        }

        // If payment and confirmation were successful, direct user to Badge Request screen
        if (confirmResult) {
          _navigateToBadgeRequestScreen(context);
          return true;
        }

        return confirmResult;
      }

      // Return payment result (true if successful)
      return paymentResult == true;
    } catch (e) {
      if (onError != null) {
        onError('Error processing payment: ${e.toString()}');
      }
      return false;
    }
  }

  // Show subscription form and process payment
  static Future<bool> showSubscriptionFormAndProcessPayment({
    required double amount,
    required int durationInMonths,
    required int subscriptionTypeId,
    required BuildContext context,
    required String cycle,
    Function? onPaymentStarted,
    Function? onPaymentCompleted,
    Function(String)? onError,
  }) async {
    // Show the subscription form first
    final result = await showDialog<SubscriptionFormData>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SubscriptionForm(
        onSubmit: (formData) {
          Navigator.of(context).pop(formData);
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );

    // If user cancelled the form
    if (result == null) {
      return false;
    }

    // Process payment with the collected data
    return await processPayment(
      amount: amount,
      durationInMonths: durationInMonths,
      subscriptionTypeId: subscriptionTypeId,
      context: context,
      cycle: cycle,
      email: result.email,
      onPaymentStarted: onPaymentStarted,
      onPaymentCompleted: onPaymentCompleted,
      onError: onError,
    );
  }

  // Navigate to badge request screen after successful payment
  static void _navigateToBadgeRequestScreen(BuildContext context) {
    // Navigate to badge request upload screen
    Get.to(() => const BadgeRequestUploadScreen());
  }

  static void showPaymentSuccessDialog(BuildContext context) {
    // Get theme colors for gradient button
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;
    final Color primaryColor = Theme.of(context).primaryColor;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Confetti background - full container
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Image.asset(
                      'assets/icons/particals.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Blue badge with checkmark
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      const Text(
                        'Congratulations',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Message
                      const Text(
                        'Your payment has been successfully added.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Done button with gradient
                      // Container(
                      //   width: double.infinity,
                      //   height: 50,
                      //   decoration: BoxDecoration(
                      //     borderRadius: BorderRadius.circular(25),
                      //     gradient: LinearGradient(
                      //         colors: [
                      //           secondaryColor,
                      //           chatownColor,
                      //         ],
                      //         begin: Alignment.topCenter,
                      //         end: Alignment.bottomCenter),
                      //   ),
                      //   child: TextButton(
                      //     onPressed: () {
                      //       // Close dialog and navigate to badge request screen
                      //       Navigator.of(context).pop();
                      //       _navigateToBadgeRequestScreen(context);
                      //     },
                      //     style: TextButton.styleFrom(
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(25),
                      //       ),
                      //     ),
                      //     child: const Text(
                      //       'Done',
                      //       style: TextStyle(
                      //         color: Colors.white,
                      //         fontSize: 16,
                      //         fontWeight: FontWeight.bold,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      CustomButtom(
                        onPressed: () {
                          // Close dialog and navigate to badge request screen
                          Navigator.of(context).pop();
                          _navigateToBadgeRequestScreen(context);
                        },
                        title: "Done",
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildConfettiParticle(int index, double maxWidth) {
    final random = Random();
    final colors = [
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.amber.shade300,
      Colors.purple.shade300,
      Colors.pink.shade300
    ];

    return Positioned(
      left: random.nextDouble() * maxWidth,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(
            milliseconds: 800 + random.nextInt(500)), // Shortened duration
        builder: (context, value, child) {
          return Opacity(
            opacity: value > 0.7 ? 2 - (value * 2) : value,
            child: Transform.translate(
              offset: Offset(
                sin(value * 5) * 10,
                -40 * value,
              ),
              child: Transform.rotate(
                angle: value * pi * 2,
                child: child,
              ),
            ),
          );
        },
        child: Icon(
          index % 2 == 0 ? Icons.star : Icons.circle,
          color: colors[index % colors.length],
          size: 8 + random.nextDouble() * 8, // Slightly smaller particles
        ),
      ),
    );
  }
}
