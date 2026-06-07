import 'dart:convert';
import 'dart:developer';
import 'package:corexchat/Models/user_profile_model.dart';
import 'package:corexchat/src/global/api_helper.dart';
import 'package:corexchat/src/global/payment_success_dialog.dart';
import 'package:corexchat/src/global/strings.dart';
import 'package:corexchat/src/screens/layout/bottombar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

// class GreetingsService {
//   static final ApiHelper _apiHelper = ApiHelper();
//
//   // Check greetings status and show dialog if needed
//   static Future<bool> checkAndShowGreetings(BuildContext context) async {
//     try {
//       // Get user details
//       final UserProfileModel? userProfile = await fetchUserDetails();
//       if (userProfile == null) {
//         return false;
//       }
//
//       // Check if greetings should be shown
//       bool shouldShowGreetings = !(userProfile.resData?.isgreetings ?? true);
//
//       // If greetings flag is false, show the dialog
//       if (shouldShowGreetings) {
//         _showVerificationSuccessDialog(context, userProfile);
//         return true;
//       }
//       return false;
//     } catch (e) {
//       print('Error checking greetings status: $e');
//       return false;
//     }
//   }
//
//   // Fetch user details from API
//   static Future<UserProfileModel?> fetchUserDetails() async {
//     try {
//       final token = Hive.box(userdata).get(authToken);
//       if (token == null) {
//         return null;
//       }
//
//       final response = await http.post(
//         Uri.parse(_apiHelper.userCreateProfile),
//         headers: {
//           'Accept': 'application/json',
//           'Authorization': 'Bearer $token'
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         log('greeting response: $data');
//         return UserProfileModel.fromJson(data);
//       } else {
//         print(
//             'Failed to fetch user details. Status code: ${response.statusCode}');
//         return null;
//       }
//     } catch (e) {
//       print('Exception during fetching user details: $e');
//       return null;
//     }
//   }
//
//   // Update user data after showing greetings
//   static Future<bool> updateUserAfterGreeting() async {
//     try {
//       final token = Hive.box(userdata).get(authToken);
//       if (token == null) {
//         return false;
//       }
//
//       // Send POST request to update isgreetings flag to true
//       final response = await http.post(
//         Uri.parse(_apiHelper.userCreateProfile),
//         headers: {
//           'Accept': 'application/json',
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token'
//         },
//         body: json.encode({
//           'is_greeted': true // Parameter to update on server
//         }),
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         log('update greeting response: $data');
//         return true;
//       } else {
//         print(
//             'Failed to update greetings status. Status code: ${response.statusCode}');
//         return false;
//       }
//     } catch (e) {
//       print('Error updating user after greeting: $e');
//       return false;
//     }
//   }
//
//   // Show verification success dialog with dynamic logo
//   static void _showVerificationSuccessDialog(
//       BuildContext context, UserProfileModel userProfile) {
//     // Get logo URL from user's verification type
//     final String? logoUrl = userProfile.resData?.verificationType?.logo;
//
//     // Get verification type ID
//     final int? verificationTypeId =
//         userProfile.resData?.verificationType?.verificationTypeId;
//
//     // Determine title and message based on verification type ID
//     String title;
//     String message;
//
//     if (verificationTypeId == 4) {
//       // Gold verification
//       title = 'Welcome to the Elite';
//       message =
//           'Congratulations on achieving Xclus Verified status. Your profile now bears the mark of true distinction — the Xclus tick. Enjoy the privileges that come with greatness.';
//     } else {
//       // Blue verification (default)
//       title = 'Congratulations';
//       message = 'You have received the verified tick';
//     }
//
//     context.showFixedBackgroundSuccessDialog(
//       title: title,
//       message: message,
//       buttonText: 'Done',
//       onButtonPressed: () async {
//         // Update user data before navigating
//         bool updated = await updateUserAfterGreeting();
//         if (!updated) {
//           print('Warning: Failed to update greeting status on server');
//         }
//         // Navigate to tabbar screen
//         Get.offAll(() => TabbarScreen(currentTab: 0));
//       },
//       useGifCheckmark: false, // Don't use the default GIF
//       logoUrl: logoUrl, // Pass the logo URL from verification type
//     );
//   }
// }

class GreetingsService {
  static final ApiHelper _apiHelper = ApiHelper();

  // Main method to check all required popups
  static Future<bool> checkAndShowPopups(BuildContext context) async {
    try {
      // Get user details
      final UserProfileModel? userProfile = await fetchUserDetails();
      if (userProfile == null) {
        return false;
      }

      // First check revocation popup
      bool isRevokePopupShown = userProfile.resData?.isRevoke ?? true;

      // If revoke popup flag is false, show the revocation popup
      // and don't check for greetings until revoke popup is handled
      if (!isRevokePopupShown) {
        _showRevocationDialog(context, userProfile);
        return true;
      }

      // Only check for greetings if revoke popup is already shown (isRevoke == true)
      bool shouldShowGreetings = !(userProfile.resData?.isgreetings ?? true);

      // If greetings flag is false, show the greetings dialog
      if (shouldShowGreetings) {
        _showVerificationSuccessDialog(context, userProfile);
        return true;
      }

      return false;
    } catch (e) {
      print('Error checking popup status: $e');
      return false;
    }
  }

  // Fetch user details from API
  static Future<UserProfileModel?> fetchUserDetails() async {
    try {
      final token = Hive.box(userdata).get(authToken);
      if (token == null) {
        return null;
      }

      final response = await http.post(
        Uri.parse(_apiHelper.userCreateProfile),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('user profile response: $data');
        return UserProfileModel.fromJson(data);
      } else {
        print(
            'Failed to fetch user details. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception during fetching user details: $e');
      return null;
    }
  }

  // Update user data after showing revocation popup
  static Future<bool> updateRevokePopupStatus() async {
    try {
      final token = Hive.box(userdata).get(authToken);
      if (token == null) {
        return false;
      }

      // Send POST request to update is_revoke_popup flag to true
      final response = await http.post(
        Uri.parse(_apiHelper.userCreateProfile),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode({
          'is_revoke_popup': true // Parameter to update on server
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('update revoke popup response: $data');

        // After updating revoke popup status, check if we need to show greetings dialog
        UserProfileModel? updatedProfile = UserProfileModel.fromJson(data);
        bool shouldShowGreetings =
            !(updatedProfile.resData?.isgreetings ?? true);

        if (shouldShowGreetings) {
          // We need to return false here to indicate that we're not done showing dialogs
          // The calling method will check for greetings in the next call
          return false;
        }

        return true;
      } else {
        print(
            'Failed to update revoke popup status. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error updating revoke popup status: $e');
      return false;
    }
  }

  // Update user data after showing greetings
  static Future<bool> updateUserAfterGreeting() async {
    try {
      final token = Hive.box(userdata).get(authToken);
      if (token == null) {
        return false;
      }

      // Send POST request to update isgreetings flag to true
      final response = await http.post(
        Uri.parse(_apiHelper.userCreateProfile),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode({
          'is_greeted': true // Parameter to update on server
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('update greeting response: $data');
        return true;
      } else {
        print(
            'Failed to update greetings status. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error updating user after greeting: $e');
      return false;
    }
  }

  // Show revocation dialog with dynamic reason
  static void _showRevocationDialog(
      BuildContext context, UserProfileModel userProfile) {
    // Get revocation reason from first item in revocations list
    String revocationReason = "Unknown reason";

    if (userProfile.resData?.revocations != null &&
        userProfile.resData!.revocations!.isNotEmpty) {
      revocationReason =
          userProfile.resData!.revocations![0].revocationReason ??
              "Unknown reason";
    }

    context.showFixedBackgroundSuccessDialog(
      title: 'Your tick mark has been removed',
      message:
          'Sorry for the inconvenience, because we were forced to remove your tick mark.\n\nReason: $revocationReason',
      buttonText: 'Done',
      onButtonPressed: () async {
        // Update revoke popup status before navigating
        bool updated = await updateRevokePopupStatus();

        // If updated is false and we have more dialogs to show, checkAndShowPopups will handle it
        // Otherwise, navigate to the home screen
        if (updated) {
          // Navigate to tabbar screen
          Get.offAll(() => TabbarScreen(currentTab: 0));
        } else {
          // Re-check for remaining popups (greeting)
          checkAndShowPopups(context);
        }
      },
      useGifCheckmark: false, // Don't use the default GIF
      logoUrl: null, // No logo for revocation popup
    );
  }

  // Show verification success dialog with dynamic logo
  static void _showVerificationSuccessDialog(
      BuildContext context, UserProfileModel userProfile) {
    // Get logo URL from user's verification type
    final String? logoUrl = userProfile.resData?.verificationType?.logo;

    // Get verification type ID
    final int? verificationTypeId =
        userProfile.resData?.verificationType?.verificationTypeId;

    // Determine title and message based on verification type ID
    String title;
    String message;

    if (verificationTypeId == 4) {
      // Gold verification
      title = 'Welcome to the Elite';
      message =
          'Congratulations on achieving Xclus Verified status. Your profile now bears the mark of true distinction — the Xclus tick. Enjoy the privileges that come with greatness.';
    } else {
      // Blue verification (default)
      title = 'Congratulations';
      message = 'You have received the verified tick';
    }

    context.showFixedBackgroundSuccessDialog(
      title: title,
      message: message,
      buttonText: 'Done',
      onButtonPressed: () async {
        // Update user data before navigating
        bool updated = await updateUserAfterGreeting();
        if (!updated) {
          print('Warning: Failed to update greeting status on server');
        }
        // Navigate to tabbar screen
        Get.offAll(() => TabbarScreen(currentTab: 0));
      },
      useGifCheckmark: false, // Don't use the default GIF
      logoUrl: logoUrl, // Pass the logo URL from verification type
    );
  }
}
