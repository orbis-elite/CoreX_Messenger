// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:corexchat/app.dart';
// import 'package:corexchat/src/global/global.dart';
// import 'package:corexchat/src/Notification/one_signal_service.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     navigateToScreen();
//     super.initState();
//   }

//   navigateToScreen() async {
//     Future.delayed(
//       const Duration(seconds: 3),
//       () {
//         Get.offAll(
//           const AppScreen(),
//           transition: Transition.downToUp,
//         );
//         OnesignalService().initialize();
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Get the screen dimensions
//     final screenSize = MediaQuery.of(context).size;
//     final height = screenSize.height;
//     final width = screenSize.width;

//     // Determine logo sizes based on screen size
//     final mainLogoHeight = height * 0.2; // 20% of screen height
//     final mainLogoWidth = width * 0.6; // 60% of screen width

//     // Bottom logo sizing - fixed size rather than percentage to avoid stretching
//     final bottomLogoWidth = width * 0.4; // 40% of screen width

//     // Spacing adjustment based on screen height
//     final bottomSpacing = height * 0.03; // 3% of screen height

//     return Scaffold(
//       backgroundColor: appColorWhite,
//       body: SafeArea(
//         child: Stack(
//           alignment: AlignmentDirectional.center,
//           children: [
//             // Main logo in the center
//             Center(
//               child: Obx(
//                 () => languageController.isAppSettingsLoading.value == true
//                     ? const CircularProgressIndicator() // Show loading indicator
//                     : Image.network(
//                         languageController.appSettingsData[0].appLogo!,
//                         height: mainLogoHeight,
//                         width: mainLogoWidth,
//                         fit: BoxFit.contain,
//                         errorBuilder: (context, error, stackTrace) {
//                           // Fallback in case network image fails to load
//                           return Icon(
//                             Icons.image_not_supported,
//                             size: mainLogoHeight * 0.7,
//                             color: Colors.grey,
//                           );
//                         },
//                       ),
//               ),
//             ),
//             // Bottom branding
//             Positioned(
//               bottom: bottomSpacing,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     'from',
//                     style: TextStyle(
//                       color: Colors.blue,
//                       fontSize: width * 0.045,
//                     ),
//                   ),
//                   SizedBox(height: height * 0.001),
//                   // Using PNG image with fixed width
//                   Row(
//                     children: [
//                       Image.asset(
//                         'assets/icons/orbiselite.png',
//                         width: MediaQuery.of(context).size.width * 0.1,
//                         fit: BoxFit.contain,
//                       ),
//                       SizedBox(width: height * 0.005),
//                       Text(
//                         "Orbis Elite",
//                         style: TextStyle(
//                           color: Color(0xFFb78f6c),
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           letterSpacing: 1.2,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:corexchat/app.dart';
import 'package:corexchat/welcome.dart';
import 'package:corexchat/src/global/global.dart';
import 'package:corexchat/src/global/strings.dart';
import 'package:corexchat/src/Notification/one_signal_service.dart';
import 'package:corexchat/src/screens/user/FinalLogin.dart';
import 'package:corexchat/src/screens/user/create_profile.dart';
import 'package:corexchat/src/screens/layout/bottombar.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _checkingPermissions = false;
  String _statusMessage = 'Loading...';
  bool _isNavigating = false;

  @override
  void initState() {
    navigatToScreen();
    super.initState();
  }

  navigatToScreen() async {
    Future.delayed(
      const Duration(seconds: 3),
      () {
        Get.offAll(
          const AppScreen(),
          transition: Transition.downToUp,
        );
        OnesignalService().initialize();
      },
    );
  }

  Future<void> _handleNavigation() async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      setState(() {
        _statusMessage = 'Checking app state...';
      });

      // Wait for initial delay to show splash screen (minimum 1.5 seconds)
      await Future.delayed(const Duration(milliseconds: 1500));

      // First check if we need to handle permissions at all
      final Widget destinationScreen = await _getDestinationScreen();

      // Navigate to the appropriate screen
      Get.offAll(
        () => destinationScreen,
        transition: Transition.downToUp,
      );
    } catch (e) {
      log("Error in splash navigation: $e");
      // Fallback to AppScreen in case of error
      await Future.delayed(const Duration(seconds: 1));
      Get.offAll(
        () => const AppScreen(),
        transition: Transition.downToUp,
      );
    } finally {
      _isNavigating = false;
    }
  }

  Future<Widget> _getDestinationScreen() async {
    var box = Hive.box(userdata);

    // Check auth state first
    final bool hasAuthToken = box.get(authToken) != null;
    final bool hasLastName =
        box.get(lastName) != null && box.get(lastName)!.isNotEmpty;
    final bool hasFirstName =
        box.get(firstName) != null && box.get(firstName)!.isNotEmpty;
    final bool permissionsRequested =
        box.get('permissions_requested', defaultValue: false);

    // If user already completed setup (has token and profile)
    if (hasAuthToken && hasLastName && hasFirstName) {
      // For fully registered users, we check if permissions are needed
      if (permissionsRequested) {
        // Check if any permissions are missing
        bool anyMissing = await _quietlyCheckMissingPermissions();
        if (anyMissing) {
          // We need to request permissions, but this user already has a profile
          // So we should handle permissions directly here rather than going to Welcome
          await _handlePermissionsForExistingUser();

          // Once permissions are handled, load contacts if needed
          await _loadContactsIfPermissionGranted();

          print("☺☺☺☺GO TO HOME PAGE AFTER PERMISSION CHECK☺☺☺☺");
          return TabbarScreen();
        } else {
          // All permissions already granted
          await _loadContactsIfPermissionGranted();
          print("☺☺☺☺GO TO HOME PAGE (ALL PERMISSIONS OK)☺☺☺☺");
          return TabbarScreen();
        }
      } else {
        // First time running, need to go through permission flow
        setState(() {
          _statusMessage = 'Waiting for permissions...';
        });
        print("☺☺☺☺GO TO WELCOME FOR PERMISSIONS☺☺☺☺");
        return const Welcome(fromAppScreen: true);
      }
    }
    // Has auth token but needs to complete profile
    else if (hasAuthToken && (!hasLastName || !hasFirstName)) {
      print("☺☺☺☺GO TO CREATE PROFILE☺☺☺☺");
      return AddPersonaDetails(isRought: false, isback: false);
    }
    // No auth token, but permissions already handled
    else if (!hasAuthToken && permissionsRequested) {
      print("☺☺☺☺GO TO LOGIN PAGE☺☺☺☺");
      return const Flogin();
    }
    // First time using the app - needs permissions and login
    else {
      print("☺☺☺☺GO TO WELCOME SCREEN☺☺☺☺");
      return const Welcome();
    }
  }

  // Quietly check if any permissions are missing without showing UI
  Future<bool> _quietlyCheckMissingPermissions() async {
    setState(() {
      _statusMessage = 'Checking permissions...';
    });

    List<Permission> requiredPermissions = [
      Permission.notification,
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.photos,
      Permission.contacts,
      Permission.location,
    ];

    for (var permission in requiredPermissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        print("Permission missing: ${permission.toString()} (status: $status)");
        return true;
      }
    }
    return false;
  }

  // Handle permissions for users that already have accounts
  // This doesn't navigate away, just shows dialogs
  Future<void> _handlePermissionsForExistingUser() async {
    setState(() {
      _statusMessage = 'Requesting permissions...';
    });

    // Request these permissions one by one with small delays
    List<Permission> requiredPermissions = [
      Permission.notification,
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.photos,
      Permission.contacts,
      Permission.location,
    ];

    for (var permission in requiredPermissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        print("Requesting: ${permission.toString()}");
        await permission.request();
        // Small delay between permission requests
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }

    // Mark permissions as requested in any case
    await Hive.box('userdata').put('permissions_requested', true);
  }

  Future<void> _loadContactsIfPermissionGranted() async {
    setState(() {
      _statusMessage = 'Loading contacts...';
    });

    final status = await Permission.contacts.status;
    if (status.isGranted) {
      await addContactController.getContactsFromGloble();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final height = screenSize.height;
    final width = screenSize.width;

    // Determine logo sizes based on screen size
    final mainLogoHeight = height * 0.2; // 20% of screen height
    final mainLogoWidth = width * 0.6; // 60% of screen width

    // Bottom logo sizing - fixed size rather than percentage to avoid stretching
    final bottomLogoWidth = width * 0.4; // 40% of screen width

    // Spacing adjustment based on screen height
    final bottomSpacing = height * 0.03; // 3% of screen height

    return Scaffold(
      backgroundColor: appColorWhite,
      body: SafeArea(
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            // Main logo in the center
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/splash_log.png',
                    height: mainLogoHeight,
                    width: mainLogoWidth,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
            // Bottom branding
            Positioned(
              bottom: bottomSpacing,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'from',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: width * 0.045,
                    ),
                  ),
                  // SizedBox(height: height * 0.008),
                  // Orbis Elite logo and text
                  Image.asset(
                    'assets/applogo/4 (1).png',
                    width: 100,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
