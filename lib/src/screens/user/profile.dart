// ignore_for_file: avoid_print, use_build_context_synchronously, unnecessary_null_comparison
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:corexchat/src/screens/user/widget/verification_badge.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:corexchat/Models/user_profile_model.dart';
import 'package:corexchat/app.dart';
import 'package:corexchat/controller/all_block_list_controller.dart';
import 'package:corexchat/controller/all_star_msg_controller.dart';
import 'package:corexchat/controller/avatar_controller.dart';
import 'package:corexchat/src/global/api_helper.dart';
import 'package:corexchat/src/global/global.dart';
import 'package:corexchat/src/global/strings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:corexchat/src/screens/chat/allstarred_msg_list.dart';
import 'package:corexchat/src/screens/normal_badge_request/badge_request_screen.dart';
import 'package:corexchat/src/screens/qr_code/qr_code_scanner.dart';
import 'package:corexchat/src/screens/qr_code/qr_generator_screen.dart';
import 'package:corexchat/src/screens/subscription/subplan/sub_plan.dart';
import 'package:corexchat/src/screens/support/support.dart';
import 'package:corexchat/src/screens/user/FinalLogin.dart';
import 'package:corexchat/src/screens/user/block_contact_list.dart';
import 'package:corexchat/src/screens/user/create_profile.dart';
import 'package:corexchat/src/screens/user/language_popup.dart';
import 'package:corexchat/src/screens/user/profile_about.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:developer';
import 'package:corexchat/src/screens/user/widget/banner_img_widget.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  AllBlockListController allBlockListController = Get.find();
  AllStaredMsgController allStaredMsgController = Get.find();
  AvatarController avatarController = Get.find();
  String badgeUrl = '';
  int verificationTypeId = 0;

  // Add variable to track verification request status
  String? verificationStatus;
  String? rejectReason;
  bool hasVerificationBeenAccepted = false;
  bool activePlan = false;
  // bool isUserBadeRevoke = false;

  @override
  void initState() {
    fetchUserDetailsAPI();
    print(
      checkForNull(Hive.box(userdata).get(userGender)) != null
          ? Hive.box(userdata).get(userGender).toString().toTitleCase()
          : '',
    );
    allBlockListController.getBlockListApi();
    allStaredMsgController.getAllStarMsg('');
    super.initState();
  }

  bool isLoading = false;
  File? image;
  final picker = ImagePicker();

  final ApiHelper apiHelper = ApiHelper();
  UserProfileModel userProfileModel = UserProfileModel();

  fetchUserDetailsAPI() async {
    print('user profile called >>');
    closeKeyboard();

    setState(() {
      isLoading = true;
    });

    var uri = Uri.parse(apiHelper.userCreateProfile);
    var request = http.MultipartRequest("POST", uri);
    Map<String, String> headers = {
      "Accept": "application/json",
      'Authorization': 'Bearer ${Hive.box(userdata).get(authToken)}'
    };
    request.headers.addAll(headers);

    var response = await request.send();

    String responseData = await response.stream.transform(utf8.decoder).join();
    var userData = json.decode(responseData);
    log('userdetails api call tab bar : $userData ');
    userProfileModel = UserProfileModel.fromJson(userData);

    if (userProfileModel.success == true) {
      // Check if user's badge is revoked by looking at revocations list
      // isUserBadeRevoke = userProfileModel.resData?.revocations != null &&
      //     userProfileModel.resData!.revocations!.isNotEmpty;

      // print('revocation check : $isUserBadeRevoke');

      await Hive.box(userdata)
          .put(userName, userProfileModel.resData!.userName.toString());
      await Hive.box(userdata)
          .put(userMobile, userProfileModel.resData!.phoneNumber.toString());
      await Hive.box(userdata)
          .put(firstName, userProfileModel.resData!.firstName.toString());
      await Hive.box(userdata)
          .put(lastName, userProfileModel.resData!.lastName.toString());
      await Hive.box(userdata)
          .put(userImage, userProfileModel.resData!.profileImage.toString());
      await Hive.box(userdata)
          .put(userBanner, userProfileModel.resData!.profileBanner.toString());
      if (userProfileModel.resData!.gender != '') {
        await Hive.box(userdata)
            .put(userGender, userProfileModel.resData!.gender.toString());
      }

      if (userProfileModel.resData!.countryFullName != '') {
        await Hive.box(userdata).put(userCountryName,
            userProfileModel.resData!.countryFullName.toString());
      }
      if (userProfileModel.resData != null) {
        badgeUrl = (userProfileModel.resData?.verificationType != null
            ? userProfileModel.resData?.verificationType!.logo
            : '')!;

        print('badge url profile: $badgeUrl');
        verificationTypeId = (userProfileModel.resData?.verificationType != null
            ? userProfileModel.resData?.verificationType!.verificationTypeId!
            : 0)!;

        // Extract active_plan status
        activePlan = userProfileModel.resData?.activePlan ?? false;

        // Check verification status
        checkVerificationStatus();
      }
      if (userProfileModel.resData?.verificationType != null) {
        await Hive.box(userdata).put(userBadge, true);
        await Hive.box(userdata).put(
            userBadge, userProfileModel.resData?.verificationType?.logo ?? '');
      } else {
        await Hive.box(userdata).put(isUserHaveBadge, false);
      }

      setState(() {
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      showCustomToast("Error");
    }
  }

// Helper method to get revocation reason
  String getRevocationReason() {
    if (userProfileModel.resData?.revocations != null &&
        userProfileModel.resData!.revocations!.isNotEmpty) {
      return userProfileModel.resData!.revocations![0].revocationReason ??
          languageController.textTranslate("No reason provided");
    }
    return languageController.textTranslate("No reason provided");
  }

  // New method to check verification status
  void checkVerificationStatus() {
    if (userProfileModel.resData?.varificationRequests != null &&
        userProfileModel.resData!.varificationRequests!.isNotEmpty) {
      // Get the most recent verification request (index 0)
      final latestRequest = userProfileModel.resData!.varificationRequests![0];

      // Check the status from super admin
      verificationStatus = latestRequest.requestStatusSuperAdmin?.toLowerCase();
      rejectReason = latestRequest.rejectReason?.toString();

      // Check if verification has been accepted
      if (verificationStatus == "approved") {
        hasVerificationBeenAccepted = true;
      }

      // Show appropriate message based on status
      if (verificationStatus == "pending") {
        // Show pending status
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showCustomToast("Your verification request is pending");
        });
      } else if (verificationStatus == "rejected") {
        // Show rejected status with reason
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showCustomToast(
              "Your verification request was rejected: ${rejectReason ?? 'No reason provided'}");
        });
      }
    }
  }

  bool isSubscriptionExpired() {
    // Check if there's subscription data available
    if (userProfileModel.resData?.subscribedUsers != null &&
        userProfileModel.resData!.subscribedUsers!.isNotEmpty) {
      // Get the first subscription (most recent one based on your data structure)
      final subscription = userProfileModel.resData!.subscribedUsers![0];

      // // Check if marked as expired
      // if (subscription.isExpired == true) {
      //   return true;
      // }

      // Check if current date is past expire_date
      try {
        final expireDate = DateTime.parse(subscription.expireDate!);
        final now = DateTime.now();
        return now.isAfter(expireDate);
      } catch (e) {
        // In case of parsing error, fallback to is_expired flag
        return subscription.isExpired == true;
      }
    }

    // If there's no subscription data, consider as not expired
    return false;
  }

  Widget _coverImg() {
    String? coverImage;
    if (checkForNull(Hive.box(userdata).get(userBanner)) != null) {
      coverImage = Hive.box(userdata).get(userBanner);
    }

    print('cover image : $coverImage');
    return CoverImageWidget(
      imageUrl: coverImage != null && coverImage.isNotEmpty ? coverImage : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: const Color.fromRGBO(250, 250, 250, 1),
        body: Stack(children: [
          _coverImg(),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: Get.height * 0.18),
                child: Column(
                  children: [
                    profileWidget(),
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ),
              ),
              Expanded(child: SingleChildScrollView(child: aboutWidget())),
            ],
          ),
          Positioned(
              top: 45,
              left: 15,
              child: Text(
                languageController.textTranslate("Settings"),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              )),
        ]));
  }

  String? profileImg;

  Widget profileWidget() {
    profileImg;
    if (checkForNull(Hive.box(userdata).get(userImage)) != null) {
      profileImg = Hive.box(userdata).get(userImage);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: '1',
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(110)),
              child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: profileImg != null &&
                          profileImg !=
                              "https://corexchat.com/uploads/not-found-images/profile-image.png" &&
                          avatarController.avatarIndex.value == -1 &&
                          image == null
                      ? avatarController.avatarsData
                              .where(
                                  (avatar) => avatar.avtarMedia == profileImg)
                              .map((avatar) => avatar.avtarMedia!)
                              .isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: profileImg!,
                              imageBuilder: (context, imageProvider) =>
                                  Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.person, color: chatColor),
                            )
                          : CachedNetworkImage(
                              imageUrl: profileImg!,
                              imageBuilder: (context, imageProvider) =>
                                  Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.person, color: chatColor),
                            )
                      : image == null
                          ? Obx(
                              () => avatarController.avatarIndex.value != -1
                                  ? CachedNetworkImage(
                                      imageUrl: avatarController
                                          .avatarsData[avatarController
                                              .avatarIndex.value]
                                          .avtarMedia!,
                                      imageBuilder: (context, imageProvider) =>
                                          Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: DecorationImage(
                                            image: imageProvider,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.person,
                                              color: chatColor),
                                    )
                                  : Hive.box(userdata).get(userGender) == "male"
                                      ? CachedNetworkImage(
                                          imageUrl: avatarController.avatarsData
                                              .where((avatar) =>
                                                  avatar.avatarGender ==
                                                      "male" &&
                                                  avatar.defaultAvtar == true)
                                              .map((avatar) =>
                                                  avatar.avtarMedia!)
                                              .first,
                                          imageBuilder:
                                              (context, imageProvider) =>
                                                  Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                image: imageProvider,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.person,
                                                  color: chatColor),
                                        )
                                      : Hive.box(userdata).get(userGender) !=
                                                  null &&
                                              Hive.box(userdata)
                                                      .get(userGender) ==
                                                  "female"
                                          ? CachedNetworkImage(
                                              imageUrl: avatarController
                                                  .avatarsData
                                                  .where((avatar) =>
                                                      avatar.avatarGender ==
                                                          "female" &&
                                                      avatar.defaultAvtar ==
                                                          true)
                                                  .map((avatar) =>
                                                      avatar.avtarMedia!)
                                                  .first,
                                              imageBuilder:
                                                  (context, imageProvider) =>
                                                      Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  image: DecorationImage(
                                                    image: imageProvider,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(Icons.person,
                                                          color: chatColor),
                                            )
                                          : Container(
                                              height: 30,
                                              width: 30,
                                              decoration: BoxDecoration(
                                                  color: chatownColor,
                                                  shape: BoxShape.circle),
                                              child: const Icon(
                                                Icons.person,
                                                size: 30,
                                                color: Colors.black,
                                              ),
                                            ),
                            )
                          : Image.file(image!, fit: BoxFit.cover)),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      Text(
                        '${Hive.box(userdata).get(firstName)} ${Hive.box(userdata).get(lastName)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 19),
                      ),
                      if (badgeUrl != '') ...{
                        VerificationLogoWidget(
                          logoUrl: badgeUrl,
                          size: 16,
                          margin: const EdgeInsets.only(left: 2),
                        ),
                      }
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 67,
                    decoration: BoxDecoration(
                        color: Color(0xFFEBEBEB),
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Lottie.asset(
                                'assets/Lottie ANIMATION/call_recieve_animation.json',
                                height: 15,
                                width: 15,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                height: 5,
                                width: 5,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    color: Colors.green),
                              )
                            ],
                          ),
                          const SizedBox(width: 3),
                          Text(
                            languageController.textTranslate('Online'),
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w400),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  print('current user id:${Hive.box(userdata).get(userId)}');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatQRGeneratorScreen(
                        peerId: Hive.box(userdata).get(userId),
                      ),
                    ),
                  );
                },
                child: Image.asset(
                  'assets/icons/barcodeicon.png',
                  height: 50,
                  width: 50,
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget aboutWidget() {
    return Padding(
      padding: const EdgeInsets.only(left: 18, right: 18),
      child: Column(
        children: [
          // containerProfileDesign(
          //     onTap: () {
          //       print('current user id:${Hive.box(userdata).get(userId)}');
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (context) => ChatQRGeneratorScreen(
          //             peerId: Hive.box(userdata).get(userId),
          //           ),
          //         ),
          //       );
          //     },
          //     image: 'assets/images/about.png',
          //     title: languageController.textTranslate('QR'),
          //     about: ''),
          // const SizedBox(height: 10),
          containerProfileDesign(
              onTap: () {
                Get.to(
                  () => ChatQRScannerScreen(),
                  transition: Transition.rightToLeft,
                  curve: Curves.linear,
                );
              },
              image: 'assets/icons/Scan.png',
              title: languageController.textTranslate('Scan QR'),
              about: ''),
          const SizedBox(height: 10),
          containerProfileDesign(
              onTap: () {
                Get.find<AvatarController>().avatarIndex.value = -1;
                Get.to(AddPersonaDetails(isRought: true, isback: true),
                        transition: Transition.rightToLeft)!
                    .then((_) {
                  setState(() {});
                });
              },
              image: 'assets/images/about.png',
              title: languageController.textTranslate('Profile'),
              about: ''),
          const SizedBox(height: 10),
          // Show verification request option based on status
          //   if (verificationStatus != "approved") ...[
          containerProfileDesign(
            onTap: () {
              //  if (isUserBadeRevoke) {
              // print('data tap');
              // // Show dialog with revocation reason
              // showDialog(
              //   context: context,
              //   barrierColor: const Color.fromRGBO(30, 30, 30, 0.37),
              //   builder: (BuildContext context) {
              //     return BackdropFilter(
              //       filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              //       child: AlertDialog(
              //         insetPadding: const EdgeInsets.all(8),
              //         alignment: Alignment.bottomCenter,
              //         backgroundColor: Colors.white,
              //         shape: const RoundedRectangleBorder(
              //           borderRadius: BorderRadius.all(
              //             Radius.circular(20),
              //           ),
              //         ),
              //         content: SizedBox(
              //           width: Get.width,
              //           child: Column(
              //             crossAxisAlignment: CrossAxisAlignment.start,
              //             mainAxisSize: MainAxisSize.min,
              //             children: [
              //               const SizedBox(height: 10),
              //               Text(
              //                 languageController.textTranslate("Badge Revoked"),
              //                 style: const TextStyle(
              //                     fontWeight: FontWeight.w600, fontSize: 16),
              //               ),
              //               const SizedBox(height: 15),
              //               Text(
              //                 getRevocationReason(),
              //                 style: const TextStyle(
              //                     fontWeight: FontWeight.w500,
              //                     color: appgrey2,
              //                     fontSize: 13),
              //               ),
              //               const SizedBox(height: 20),
              //               Row(
              //                 mainAxisAlignment: MainAxisAlignment.center,
              //                 children: [
              //                   InkWell(
              //                     onTap: () {
              //                       Navigator.pop(context);
              //                     },
              //                     child: Container(
              //                       height: 40,
              //                       width: MediaQuery.of(context).size.width *
              //                           0.35,
              //                       decoration: BoxDecoration(
              //                           borderRadius: BorderRadius.circular(12),
              //                           gradient: LinearGradient(
              //                               colors: [
              //                                 secondaryColor,
              //                                 chatownColor
              //                               ],
              //                               begin: Alignment.topCenter,
              //                               end: Alignment.bottomCenter)),
              //                       child: Center(
              //                           child: Text(
              //                         languageController.textTranslate('OK'),
              //                         style: const TextStyle(
              //                             fontSize: 14,
              //                             fontWeight: FontWeight.w400,
              //                             color: appColorWhite),
              //                       )),
              //                     ),
              //                   ),
              //                 ],
              //               ),
              //             ],
              //           ),
              //         ),
              //       ),
              //     );
              //   },
              // );
              // } else {
              //   // Original logic for non-revoked users
              print('v-status: $verificationStatus');
              if (verificationTypeId != 0) {
                //when request is revoked or null
                if (verificationStatus == "rejected") {
                  Get.to(BadgeRequestScreen(),
                          transition: Transition.rightToLeft)!
                      .then((value) {
                    // Refresh data when user returns
                    fetchUserDetailsAPI();
                  });
                } else if (verificationStatus == "pending") {
                  showCustomToast(languageController
                      .textTranslate("Your verification request is pending"));
                } else if (verificationStatus == "approved") {
                  showCustomToast(languageController
                      .textTranslate("Your verification request is approved"));
                } else {
                  // No request yet, go to request screen
                  Get.to(BadgeRequestScreen(),
                          transition: Transition.rightToLeft)!
                      .then((value) {
                    // Refresh data when user returns
                    fetchUserDetailsAPI();
                  });
                }
              } else {
                Get.to(BadgeRequestScreen(),
                        transition: Transition.rightToLeft)!
                    .then((value) {
                  // Refresh data when user returns
                  fetchUserDetailsAPI();
                });
              }

              // }
            },
            image: 'assets/icons/Verified.png',
            disabled: verificationTypeId == 0
                ? false
                : (verificationStatus == "approved" ||
                    verificationStatus == "pending"),

            // disabled: !isUserBadeRevoke
            //     ? (verificationStatus == "approved" ||
            //         verificationStatus == "pending")
            //     : true,
            aboutTextColor: verificationStatus == "approved"
                ? Colors.green
                : verificationStatus == "rejected"
                    ? Colors.red
                    : verificationStatus == "pending"
                        ? Colors
                            .orange // Changed from Colors.grey for better visibility
                        : null,
            title: verificationStatus == "rejected"
                ? languageController.textTranslate('Request Verification Again')
                : languageController.textTranslate('Request Verification'),
            // about: isUserBadeRevoke
            //     ? 'Revoked'
            //     : verificationTypeId == 3
            //         ? '' // Empty about text when verificationTypeId is 3
            //         : (verificationStatus == "approved"
            //             ? languageController.textTranslate('Verified')
            //             : verificationStatus == "pending"
            //                 ? languageController.textTranslate('Pending')
            //                 : verificationStatus == "rejected"
            //                     ? languageController.textTranslate('Rejected')
            //                     : ''),
            about: userProfileModel.resData?.varificationRequests == null ||
                    verificationTypeId == 3
                ? '' // Empty about text when verificationTypeId is 3
                : (verificationStatus == "approved"
                    ? languageController.textTranslate('Verified')
                    : verificationStatus == "pending"
                        ? languageController.textTranslate('Pending request')
                        : verificationStatus == "rejected"
                            ? languageController
                                .textTranslate('Request rejected')
                            : ''),
          ),
          const SizedBox(height: 10),
          //   ],
          containerProfileDesign(
              onTap: () {
                Get.to(() => const about(), transition: Transition.rightToLeft)!
                    .then((value) {
                  print("BACK");
                  setState(() {});
                });
              },
              image: 'assets/images/about.png',
              title: languageController.textTranslate('About'),
              about: Hive.box(userdata).get(userBio) == null
                  ? ""
                  : capitalizeFirstLetter(Hive.box(userdata).get(userBio))),
          const SizedBox(height: 10),
          // Show Orbis Elite Verified if not already accepted
          //  if (!hasVerificationBeenAccepted) ...[
          // containerProfileDesign(
          //   onTap: () {
          //     if (!hasVerificationBeenAccepted ||
          //         verificationTypeId == 3 ||
          //         verificationTypeId == 1) {
          //       Get.to(() => const SubscriptionScreen(),
          //               transition: Transition.rightToLeft)!
          //           .then((value) {
          //         print("BACK");
          //         setState(() {});
          //       });
          //     } else {
          //       Fluttertoast.showToast(
          //         msg: languageController
          //             .textTranslate('You have a badge already.'),
          //       );
          //     }
          //   },
          //   aboutTextColor: hasVerificationBeenAccepted ? Colors.green : null,
          //   about: verificationTypeId == 1
          //       ? ''
          //       : (hasVerificationBeenAccepted ? 'Active' : ''),
          //   image: 'assets/icons/Verified.png',
          //   title: languageController.textTranslate('Orbis Elite Verified'),
          // ),
          containerProfileDesign(
            onTap: () {
              //  if (isUserBadeRevoke) {
              // Show dialog with revocation reason
              // showDialog(
              //   context: context,
              //   barrierColor: const Color.fromRGBO(30, 30, 30, 0.37),
              //   builder: (BuildContext context) {
              //     return BackdropFilter(
              //       filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              //       child: AlertDialog(
              //         insetPadding: const EdgeInsets.all(8),
              //         alignment: Alignment.bottomCenter,
              //         backgroundColor: Colors.white,
              //         shape: const RoundedRectangleBorder(
              //           borderRadius: BorderRadius.all(
              //             Radius.circular(20),
              //           ),
              //         ),
              //         content: SizedBox(
              //           width: Get.width,
              //           child: Column(
              //             crossAxisAlignment: CrossAxisAlignment.start,
              //             mainAxisSize: MainAxisSize.min,
              //             children: [
              //               const SizedBox(height: 10),
              //               Text(
              //                 languageController.textTranslate("Badge Revoked"),
              //                 style: const TextStyle(
              //                     fontWeight: FontWeight.w600, fontSize: 16),
              //               ),
              //               const SizedBox(height: 15),
              //               Text(
              //                 getRevocationReason(),
              //                 style: const TextStyle(
              //                     fontWeight: FontWeight.w500,
              //                     color: appgrey2,
              //                     fontSize: 13),
              //               ),
              //               const SizedBox(height: 20),
              //               Row(
              //                 mainAxisAlignment: MainAxisAlignment.center,
              //                 children: [
              //                   InkWell(
              //                     onTap: () {
              //                       Navigator.pop(context);
              //                     },
              //                     child: Container(
              //                       height: 40,
              //                       width: MediaQuery.of(context).size.width *
              //                           0.35,
              //                       decoration: BoxDecoration(
              //                           borderRadius: BorderRadius.circular(12),
              //                           gradient: LinearGradient(
              //                               colors: [
              //                                 secondaryColor,
              //                                 chatownColor
              //                               ],
              //                               begin: Alignment.topCenter,
              //                               end: Alignment.bottomCenter)),
              //                       child: Center(
              //                           child: Text(
              //                         languageController.textTranslate('OK'),
              //                         style: const TextStyle(
              //                             fontSize: 14,
              //                             fontWeight: FontWeight.w400,
              //                             color: appColorWhite),
              //                       )),
              //                     ),
              //                   ),
              //                 ],
              //               ),
              //             ],
              //           ),
              //         ),
              //       ),
              //     );
              //   },
              // );
              // } else {
              if (verificationTypeId != 0) {
                if (!hasVerificationBeenAccepted ||
                    verificationTypeId == 3 ||
                    verificationTypeId == 1 ||
                    verificationTypeId == 4) {
                  Get.to(() => const SubscriptionScreen(),
                          transition: Transition.rightToLeft)!
                      .then((value) {
                    print("BACK");
                    setState(() {});
                  });
                } else {
                  Fluttertoast.showToast(
                    msg: languageController
                        .textTranslate('You have a badge already.'),
                  );
                }
              } else {
                Get.to(() => const SubscriptionScreen(),
                        transition: Transition.rightToLeft)!
                    .then((value) {
                  print("BACK");
                  setState(() {});
                });
              }
              // }
            },
            // disabled: isUserBadeRevoke,
            aboutTextColor: activePlan
                ? Colors.green
                : (verificationTypeId == 3 && isSubscriptionExpired())
                    ? Colors.red
                    : null,
            // about: isUserBadeRevoke
            //     ? 'Revoked'
            //     : verificationTypeId == 1
            //         ? ''
            //         : (verificationTypeId == 3 && isSubscriptionExpired()
            //             ? 'Expired'
            //             : (hasVerificationBeenAccepted ? 'Active' : '')),
            about: (verificationTypeId == 0)
                ? ''
                : verificationTypeId == 1
                    ? ''
                    : activePlan
                        ? 'Active'
                        : (verificationTypeId == 3 && isSubscriptionExpired()
                            ? 'Expired'
                            : ''),
            image: 'assets/icons/Verified.png',
            title: languageController.textTranslate('Orbis Elite Verified'),
          ),
          const SizedBox(height: 10),
          //  ],

          InkWell(
            onTap: () {
              Get.to(AllStarredMsgList(index: 0),
                      transition: Transition.rightToLeft)!
                  .then((_) {
                allStaredMsgController.allStarred.refresh();
              });
            },
            child: Container(
              height: 48,
              width: Get.width * 90,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset("assets/images/starUnfill.png",
                          color: black1Color, height: 16),
                      const SizedBox(width: 10),
                      Text(
                        languageController.textTranslate('Starred Messages'),
                        style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400),
                      )
                    ],
                  ),
                  Row(
                    children: [
                      Obx(() {
                        return Text(
                          allStaredMsgController.allStarred.isEmpty
                              ? "0"
                              : allStaredMsgController.allStarred.length
                                  .toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                          ),
                        );
                      }),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  )
                ],
              ).paddingSymmetric(horizontal: 10),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              Get.to(const BlockList(), transition: Transition.rightToLeft)!
                  .then((value) {
                Get.find<AllBlockListController>().getBlockListApi();
              });
            },
            child: Container(
              height: 48,
              width: Get.width * 90,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/block1.png',
                        fit: BoxFit.cover,
                        height: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        languageController.textTranslate('Block Contacts'),
                        style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400),
                      )
                    ],
                  ),
                  Row(
                    children: [
                      Obx(() {
                        return Text(
                          allBlockListController.allBlock.isEmpty
                              ? "0"
                              : allBlockListController.allBlock.length
                                  .toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                          ),
                        );
                      }),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  )
                ],
              ).paddingSymmetric(horizontal: 10),
            ),
          ),
          const SizedBox(height: 10),
          containerProfileDesign(
              onTap: () {
                Get.to(SupportTicketScreen(),
                    transition: Transition.rightToLeft);
              },
              image: 'assets/icons/support.png',
              title: languageController.textTranslate('Support Ticket'),
              about: ''),
          const SizedBox(height: 10),
          containerProfileDesign(
            onTap: () {
              chooseLanguage();
            },
            image: 'assets/images/language-square.png',
            title: languageController.textTranslate("App Language"),
            about: '',
          ),
          const SizedBox(height: 10),
          containerProfileDesign(
              onTap: () {
                Share.share(
                  '${languageController.appSettingsData[0].tellAFriendLink}',
                  subject:
                      '${languageController.appSettingsData[0].tellAFriendLink}',
                  // subject: 'Check out this website',
                );
              },
              image: 'assets/images/share2.png',
              title: languageController.textTranslate('Share a link'),
              about: ''),
          const SizedBox(height: 10),

          InkWell(
            onTap: () async {
              showDialog(
                barrierColor: const Color.fromRGBO(30, 30, 30, 0.37),
                context: context,
                builder: (BuildContext context) {
                  return BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: AlertDialog(
                      insetPadding: const EdgeInsets.all(8),
                      alignment: Alignment.bottomCenter,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                      content: SizedBox(
                        width: Get.width,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              languageController.textTranslate(
                                  "Are you sure you want to Logout?"),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              languageController.textTranslate(
                                  "Your session will expire upon logout. Are you absolutely sure?"),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: appgrey2,
                                  fontSize: 13),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    height: 40,
                                    width: MediaQuery.of(context).size.width *
                                        0.35,
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: chatownColor, width: 1),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Center(
                                        child: Text(
                                      languageController
                                          .textTranslate('Cancel'),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: chatColor),
                                    )),
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                InkWell(
                                  onTap: () async {
                                    var box = Hive.box(userdata);
                                    await languageController
                                        .getLanguageTranslation();
                                    await box.delete(userId);
                                    await box.delete(authToken);
                                    await box.delete(firstName);
                                    await box.delete(lastName);
                                    Hive.box(userdata).clear();
                                    Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const Flogin(),
                                        ),
                                        (route) => false);
                                  },
                                  child: Container(
                                    height: 40,
                                    width: MediaQuery.of(context).size.width *
                                        0.35,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: LinearGradient(
                                            colors: [
                                              secondaryColor,
                                              chatownColor
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter)),
                                    child: Center(
                                        child: Text(
                                      languageController
                                          .textTranslate('Logout'),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: chatColor),
                                    )),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            child: Container(
              height: 48,
              width: Get.width * 90,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        "assets/images/logout.png",
                        fit: BoxFit.cover,
                        color: Colors.red,
                        height: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        languageController.textTranslate('Logout'),
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400),
                      )
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16)
                ],
              ).paddingSymmetric(horizontal: 10),
            ),
          ),
          const SizedBox(
            height: 38,
          ),
          CustomButtom(
            title: "Delete Account",
            onPressed: () async {
              showDialog(
                barrierColor: const Color.fromRGBO(30, 30, 30, 0.37),
                context: context,
                builder: (BuildContext context) {
                  return BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: AlertDialog(
                      insetPadding: const EdgeInsets.all(8),
                      alignment: Alignment.bottomCenter,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                      content: SizedBox(
                        width: Get.width,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              languageController.textTranslate(
                                  "Are you sure you want to Delete Account?"),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              languageController.textTranslate(
                                  "Your session will expire upon Delete Account. Are you absolutely sure?"),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: appgrey2,
                                  fontSize: 13),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    height: 40,
                                    width: MediaQuery.of(context).size.width *
                                        0.35,
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: chatownColor, width: 1),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Center(
                                        child: Text(
                                      languageController
                                          .textTranslate('Cancel'),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: chatColor),
                                    )),
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Obx(
                                  () => InkWell(
                                    onTap: () async {
                                      await allBlockListController
                                          .deleteAccount();
                                      if (allBlockListController
                                              .isAccountDeleted.value ==
                                          true) {
                                        var box = Hive.box(userdata);
                                        await languageController
                                            .getLanguageTranslation();

                                        await box.delete(userId);
                                        await box.delete(authToken);
                                        await box.delete(firstName);
                                        await box.delete(lastName);
                                        Hive.box(userdata).clear();

                                        Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const Flogin(),
                                            ),
                                            (route) => false);
                                      }
                                    },
                                    child: Container(
                                      height: 40,
                                      width: MediaQuery.of(context).size.width *
                                          0.35,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          gradient: LinearGradient(
                                              colors: [
                                                secondaryColor,
                                                chatownColor
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter)),
                                      child: Center(
                                          child: allBlockListController
                                                      .isDeletedLoading.value ==
                                                  true
                                              ? const CircularProgressIndicator(
                                                  color: blackcolor,
                                                  strokeWidth: 2,
                                                ).paddingAll(5)
                                              : Text(
                                                  languageController
                                                      .textTranslate('Delete'),
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: chatColor),
                                                )),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ).paddingSymmetric(
            horizontal: 37,
          ),
          const SizedBox(
            height: 30,
          ),
        ],
      ),
    );
  }

  chooseLanguage() {
    return showDialog(
        context: context,
        barrierColor: const Color.fromRGBO(30, 30, 30, 0.37),
        builder: (BuildContext context) {
          return Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: const LanguagePopUp(),
              ),
            ],
          );
        });
  }

  Future deleteAccAsk() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, kk) {
          return AlertDialog(
            backgroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
            ),
            content: SizedBox(
                height: 350,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(300),
                          color: const Color.fromARGB(255, 245, 243, 243),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: Hive.box(userdata).get(userImage),
                          imageBuilder: (context, imageProvider) => Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          placeholder: (context, url) =>
                              Center(child: loader(context)),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.person),
                        )),
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      '${Hive.box(userdata).get(firstName)} ${Hive.box(userdata).get(lastName)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 18),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      languageController.textTranslate(
                          'Are you sure you want to delete your account?'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.grey),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 45,
                        width: 220,
                        decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: Text(
                            languageController.textTranslate('YES'),
                            style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 45,
                        width: 220,
                        decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: Text(
                            languageController.textTranslate('NO'),
                            style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  ],
                )),
          );
        });
      },
    );
  }
}
