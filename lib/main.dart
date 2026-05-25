//flutter version 3.19.6
// ignore_for_file: avoid_print, deprecated_member_use
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:corexchat/controller/launguage_controller.dart';
import 'package:corexchat/native_controller/audio_native_controller.dart';
import 'package:corexchat/src/global/api_helper.dart';
import 'package:corexchat/src/global/global.dart';
import 'package:corexchat/src/global/socket_initiallize.dart';
import 'package:corexchat/src/global/strings.dart';
import 'package:corexchat/src/screens/splash_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:corexchat/src/screens/user/api_config_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebasebackgroundmessagehendler(RemoteMessage message) async {
  print("BackgroundDATA:${message.data.toString()}");
  print("BackgroundTITLE:${message.notification!.title}");
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only essential initialization before UI
  await Firebase.initializeApp();
  if (Platform.isIOS) {
    AudioManager.listenToLogs();
  }
  FirebaseMessaging.onBackgroundMessage(_firebasebackgroundmessagehendler);
  WidgetsBinding.instance.renderView.automaticSystemUiAdjustment = false;
  
  // Configure status bar to be visible throughout the app
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  // Initialize basic Hive setup
  Directory directory = await getApplicationDocumentsDirectory();
  Hive.init(directory.path);
  
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await Hive.initFlutter(appName);
  } else {
    await Hive.initFlutter();
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize timezone and database after UI is shown
      tz.initializeTimeZones();
      await openHiveBox(userdata);
      
      // Initialize language controller
      await Get.put(LanguageController())
          .getLanguageTranslation(lnId: Hive.box(userdata).get(lnId) ?? "");
      
      // Update app colors after settings are loaded
      updateAppColors();
      
      // Initialize socket if user is logged in
      if (Hive.box(userdata).get(userId) != "" &&
          Hive.box(userdata).get(userId) != null) {
        initSocket();
      } else {
        if (kDebugMode) {
          print("NO USER ID AVAILABLE");
        }
      }
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Initialization error: $e");
      }
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: appName,
        color: Colors.white,
        theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Poppins'),
        home: _isInitialized 
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              ),
      ),
    );
  }
}

Future<void> openHiveBox(String boxName) async {
  final box = await Hive.openBox(boxName).onError((error, stackTrace) async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final String dirPath = dir.path;

    File dbFile = File('$dirPath/$boxName.hive');
    File lockFile = File('$dirPath/$boxName.lock');
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      dbFile = File('$dirPath/$appName/$boxName.hive');
      lockFile = File('$dirPath/$appName/$boxName.lock');
    }
    await dbFile.delete();
    await lockFile.delete();
    await Hive.openBox(boxName);
    throw 'Failed to open $boxName Box\nError: $error';
  });

  if (box.length > 500) {
    box.clear();
  }
}

SocketIntilized socketIntilized = SocketIntilized();

Future<void> initSocket() async {
  if (Hive.box(userdata).get(authToken) != '' &&
      Hive.box(userdata).get(authToken) != null) {
    await socketIntilized.initlizedsocket();
  }
}
