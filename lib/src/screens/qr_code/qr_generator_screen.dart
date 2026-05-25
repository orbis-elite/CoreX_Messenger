// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:get/get.dart';
// import 'dart:convert';
// import 'package:hive/hive.dart';
// import 'dart:developer';

// class ChatQRGeneratorScreen extends StatefulWidget {
//   final int peerId;

//   const ChatQRGeneratorScreen({
//     Key? key,
//     required this.peerId,
//   }) : super(key: key);

//   @override
//   State<ChatQRGeneratorScreen> createState() => _ChatQRGeneratorScreenState();
// }

// class _ChatQRGeneratorScreenState extends State<ChatQRGeneratorScreen> {
//   bool isLoading = true;
//   Map<String, dynamic> userData = {};
//   int? currentUserId;

//   // Constants for Hive keys
//   static const String userdata = 'userdata';
//   static const String userId = 'userId';
//   static const String userName = 'userName';
//   static const String firstName = 'firstName';
//   static const String lastName = 'lastName';
//   static const String userImage = 'userImage';
//   static const String userGender = 'userGender';
//   static const String phoneNumber = 'phoneNumber';
//   static const String countryCode = 'countryCode';
//   static const String bio = 'bio';
//   static const String authToken = 'authToken';

//   @override
//   void initState() {
//     super.initState();
//     // Get current user ID from Hive
//     currentUserId = Hive.box(userdata).get(userId);
//     _loadProfileData();
//   }

//   Future<void> _loadProfileData() async {
//     setState(() {
//       isLoading = true;
//     });

//     try {
//       // Create a Map with user data from Hive
//       userData = {
//         'userId': widget.peerId, // Use peerId as this is the peer's QR code
//         'userName': Hive.box(userdata).get(userName),
//         'firstName': Hive.box(userdata).get(firstName),
//         'lastName': Hive.box(userdata).get(lastName),
//         'profileImage': Hive.box(userdata).get(userImage),
//         'gender': Hive.box(userdata).get(userGender),
//         'phoneNumber': Hive.box(userdata).get(phoneNumber),
//         'countryCode': Hive.box(userdata).get(countryCode),
//         'bio': Hive.box(userdata).get(bio),
//       };

//       log('User data loaded from Hive: ${userData['firstName']} ${userData['lastName']}');
//     } catch (e) {
//       log('Error loading user data from Hive: $e');
//       userData = {};
//     }

//     setState(() {
//       isLoading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return Scaffold(
//         appBar: AppBar(
//           title: const Text('QR Code'),
//           backgroundColor: Colors.white,
//           elevation: 0,
//           centerTitle: true,
//           iconTheme: const IconThemeData(color: Colors.black),
//           titleTextStyle: const TextStyle(
//             color: Colors.black,
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         backgroundColor: Colors.white,
//         body: const Center(
//           child: CircularProgressIndicator(),
//         ),
//       );
//     }

//     if (userData.isEmpty) {
//       return Scaffold(
//         appBar: AppBar(
//           title: const Text('QR Code'),
//           backgroundColor: Colors.white,
//           elevation: 0,
//           centerTitle: false,
//           iconTheme: const IconThemeData(color: Colors.black),
//           titleTextStyle: const TextStyle(
//             color: Colors.black,
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         backgroundColor: Colors.white,
//         body: const Center(
//           child: Text('User data not available'),
//         ),
//       );
//     }

//     // Create QR code data with user details
//     final Map<String, dynamic> qrData = {
//       'type': 'corexmessenger_user',
//       'user_id': userData['userId'],
//       'username': userData['userName'],
//       'phone': userData['phoneNumber'],
//       'country_code': userData['countryCode'],
//       'first_name': userData['firstName'],
//       'last_name': userData['lastName'],
//       'profile_image': userData['profileImage'],
//       'bio': userData['bio'],
//       'conversation_id': widget.peerId,
//     };

//     final qrDataString = json.encode(qrData);
//     final shareText = 'CoreX Messenger@${userData['userName']}';
//     final displayName =
//         userData['firstName'] != null && userData['lastName'] != null
//             ? '${userData['firstName']} ${userData['lastName']}'
//             : userData['userName'] ?? 'User';

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('QR Code'),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: false,
//         iconTheme: const IconThemeData(color: Colors.black),
//         titleTextStyle: const TextStyle(
//           color: Colors.black,
//           fontSize: 18,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               const SizedBox(height: 20),
//               // Profile image if available
//               if (userData['profileImage'] != null &&
//                   userData['profileImage'].toString().isNotEmpty)
//                 Container(
//                   width: 80,
//                   height: 80,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     image: DecorationImage(
//                       image: NetworkImage(userData['profileImage']),
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                 ),
//               const SizedBox(height: 10),
//               Text(
//                 displayName,
//                 style:
//                     const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//                 textAlign: TextAlign.center,
//               ),
//               if (userData['userName'] != null)
//                 Text(
//                   '@${userData['userName']}',
//                   style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//                   textAlign: TextAlign.center,
//                 ),
//               const SizedBox(height: 30),
//               Center(
//                 child: Container(
//                   // padding: const EdgeInsets.all(15),
//                   // decoration: BoxDecoration(
//                   //   color: Colors.white,
//                   //   borderRadius: BorderRadius.circular(20),
//                   //   boxShadow: [
//                   //     BoxShadow(
//                   //       color: Colors.black.withOpacity(0.1),
//                   //       spreadRadius: 1,
//                   //       blurRadius: 10,
//                   //       offset: const Offset(0, 2),
//                   //     ),
//                   //   ],
//                   // ),
//                   child: QrImageView(
//                     data: qrDataString,
//                     version: QrVersions.auto,
//                     size: 220.0,
//                     errorCorrectionLevel: QrErrorCorrectLevel.H,
//                     backgroundColor: Colors.white,
//                     padding: const EdgeInsets.all(10),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 30),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 30.0),
//                 child: Container(
//                   padding: const EdgeInsets.all(15),
//                   decoration: BoxDecoration(
//                     color: Color(0xFFBAE9FD).withOpacity(0.3),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Column(
//                     children: [
//                       Text(
//                         'Scan to connect with me on CoreX Messenger',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Colors.black38,
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Your QR code is personal. If you share it, others can scan it with their CoreX Messenger camera.',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Colors.black38,
//                           fontSize: 13,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               // const SizedBox(height: 30),
//               // const Text('OR',
//               //     style: TextStyle(color: Colors.grey, fontSize: 12)),
//               // const SizedBox(height: 20),
//               // GestureDetector(
//               //   onTap: () {
//               //     Clipboard.setData(ClipboardData(text: shareText));
//               //     Get.snackbar(
//               //       'Copied!',
//               //       'Username copied to clipboard',
//               //       snackPosition: SnackPosition.BOTTOM,
//               //     );
//               //   },
//               //   child: Container(
//               //     padding:
//               //         const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//               //     decoration: BoxDecoration(
//               //       color: Colors.grey[100],
//               //       borderRadius: BorderRadius.circular(10),
//               //       border: Border.all(color: Colors.grey[300]!),
//               //     ),
//               //     child: Row(
//               //       mainAxisSize: MainAxisSize.min,
//               //       children: [
//               //         Text(
//               //           shareText,
//               //           style: const TextStyle(
//               //             fontWeight: FontWeight.w500,
//               //             letterSpacing: 0.3,
//               //           ),
//               //         ),
//               //         const SizedBox(width: 10),
//               //         const Icon(Icons.copy_outlined, size: 18),
//               //       ],
//               //     ),
//               //   ),
//               // ),
//               // const SizedBox(height: 20),
//               // const Text('OR',
//               //     style: TextStyle(color: Colors.grey, fontSize: 12)),
//               // const SizedBox(height: 20),
//               // ElevatedButton.icon(
//               //   onPressed: () {
//               //     Share.share(
//               //         'Connect with me on CoreX Messenger! My username: $shareText');
//               //   },
//               //   icon: const Icon(Icons.share_outlined),
//               //   label: const Text('Share On Social Media'),
//               //   style: ElevatedButton.styleFrom(
//               //     padding:
//               //         const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
//               //     backgroundColor: Colors.blue,
//               //     foregroundColor: Colors.white,
//               //     elevation: 0,
//               //     shape: RoundedRectangleBorder(
//               //       borderRadius: BorderRadius.circular(30),
//               //     ),
//               //   ),
//               // ),
//               const SizedBox(height: 30),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'dart:convert';
// import 'package:hive/hive.dart';
// import 'dart:developer';

// class ChatQRGeneratorScreen extends StatefulWidget {
//   final int peerId;

//   const ChatQRGeneratorScreen({
//     Key? key,
//     required this.peerId,
//   }) : super(key: key);

//   @override
//   State<ChatQRGeneratorScreen> createState() => _ChatQRGeneratorScreenState();
// }

// class _ChatQRGeneratorScreenState extends State<ChatQRGeneratorScreen> {
//   bool isLoading = true;
//   Map<String, dynamic> userData = {};
//   int? currentUserId;

//   // Constants for Hive keys
//   static const String userdata = 'userdata';
//   static const String userId = 'userId';
//   static const String userName = 'userName';
//   static const String firstName = 'firstName';
//   static const String lastName = 'lastName';
//   static const String userImage = 'userImage';
//   static const String phoneNumber = 'phoneNumber';
//   static const String countryCode = 'countryCode';

//   @override
//   void initState() {
//     super.initState();
//     // Get current user ID from Hive
//     currentUserId = Hive.box(userdata).get(userId);
//     _loadProfileData();
//   }

//   Future<void> _loadProfileData() async {
//     setState(() {
//       isLoading = true;
//     });

//     try {
//       // Create a Map with user data from Hive
//       userData = {
//         'userId': widget.peerId,
//         'userName': Hive.box(userdata).get(userName),
//         'firstName': Hive.box(userdata).get(firstName),
//         'lastName': Hive.box(userdata).get(lastName),
//         'profileImage': Hive.box(userdata).get(userImage),
//         'phoneNumber': Hive.box(userdata).get(phoneNumber),
//         'countryCode': Hive.box(userdata).get(countryCode),
//       };

//       log('User data loaded: ${userData['firstName']} ${userData['lastName']}');
//     } catch (e) {
//       log('Error loading user data: $e');
//       userData = {};
//     }

//     setState(() {
//       isLoading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return Scaffold(
//         appBar: AppBar(
//           title: const Text('QR Code'),
//           backgroundColor: Colors.white,
//           elevation: 0,
//           centerTitle: true,
//           iconTheme: const IconThemeData(color: Colors.black),
//           titleTextStyle: const TextStyle(
//             color: Colors.black,
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         backgroundColor: Colors.white,
//         body: const Center(
//           child: CircularProgressIndicator(),
//         ),
//       );
//     }

//     if (userData.isEmpty) {
//       return Scaffold(
//         appBar: AppBar(
//           title: const Text('QR Code'),
//           backgroundColor: Colors.white,
//           elevation: 0,
//           centerTitle: false,
//           iconTheme: const IconThemeData(color: Colors.black),
//           titleTextStyle: const TextStyle(
//             color: Colors.black,
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         backgroundColor: Colors.white,
//         body: const Center(
//           child: Text('User data not available'),
//         ),
//       );
//     }

//     // Create QR code data with user details - standard format
//     final Map<String, dynamic> qrData = {
//       'type': 'corexmessenger_user',
//       'user_id': widget.peerId,
//       'username': userData['userName'],
//       'phone': userData['phoneNumber'],
//       'country_code': userData['countryCode'],
//     };

//     final qrDataString = json.encode(qrData);
//     final displayName =
//         userData['firstName'] != null && userData['lastName'] != null
//             ? '${userData['firstName']} ${userData['lastName']}'
//             : userData['userName'] ?? 'User';

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('QR Code'),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: false,
//         iconTheme: const IconThemeData(color: Colors.black),
//         titleTextStyle: const TextStyle(
//           color: Colors.black,
//           fontSize: 18,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               const SizedBox(height: 20),
//               // Profile image if available
//               if (userData['profileImage'] != null &&
//                   userData['profileImage'].toString().isNotEmpty)
//                 Container(
//                   width: 80,
//                   height: 80,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     image: DecorationImage(
//                       image: NetworkImage(userData['profileImage']),
//                       fit: BoxFit.cover,
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         spreadRadius: 1,
//                         blurRadius: 4,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                 ),
//               const SizedBox(height: 10),
//               Text(
//                 displayName,
//                 style:
//                     const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//                 textAlign: TextAlign.center,
//               ),
//               if (userData['userName'] != null)
//                 Text(
//                   '@${userData['userName']}',
//                   style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//                   textAlign: TextAlign.center,
//                 ),
//               const SizedBox(height: 30),
//               // Stylish QR Code
//               Container(
//                 width: 260,
//                 height: 260,
//                 padding: const EdgeInsets.all(4),
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.blue.withOpacity(0.3),
//                       spreadRadius: 2,
//                       blurRadius: 15,
//                       offset: const Offset(0, 5),
//                     ),
//                   ],
//                 ),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(18),
//                   ),
//                   padding: const EdgeInsets.all(10),
//                   child: Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       // Base QR code
//                       QrImageView(
//                         data: qrDataString,
//                         version: QrVersions.auto,
//                         size: 232,
//                         backgroundColor: Colors.white,
//                         errorCorrectionLevel: QrErrorCorrectLevel.H,
//                         eyeStyle: const QrEyeStyle(
//                           eyeShape: QrEyeShape.square,
//                           color: Color(0xFF0072FF),
//                         ),
//                         dataModuleStyle: const QrDataModuleStyle(
//                           dataModuleShape: QrDataModuleShape.circle,
//                           color: Color(0xFF303030),
//                         ),
//                       ),

//                       // Logo in center
//                       Container(
//                         width: 60,
//                         height: 60,
//                         // decoration: BoxDecoration(
//                         //   color: Colors.white,
//                         //   shape: BoxShape.circle,
//                         //   boxShadow: [
//                         //     BoxShadow(
//                         //       color: Colors.black.withOpacity(0.15),
//                         //       spreadRadius: 1,
//                         //       blurRadius: 3,
//                         //       offset: const Offset(0, 1),
//                         //     ),
//                         //   ],
//                         // ),
//                         padding: const EdgeInsets.all(5),
//                         child: Container(
//                             decoration: const BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
//                                 begin: Alignment.topLeft,
//                                 end: Alignment.bottomRight,
//                               ),
//                               shape: BoxShape.circle,
//                             ),
//                             child: Image.asset(
//                               'assets/icons/Nobg_qr.png',
//                               color: Colors.white,
//                             )),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 30),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 30.0),
//                 child: Container(
//                   padding: const EdgeInsets.all(15),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFBAE9FD).withOpacity(0.3),
//                     borderRadius: BorderRadius.circular(10),
//                     border: Border.all(
//                       color: const Color(0xFF00C6FF).withOpacity(0.1),
//                       width: 1,
//                     ),
//                   ),
//                   child: Column(
//                     children: [
//                       Text(
//                         'Scan to connect with me on CoreX Messenger',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Colors.blue[800],
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Your QR code is personal. If you share it, others can scan it with their CoreX Messenger camera.',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Colors.black45,
//                           fontSize: 13,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 30),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:corexchat/src/screens/user/widget/verification_badge.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'dart:developer';

class ChatQRGeneratorScreen extends StatefulWidget {
  final int peerId;

  const ChatQRGeneratorScreen({
    Key? key,
    required this.peerId,
  }) : super(key: key);

  @override
  State<ChatQRGeneratorScreen> createState() => _ChatQRGeneratorScreenState();
}

class _ChatQRGeneratorScreenState extends State<ChatQRGeneratorScreen> {
  bool isLoading = true;
  Map<String, dynamic> userData = {};
  int? currentUserId;

  // Constants for Hive keys
  static const String userdata = 'userdata';
  static const String userId = 'userId';
  static const String userName = 'userName';
  static const String firstName = 'firstName';
  static const String lastName = 'lastName';
  static const String userImage = 'userImage';
  static const String phoneNumber = 'phoneNumber';
  static const String countryCode = 'countryCode';
  // Added constants for badge
  static const String userBadge = 'userBadge';
  static const String isUserHaveBadge = 'isUserHaveBadge';

  @override
  void initState() {
    super.initState();
    // Get current user ID from Hive
    currentUserId = Hive.box(userdata).get(userId);
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Create a Map with user data from Hive
      userData = {
        'userId': widget.peerId,
        'userName': Hive.box(userdata).get(userName),
        'firstName': Hive.box(userdata).get(firstName),
        'lastName': Hive.box(userdata).get(lastName),
        'profileImage': Hive.box(userdata).get(userImage),
        'phoneNumber': Hive.box(userdata).get(phoneNumber),
        'countryCode': Hive.box(userdata).get(countryCode),
        // Add badge information
        'hasBadge': Hive.box(userdata).get(isUserHaveBadge) ?? false,
        'badgeLogo': Hive.box(userdata).get(userBadge),
      };

      log('User data loaded: ${userData['firstName']} ${userData['lastName']}');
      log('Badge info: Has badge - ${userData['hasBadge']}, Logo - ${userData['badgeLogo']}');
    } catch (e) {
      log('Error loading user data: $e');
      userData = {};
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('QR Code'),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (userData.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('QR Code'),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: Colors.black),
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        body: const Center(
          child: Text('User data not available'),
        ),
      );
    }

    // Create QR code data with user details - standard format
    final Map<String, dynamic> qrData = {
      'type': 'corexmessenger_user',
      'user_id': widget.peerId,
      'username': userData['userName'],
      'phone': userData['phoneNumber'],
      'country_code': userData['countryCode'],
      // Add badge info to QR data if available
      if (userData['hasBadge'] == true) 'is_verified': true,
      if (userData['badgeLogo'] != null &&
          userData['badgeLogo'].toString().isNotEmpty)
        'verification_logo': userData['badgeLogo'],
    };

    final qrDataString = json.encode(qrData);
    final displayName =
        userData['firstName'] != null && userData['lastName'] != null
            ? '${userData['firstName']} ${userData['lastName']}'
            : userData['userName'] ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Profile image if available
              if (userData['profileImage'] != null &&
                  userData['profileImage'].toString().isNotEmpty)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(userData['profileImage']),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              // Display name with verification badge if available
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  // Show verification badge next to name if available
                  if (userData['badgeLogo'] != null)
                    VerificationLogoWidget(
                      logoUrl: userData['badgeLogo'],
                      size: 20,
                      margin: const EdgeInsets.only(left: 4),
                    ),
                ],
              ),
              if (userData['userName'] != null)
                Text(
                  '@${userData['userName']}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 30),
              // Stylish QR Code
              Container(
                width: 260,
                height: 260,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Base QR code
                      QrImageView(
                        data: qrDataString,
                        version: QrVersions.auto,
                        size: 232,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF0072FF),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.circle,
                          color: Color(0xFF303030),
                        ),
                      ),

                      // Logo in center
                      Container(
                        width: 60,
                        height: 60,
                        padding: const EdgeInsets.all(5),
                        child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              'assets/icons/Nobg_qr.png',
                              color: Colors.white,
                            )),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBAE9FD).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF00C6FF).withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Scan to connect with me on CoreX Messenger',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your QR code is personal. If you share it, others can scan it with their CoreX Messenger camera.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
