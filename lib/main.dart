// =============================================================================
// CoreX Messenger
// =============================================================================
//
// Main Application Entry Point
//
// =============================================================================
//
// Stable Configuration For:
//
// ✔ Flutter 3.19.x - 3.24.x
// ✔ Firebase Messaging
// ✔ Hive Local Database
// ✔ GetX State Management
// ✔ Socket Initialization
// ✔ Multi Language Support
// ✔ Android
// ✔ iOS
// ✔ macOS
// ✔ Windows
// ✔ Linux
// ✔ Codemagic CI/CD
//
// =============================================================================
//
// IMPORTANT NOTES
//
// This file is restored and stabilized for:
//
// ✔ Legacy CoreX Messenger source compatibility
// ✔ Stable .aab generation
// ✔ Stable .ipa generation
// ✔ Firebase background handling
// ✔ Hive crash recovery
// ✔ Smooth startup initialization
//
// =============================================================================

// ignore_for_file: avoid_print, deprecated_member_use

// =============================================================================
// DART IMPORTS
// =============================================================================

import 'dart:io';

// =============================================================================
// FLUTTER IMPORTS
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// =============================================================================
// FIREBASE
// =============================================================================

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// =============================================================================
// STATE MANAGEMENT
// =============================================================================

import 'package:get/get.dart';

// =============================================================================
// LOCAL STORAGE
// =============================================================================

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

// =============================================================================
// TIMEZONE
// =============================================================================

import 'package:timezone/data/latest.dart' as tz;

// =============================================================================
// COREX IMPORTS
// =============================================================================

import 'package:corexchat/controller/launguage_controller.dart';

import 'package:corexchat/native_controller/audio_native_controller.dart';

import 'package:corexchat/src/global/api_helper.dart';
import 'package:corexchat/src/global/global.dart';
import 'package:corexchat/src/global/socket_initiallize.dart';
import 'package:corexchat/src/global/strings.dart';

import 'package:corexchat/src/screens/splash_screen.dart';
import 'package:corexchat/src/screens/user/api_config_screen.dart';

// =============================================================================
// FIREBASE BACKGROUND HANDLER
// =============================================================================

@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(
  RemoteMessage message,
) async {
  try {
    await Firebase.initializeApp();

    if (kDebugMode) {
      print("BACKGROUND DATA : ${message.data}");
      print("BACKGROUND TITLE : ${message.notification?.title}");
    }
  } catch (e) {
    if (kDebugMode) {
      print("Firebase Background Error : $e");
    }
  }
}

// =============================================================================
// MAIN FUNCTION
// =============================================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // SYSTEM UI CONFIGURATION
  // ---------------------------------------------------------------------------

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // ---------------------------------------------------------------------------
  // FIREBASE INITIALIZATION
  // ---------------------------------------------------------------------------

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(
    firebaseBackgroundMessageHandler,
  );

  // ---------------------------------------------------------------------------
  // IOS AUDIO LOGS
  // ---------------------------------------------------------------------------

  if (Platform.isIOS) {
    AudioManager.listenToLogs();
  }

  // ---------------------------------------------------------------------------
  // HIVE INITIALIZATION
  // ---------------------------------------------------------------------------

  final Directory directory = await getApplicationDocumentsDirectory();

  Hive.init(directory.path);

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await Hive.initFlutter(appName);
  } else {
    await Hive.initFlutter();
  }

  // ---------------------------------------------------------------------------
  // RUN APPLICATION
  // ---------------------------------------------------------------------------

  runApp(const MyApp());
}

// =============================================================================
// APPLICATION ROOT
// =============================================================================

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// =============================================================================
// APPLICATION STATE
// =============================================================================

class _MyAppState extends State<MyApp> {
  // ---------------------------------------------------------------------------
  // LOADING STATE
  // ---------------------------------------------------------------------------

  bool isInitialized = false;

  // ---------------------------------------------------------------------------
  // INIT STATE
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    initializeApplication();
  }

  // =============================================================================
  // INITIALIZE APPLICATION
  // =============================================================================

  Future<void> initializeApplication() async {
    try {
      // -----------------------------------------------------------------------
      // TIMEZONE
      // -----------------------------------------------------------------------

      tz.initializeTimeZones();

      // -----------------------------------------------------------------------
      // OPEN HIVE BOX
      // -----------------------------------------------------------------------

      await openHiveBox(userdata);

      // -----------------------------------------------------------------------
      // LANGUAGE INITIALIZATION
      // -----------------------------------------------------------------------

      await Get.put(
        LanguageController(),
      ).getLanguageTranslation(
        lnId: Hive.box(userdata).get(lnId) ?? "",
      );

      // -----------------------------------------------------------------------
      // UPDATE APP COLORS
      // -----------------------------------------------------------------------

      updateAppColors();

      // -----------------------------------------------------------------------
      // SOCKET INITIALIZATION
      // -----------------------------------------------------------------------

      final dynamic currentUserId = Hive.box(userdata).get(userId);

      if (currentUserId != null && currentUserId.toString().isNotEmpty) {
        await initializeSocket();
      } else {
        if (kDebugMode) {
          print("NO USER ID AVAILABLE");
        }
      }

      // -----------------------------------------------------------------------
      // UPDATE UI
      // -----------------------------------------------------------------------

      if (mounted) {
        setState(() {
          isInitialized = true;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("APPLICATION INITIALIZATION ERROR : $e");
      }

      if (mounted) {
        setState(() {
          isInitialized = true;
        });
      }
    }
  }

  // =============================================================================
  // BUILD UI
  // =============================================================================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: GetMaterialApp(
        // ---------------------------------------------------------------------
        // GENERAL
        // ---------------------------------------------------------------------

        debugShowCheckedModeBanner: false,

        title: appName,

        color: Colors.white,

        // ---------------------------------------------------------------------
        // THEME
        // ---------------------------------------------------------------------

        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Poppins',
        ),

        // ---------------------------------------------------------------------
        // HOME
        // ---------------------------------------------------------------------

        home: isInitialized
            ? Obx(
                () => Directionality(
                  textDirection: Get.find<LanguageController>().textDirection(),
                  child: ApiHelper.baseUrl == ApiHelper.staticBaseUrl
                      ? const ApiConfigScreen()
                      : const SplashScreen(),
                ),
              )
            : const Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

// =============================================================================
// OPEN HIVE BOX
// =============================================================================

Future<void> openHiveBox(String boxName) async {
  final box = await Hive.openBox(boxName).onError(
    (error, stackTrace) async {
      final Directory dir = await getApplicationDocumentsDirectory();

      final String dirPath = dir.path;

      File dbFile = File('$dirPath/$boxName.hive');

      File lockFile = File('$dirPath/$boxName.lock');

      // -----------------------------------------------------------------------
      // DESKTOP SUPPORT
      // -----------------------------------------------------------------------

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        dbFile = File(
          '$dirPath/$appName/$boxName.hive',
        );

        lockFile = File(
          '$dirPath/$appName/$boxName.lock',
        );
      }

      // -----------------------------------------------------------------------
      // DELETE CORRUPTED FILES
      // -----------------------------------------------------------------------

      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      if (await lockFile.exists()) {
        await lockFile.delete();
      }

      // -----------------------------------------------------------------------
      // REOPEN HIVE
      // -----------------------------------------------------------------------

      await Hive.openBox(boxName);

      throw 'Failed to open $boxName Box\nError: $error';
    },
  );

  // ---------------------------------------------------------------------------
  // CLEAN LARGE BOXES
  // ---------------------------------------------------------------------------

  // Avoid wiping auth/session data on large local caches.
  if (box.length > 5000) {
    if (kDebugMode) {
      print('Hive box $boxName is unusually large (${box.length} entries).');
    }
  }
}

// =============================================================================
// SOCKET INITIALIZATION
// =============================================================================

SocketIntilized socketIntilized = SocketIntilized();

Future<void> initializeSocket() async {
  final token = Hive.box(userdata).get(authToken);

  if (token != null && token.toString().isNotEmpty) {
    await socketIntilized.initlizedsocket();
  }
}

// =============================================================================
// END OF FILE
// =============================================================================
