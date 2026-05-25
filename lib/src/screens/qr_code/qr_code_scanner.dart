import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:io';
import 'package:get/get.dart';
import 'package:corexchat/controller/user_chatlist_controller.dart';
import 'dart:convert';
import 'dart:developer';

import 'package:corexchat/src/screens/chat/single_chat.dart';

class ChatQRScannerScreen extends StatefulWidget {
  const ChatQRScannerScreen({Key? key}) : super(key: key);

  @override
  State<ChatQRScannerScreen> createState() => _ChatQRScannerScreenState();
}

class _ChatQRScannerScreenState extends State<ChatQRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _scanned = false;
  bool _isFlashOn = false;

  // Get the chat list controller
  final ChatListController chatListController = Get.find<ChatListController>();

  // In order to get hot reload to work we need to pause the camera
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Stack(
        children: <Widget>[
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.blue,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: MediaQuery.of(context).size.width * 0.8,
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Point your camera at a CoreX Messenger QR code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(_isFlashOn ? Icons.flash_off : Icons.flash_on),
                onPressed: () async {
                  await controller?.toggleFlash();
                  setState(() {
                    _isFlashOn = !_isFlashOn;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!_scanned && scanData.code != null) {
        _scanned = true; // Prevent multiple readings
        _handleScannedCode(scanData.code!);
      }
    });
  }

  void _handleScannedCode(String code) {
    // Prevent scanning again
    controller?.pauseCamera();

    // Print for debugging
    log("Scanned QR code: $code");

    // Parse the QR code data
    try {
      // First try to parse as JSON
      Map<String, dynamic> userData = json.decode(code);

      // Check if it's a CoreX Messenger user QR code
      if (userData.containsKey('type') &&
          userData['type'] == 'corexmessenger_user') {
        final userId = userData['user_id'];
        final username = userData['username'] ?? 'User';
        final profileImage = userData['profile_image'];
        final phoneNumber = userData['phone'] ?? '';

        // Extract verification badge information
        final isVerified = userData['is_verified'] ?? false;
        final verificationLogo = userData['verification_logo'];

        if (userId != null) {
          // Use the chat list logic to navigate to chat screen
          _navigateWithChatListCheck(
            userId.toString(),
            username,
            profileImage,
            phoneNumber,
            isVerified,
            verificationLogo,
          );
          return;
        }
      }

      // If it's not a valid JSON or doesn't have the right format,
      // Try the old URL format as a fallback
      if (code.startsWith('shareqr://')) {
        final uri = Uri.parse(code);

        if (uri.scheme == 'shareqr') {
          final userId = uri.host;
          final name = uri.queryParameters['name'] ?? 'User';
          final phoneNumber = uri.queryParameters['phone'] ?? '';

          if (userId.isNotEmpty) {
            // Use the chat list logic to navigate to chat screen
            // Note: Old format doesn't support verification badge
            _navigateWithChatListCheck(
              userId,
              name,
              null,
              phoneNumber,
              false,
              null,
            );
            return;
          }
        }
      }

      // If we got here, it's not in a format we recognize
      _showInvalidQRCodeMessage();
    } catch (e) {
      log("Error parsing QR code: $e");
      _showInvalidQRCodeMessage();
    }
  }

  void _navigateWithChatListCheck(
    String userId,
    String fullName,
    String? profileImage,
    String phoneNumber,
    bool isVerified,
    String? verificationLogo,
  ) {
    // Close the scanner screen first
    Get.back();

    // Safely check if model and chatList exist
    final chatListModel = chatListController.userChatListModel.value;
    if (chatListModel == null) {
      log('Chat list model is null');
      _navigateToSingleChat('', fullName, profileImage, phoneNumber, userId,
          false, verificationLogo);
      return;
    }

    final chatList = chatListModel.chatList;
    if (chatList == null) {
      log('Chat list is null');
      _navigateToSingleChat('', fullName, profileImage, phoneNumber, userId,
          false, verificationLogo);
      return;
    }

    if (chatList.isEmpty) {
      log('Chat list is empty');
      _navigateToSingleChat('', fullName, profileImage, phoneNumber, userId,
          false, verificationLogo);
    } else {
      final matchingChats =
          chatList.where((element) => userId == element.userId?.toString());
      if (matchingChats.isNotEmpty) {
        final data = matchingChats.first;
        _navigateToSingleChat(
          data.conversationId?.toString() ?? '',
          fullName,
          profileImage,
          phoneNumber,
          userId,
          data.isBlock ?? false,
          verificationLogo,
        );
      } else {
        _navigateToSingleChat('', fullName, profileImage, phoneNumber, userId,
            false, verificationLogo);
      }
    }
  }

  void _navigateToSingleChat(
    String conversationId,
    String username,
    String? userPic,
    String mobileNum,
    String userId,
    bool isBlock,
    String? verificationLogo,
  ) {
    Get.to(
      () => SingleChatMsg(
        conversationID: conversationId,
        username: username,
        userPic: userPic,
        mobileNum: mobileNum,
        index: 0,
        isMsgHighLight: false,
        isBlock: isBlock,
        userID: userId,
        verificationBadge: verificationLogo,
      ),
      transition: Transition.rightToLeft,
      curve: Curves.linear,
    );
  }

  void _showInvalidQRCodeMessage() {
    // Pause camera immediately
    controller?.pauseCamera();
    _scanned = true;

    // Show a modal dialog instead of snackbar
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.qr_code_scanner, color: Colors.red.shade700),
              SizedBox(width: 10),
              Text('Invalid QR Code',
                  style: TextStyle(color: Colors.red.shade700)),
            ],
          ),
          content: Text(
            'This QR code is not valid for this application.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              child: Text(
                'Try Again',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                controller?.resumeCamera();
                _scanned = false;
              },
            ),
          ],
        );
      },
    );

    // Auto-dismiss after 3 seconds if user doesn't press button
    Future.delayed(Duration(seconds: 3), () {
      if (_scanned) {
        Navigator.of(Get.context!).pop();
        controller?.resumeCamera();
        _scanned = false;
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
