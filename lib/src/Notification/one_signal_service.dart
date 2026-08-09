// ignore_for_file: avoid_print

import 'dart:io';

import 'package:corexchat/Models/calls_Model/joined_users_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:get/get.dart';
import 'package:corexchat/app.dart';
import 'package:corexchat/controller/call_controller.dart/get_roomId_controller.dart';
import 'package:corexchat/controller/user_chatlist_controller.dart';
import 'package:corexchat/native_controller/audio_native_controller.dart';
import 'package:corexchat/src/screens/call/web_rtc/audio_call_screen.dart';
import 'package:corexchat/src/screens/call/web_rtc/incoming_call_screen.dart';
import 'package:corexchat/src/screens/call/web_rtc/video_call_screen.dart';
import 'package:corexchat/src/screens/chat/group_chat_temp.dart';
import 'package:corexchat/src/screens/chat/single_chat.dart';
import 'package:corexchat/src/screens/layout/bottombar.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class OnesignalService {
  final RoomIdController roomIdController = Get.put(RoomIdController());
  bool _foregroundListenerRegistered = false;
  bool _clickListenerRegistered = false;

  initialize() {
    if (languageController.appSettingsOneSignalData.isEmpty) {
      if (kDebugMode) {
        print("OneSignal initialization skipped: app ID is unavailable");
      }
      return;
    }

    final appId =
        languageController.appSettingsOneSignalData.first.oneSignalAppId;
    if (appId == null || appId.isEmpty) {
      if (kDebugMode) {
        print("OneSignal initialization skipped: app ID is empty");
      }
      return;
    }

    OneSignal.Debug.setLogLevel(
      kDebugMode ? OSLogLevel.verbose : OSLogLevel.none,
    );
    OneSignal.initialize(appId);
    // OneSignal.initialize("fa0d2111-1ab5-49d7-ad5d-976b8d9d66a4");
    OneSignal.User.pushSubscription.addObserver((state) {
      print(
          "pushSubscription optedIn ${OneSignal.User.pushSubscription.optedIn}");
      print("pushSubscription id ${OneSignal.User.pushSubscription.id}");
      print("pushSubscription token ${OneSignal.User.pushSubscription.token}");
      print(
          "pushSubscription current.jsonRepresentation ${state.current.jsonRepresentation()}");
    });

    OneSignal.Notifications.requestPermission(true);
  }

  // onNotifiacation() {
  //   OneSignal.Notifications.addForegroundWillDisplayListener((event) {
  //     print("event body ${event.notification.additionalData}");
  //     if (event.notification.additionalData!['call_type'].toString() ==
  //         'video_call') {
  //       print("video call");
  //       if (event.notification.additionalData!['missed_call'].toString() ==
  //           'true') {
  //         print('get the pickup point>?>>> miscall');
  //         OneSignal.Notifications.clearAll();
  //         stopRingtone();
  //         Get.offAll(
  //           TabbarScreen(
  //             currentTab: 0,
  //           ),
  //         );
  //         Get.put(ChatListController()).forChatList();
  //       } else {
  //         print('get the pickup point>?>>>');
  //         Get.to(IncomingCallScrenn(
  //           roomID: event.notification.additionalData!['room_id'].toString(),
  //           callerImage: event
  //               .notification.additionalData!['sender_profile_image']
  //               .toString(),
  //           senderName:
  //               event.notification.additionalData!['senderName'].toString(),
  //           conversation_id: event
  //               .notification.additionalData!['conversation_id']
  //               .toString(),
  //           message_id:
  //               event.notification.additionalData!['message_id'].toString(),
  //           caller_id:
  //               event.notification.additionalData!['senderId'].toString(),
  //           isGroupCall:
  //               event.notification.additionalData!['is_group'].toString(),
  //           verificationType:
  //               event.notification.additionalData!['Varification_type'],
  //         ));
  //         FlutterRingtonePlayer().playRingtone();

  //         AudioManager.setEarpiece();
  //       }
  //     } else if (event.notification.additionalData!['call_type'].toString() ==
  //         'audio_call') {
  //       print("audio call");
  //       if (event.notification.additionalData!['missed_call'].toString() ==
  //           "true") {
  //         OneSignal.Notifications.clearAll();
  //         stopRingtone();
  //         Get.offAll(
  //           TabbarScreen(
  //             currentTab: 0,
  //           ),
  //         );
  //         Get.put(ChatListController()).forChatList();
  //       } else {
  //         Get.to(IncomingCallScrenn(
  //           roomID: event.notification.additionalData!['room_id'].toString(),
  //           callerImage: event
  //               .notification.additionalData!['sender_profile_image']
  //               .toString(),
  //           senderName:
  //               event.notification.additionalData!['senderName'].toString(),
  //           conversation_id: event
  //               .notification.additionalData!['conversation_id']
  //               .toString(),
  //           message_id:
  //               event.notification.additionalData!['message_id'].toString(),
  //           caller_id:
  //               event.notification.additionalData!['senderId'].toString(),
  //           forVideoCall: false,
  //           receiverImage: event
  //               .notification.additionalData!['receiver_profile_image']
  //               .toString(),
  //           isGroupCall:
  //               event.notification.additionalData!['is_group'].toString(),
  //           verificationType:
  //               event.notification.additionalData!['Varification_type'],
  //         ));
  //         FlutterRingtonePlayer().playRingtone();
  //         AudioManager.setEarpiece();
  //       }
  //     }
  //   });
  // }

  onNotifiacation() {
    if (_foregroundListenerRegistered) return;
    _foregroundListenerRegistered = true;
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print("🔍 NOTIFICATION RECEIVED: ${event.notification}");
      print("🔍 ADDITIONAL DATA: ${event.notification.additionalData}");

      // Safely check if additionalData exists
      if (event.notification.additionalData == null) {
        print("❌ ERROR: additionalData is null");
        return;
      }

      try {
        if (event.notification.additionalData!['call_type'].toString() ==
            'video_call') {
          print("🎥 Processing VIDEO CALL notification");

          if (event.notification.additionalData!['missed_call'].toString() ==
              'true') {
            print("📱 Handling MISSED video call");
            OneSignal.Notifications.clearAll();
            stopRingtone();
            Get.offAll(
              TabbarScreen(
                currentTab: 0,
              ),
            );
            Get.put(ChatListController()).forChatList();
          } else {
            print("📱 Handling INCOMING video call");

            // Check for null explicitly - don't try to parse null values
            VerificationType? verificationType;

            // Only try to create VerificationType if it's not null in the payload
            if (event.notification.additionalData!
                    .containsKey('Varification_type') &&
                event.notification.additionalData!['Varification_type'] !=
                    null) {
              print(
                  "🔍 Found verification type: ${event.notification.additionalData!['Varification_type']}");
              // Create VerificationType object
              verificationType = VerificationType(
                logo: event
                    .notification.additionalData!['Varification_type']['logo']
                    ?.toString(),
                // Add other fields as needed
              );
            } else {
              print("ℹ️ Verification type is null in notification");
            }

            // Create IncomingCallScrenn with explicit null check for verificationType
            print(
                "📱 Navigating to IncomingCallScrenn with verificationType: $verificationType");
            Get.to(IncomingCallScrenn(
              roomID: event.notification.additionalData!['room_id'].toString(),
              callerImage: event
                  .notification.additionalData!['sender_profile_image']
                  .toString(),
              senderName:
                  event.notification.additionalData!['senderName'].toString(),
              conversation_id: event
                  .notification.additionalData!['conversation_id']
                  .toString(),
              message_id:
                  event.notification.additionalData!['message_id'].toString(),
              caller_id:
                  event.notification.additionalData!['senderId'].toString(),
              isGroupCall:
                  event.notification.additionalData!['is_group'].toString(),
              verificationType:
                  verificationType, // Will be null based on your logs
            ));
            FlutterRingtonePlayer().playRingtone();
            AudioManager.setEarpiece();
          }
        } else if (event.notification.additionalData!['call_type'].toString() ==
            'audio_call') {
          // Similar changes for audio call section...
          print("🔊 Processing AUDIO CALL notification");

          if (event.notification.additionalData!['missed_call'].toString() ==
              "true") {
            print("📱 Handling MISSED audio call");
            OneSignal.Notifications.clearAll();
            stopRingtone();
            Get.offAll(
              TabbarScreen(
                currentTab: 0,
              ),
            );
            Get.put(ChatListController()).forChatList();
          } else {
            print("📱 Handling INCOMING audio call");

            // Same verification type handling as above
            VerificationType? verificationType;
            if (event.notification.additionalData!
                    .containsKey('Varification_type') &&
                event.notification.additionalData!['Varification_type'] !=
                    null) {
              print(
                  "🔍 Found verification type: ${event.notification.additionalData!['Varification_type']}");
              verificationType = VerificationType(
                logo: event
                    .notification.additionalData!['Varification_type']['logo']
                    ?.toString(),
                // Add other fields as needed
              );
            } else {
              print("ℹ️ Verification type is null in notification");
            }

            print(
                "📱 Navigating to IncomingCallScrenn with verificationType: $verificationType");
            Get.to(IncomingCallScrenn(
              roomID: event.notification.additionalData!['room_id'].toString(),
              callerImage: event
                  .notification.additionalData!['sender_profile_image']
                  .toString(),
              senderName:
                  event.notification.additionalData!['senderName'].toString(),
              conversation_id: event
                  .notification.additionalData!['conversation_id']
                  .toString(),
              message_id:
                  event.notification.additionalData!['message_id'].toString(),
              caller_id:
                  event.notification.additionalData!['senderId'].toString(),
              forVideoCall: false,
              receiverImage: event
                  .notification.additionalData!['receiver_profile_image']
                  .toString(),
              isGroupCall:
                  event.notification.additionalData!['is_group'].toString(),
              verificationType:
                  verificationType, // Will be null based on your logs
            ));
            FlutterRingtonePlayer().playRingtone();
            AudioManager.setEarpiece();
          }
        }
      } catch (e, stackTrace) {
        print("❌ ERROR in notification processing: $e");
        print("❌ STACK TRACE: $stackTrace");
      }
    });
  }

  // onNotificationClick() {
  //   OneSignal.Notifications.addClickListener((event) {
  //     if (event.result.actionId == "accept") {
  //       print("actionId accept");
  //       if (event.notification.additionalData!['call_type'].toString() ==
  //           'video_call') {
  //         print("video call");

  //         stopRingtone();
  //         Get.off(VideoCallScreen(
  //           roomID: event.notification.additionalData!['room_id'].toString(),
  //           conversation_id: event
  //               .notification.additionalData!['conversation_id']
  //               .toString(),
  //           isGroupCall:
  //               event.notification.additionalData!['is_group'].toString(),
  //         ));
  //       } else if (event.notification.additionalData!['call_type'].toString() ==
  //           'audio_call') {
  //         print("audio call");

  //         stopRingtone();
  //         Get.off(AudioCallScreen(
  //           roomID: event.notification.additionalData!['room_id'].toString(),
  //           conversation_id: event
  //               .notification.additionalData!['conversation_id']
  //               .toString(),
  //           receiverImage: event
  //               .notification.additionalData!["sender_profile_image"]
  //               .toString(),
  //           receiverUserName:
  //               event.notification.additionalData!["senderName"].toString(),
  //           isGroupCall:
  //               event.notification.additionalData!['is_group'].toString(),
  //         ));
  //       }
  //     } else if (event.result.actionId == "decline") {
  //       print("actionId decline");
  //       if (event.notification.additionalData!['call_type'].toString() ==
  //           'video_call') {
  //         stopRingtone();
  //         if (event.notification.additionalData!['is_group'].toString() ==
  //             "true") {
  //           Get.offAll(
  //             TabbarScreen(
  //               currentTab: 0,
  //             ),
  //           );
  //         } else {
  //           roomIdController.callCutByReceiver(
  //             conversationID: event
  //                 .notification.additionalData!['conversation_id']
  //                 .toString(),
  //             message_id:
  //                 event.notification.additionalData!['message_id'].toString(),
  //             caller_id:
  //                 event.notification.additionalData!['senderId'].toString(),
  //           );
  //         }
  //       } else if (event.notification.additionalData!['call_type'].toString() ==
  //           'audio_call') {
  //         stopRingtone();
  //         if (event.notification.additionalData!['is_group'].toString() ==
  //             "true") {
  //           Get.offAll(
  //             TabbarScreen(
  //               currentTab: 0,
  //             ),
  //           );
  //         } else {
  //           roomIdController.callCutByReceiver(
  //             conversationID: event
  //                 .notification.additionalData!['conversation_id']
  //                 .toString(),
  //             message_id:
  //                 event.notification.additionalData!['message_id'].toString(),
  //             caller_id:
  //                 event.notification.additionalData!['senderId'].toString(),
  //           );
  //         }
  //       }
  //     } else {
  //       if (event.notification.additionalData!['call_type'].toString() ==
  //               'video_call' &&
  //           event.notification.additionalData!['missed_call'].toString() ==
  //               'false') {
  //         stopRingtone();
  //         Get.to(IncomingCallScrenn(
  //           roomID: event.notification.additionalData!['room_id'].toString(),
  //           callerImage: event
  //               .notification.additionalData!['sender_profile_image']
  //               .toString(),
  //           senderName:
  //               event.notification.additionalData!['senderName'].toString(),
  //           conversation_id: event
  //               .notification.additionalData!['conversation_id']
  //               .toString(),
  //           message_id:
  //               event.notification.additionalData!['message_id'].toString(),
  //           caller_id:
  //               event.notification.additionalData!['senderId'].toString(),
  //           isGroupCall:
  //               event.notification.additionalData!['is_group'].toString(),
  //           verificationType:
  //               event.notification.additionalData!['Varification_type'],
  //         ));
  //       } else if (event.notification.additionalData!['call_type'].toString() ==
  //               'audio_call' &&
  //           event.notification.additionalData!['missed_call'].toString() ==
  //               'false') {
  //         stopRingtone();
  //         Get.to(IncomingCallScrenn(
  //           roomID: event.notification.additionalData!['room_id'].toString(),
  //           callerImage: event
  //               .notification.additionalData!['sender_profile_image']
  //               .toString(),
  //           senderName:
  //               event.notification.additionalData!['senderName'].toString(),
  //           conversation_id: event
  //               .notification.additionalData!['conversation_id']
  //               .toString(),
  //           message_id:
  //               event.notification.additionalData!['message_id'].toString(),
  //           caller_id:
  //               event.notification.additionalData!['senderId'].toString(),
  //           forVideoCall: false,
  //           receiverImage: event
  //               .notification.additionalData!['receiver_profile_image']
  //               .toString(),
  //           isGroupCall:
  //               event.notification.additionalData!['is_group'].toString(),
  //           verificationType:
  //               event.notification.additionalData!['Varification_type'],
  //         ));
  //       } else if (event.notification.additionalData!['notification_type']
  //                   .toString() ==
  //               'message' &&
  //           event.notification.additionalData!['is_group'].toString() ==
  //               'false') {
  //         // Get.find<SingleChatContorller>().getdetailschat(
  //         //     event.notification.additionalData!['conversation_id'].toString());
  //         Get.to(SingleChatMsg(
  //           conversationID: event
  //               .notification.additionalData!['conversation_id']
  //               .toString(),
  //           username:
  //               event.notification.additionalData!['senderName'].toString(),
  //           userPic:
  //               event.notification.additionalData!['profile_image'].toString(),
  //           index: 0,
  //           isMsgHighLight: false,
  //           isBlock: bool.parse(event.notification.additionalData!['is_block']),
  //           userID: event.notification.additionalData!['senderId'].toString(),
  //         ));
  //       } else if (event.notification.additionalData!['notification_type']
  //                   .toString() ==
  //               'message' &&
  //           event.notification.additionalData!['is_group'].toString() ==
  //               'true') {
  //         Get.to(GroupChatMsg(
  //           conversationID: event
  //               .notification.additionalData!['conversation_id']
  //               .toString(),
  //           gPusername:
  //               event.notification.additionalData!['senderName'].toString(),
  //           gPPic:
  //               event.notification.additionalData!['profile_image'].toString(),
  //           index: 0,
  //           isMsgHighLight: false,
  //         ));
  //       }
  //     }
  //   });
  // }

  onNotificationClick() {
    if (_clickListenerRegistered) return;
    _clickListenerRegistered = true;
    OneSignal.Notifications.addClickListener((event) {
      final additionalData = event.notification.additionalData;
      if (additionalData == null) {
        return;
      }

      try {
        if (event.result.actionId == "accept") {
          if (additionalData['call_type'].toString() == 'video_call') {
            stopRingtone();
            Get.off(VideoCallScreen(
              roomID: additionalData['room_id'].toString(),
              conversation_id: additionalData['conversation_id'].toString(),
              isGroupCall: additionalData['is_group'].toString(),
            ));
          } else if (additionalData['call_type'].toString() == 'audio_call') {
            stopRingtone();
            Get.off(AudioCallScreen(
              roomID: additionalData['room_id'].toString(),
              conversation_id: additionalData['conversation_id'].toString(),
              receiverImage:
                  additionalData["sender_profile_image"].toString(),
              receiverUserName: additionalData["senderName"].toString(),
              isGroupCall: additionalData['is_group'].toString(),
            ));
          }
        } else if (event.result.actionId == "decline") {
          stopRingtone();
          if (additionalData['is_group'].toString() == "true") {
            Get.offAll(
              TabbarScreen(
                currentTab: 0,
              ),
            );
          } else {
            roomIdController.callCutByReceiver(
              conversationID: additionalData['conversation_id'].toString(),
              message_id: additionalData['message_id'].toString(),
              caller_id: additionalData['senderId'].toString(),
            );
          }
        } else if (additionalData['call_type'].toString() == 'video_call' &&
            additionalData['missed_call'].toString() == 'false') {
          stopRingtone();
          Get.to(IncomingCallScrenn(
            roomID: additionalData['room_id'].toString(),
            callerImage: additionalData['sender_profile_image'].toString(),
            senderName: additionalData['senderName'].toString(),
            conversation_id: additionalData['conversation_id'].toString(),
            message_id: additionalData['message_id'].toString(),
            caller_id: additionalData['senderId'].toString(),
            isGroupCall: additionalData['is_group'].toString(),
            verificationType: additionalData['Varification_type']
                is Map<String, dynamic>
                ? VerificationType(
                    logo: additionalData['Varification_type']['logo']
                        ?.toString(),
                  )
                : null,
          ));
        } else if (additionalData['call_type'].toString() == 'audio_call' &&
            additionalData['missed_call'].toString() == 'false') {
          stopRingtone();
          Get.to(IncomingCallScrenn(
            roomID: additionalData['room_id'].toString(),
            callerImage: additionalData['sender_profile_image'].toString(),
            senderName: additionalData['senderName'].toString(),
            conversation_id: additionalData['conversation_id'].toString(),
            message_id: additionalData['message_id'].toString(),
            caller_id: additionalData['senderId'].toString(),
            forVideoCall: false,
            receiverImage:
                additionalData['receiver_profile_image'].toString(),
            isGroupCall: additionalData['is_group'].toString(),
            verificationType: additionalData['Varification_type']
                is Map<String, dynamic>
                ? VerificationType(
                    logo: additionalData['Varification_type']['logo']
                        ?.toString(),
                  )
                : null,
          ));
        } else if (additionalData['notification_type'].toString() ==
                'message' &&
            additionalData['is_group'].toString() == 'false') {
          Get.to(SingleChatMsg(
            conversationID: additionalData['conversation_id'].toString(),
            username: additionalData['senderName'].toString(),
            userPic: additionalData['profile_image'].toString(),
            index: 0,
            isMsgHighLight: false,
            isBlock: bool.tryParse(
                    additionalData['is_block']?.toString() ?? '') ??
                false,
            userID: additionalData['senderId'].toString(),
          ));
        } else if (additionalData['notification_type'].toString() ==
                'message' &&
            additionalData['is_group'].toString() == 'true') {
          Get.to(GroupChatMsg(
            conversationID: additionalData['conversation_id'].toString(),
            gPusername: additionalData['senderName'].toString(),
            gPPic: additionalData['profile_image'].toString(),
            index: 0,
            isMsgHighLight: false,
          ));
        }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print("❌ ERROR in notification click processing: $e");
          print("❌ STACK TRACE: $stackTrace");
        }
      }
    });
  }
}

stopRingtone() {
  if (Platform.isAndroid) {
    FlutterRingtonePlayer().stop();
  } else {
    AudioManager.pauseAudio();
  }
}
