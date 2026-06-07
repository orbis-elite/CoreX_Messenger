// =============================================================================
// CoreX Messenger
// =============================================================================
//
// Media Screen
//
// =============================================================================
//
// Stable Legacy-Compatible Media Screen
//
// Optimized For:
//
// ✔ Flutter 3.19.x - 3.24.x
// ✔ Legacy CoreX Messenger Source
// ✔ Firebase Compatible
// ✔ WebRTC Compatible
// ✔ Codemagic Compatible
// ✔ Android
// ✔ iOS
// ✔ Media Preview
// ✔ Video Preview
// ✔ Link Preview
// ✔ PDF Viewer
//
// =============================================================================
//
// IMPORTANT NOTES
//
// This file intentionally keeps:
// - lecle_flutter_link_preview
// - qr_code_scanner
// - legacy media APIs
//
// because the original CoreX Messenger source code depends on them.
//
// =============================================================================

// ignore_for_file:
// deprecated_member_use,
// must_be_immutable,
// file_names,
// avoid_print,
// non_constant_identifier_names

// =============================================================================
// DART IMPORTS
// =============================================================================

import 'dart:developer';
import 'dart:typed_data';

// =============================================================================
// FLUTTER IMPORTS
// =============================================================================

import 'package:flutter/material.dart';

// =============================================================================
// PACKAGES
// =============================================================================

import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:lecle_flutter_link_preview/lecle_flutter_link_preview.dart';
import 'package:page_transition/page_transition.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

// =============================================================================
// COREX IMPORTS
// =============================================================================

import 'package:corexchat/app.dart';

import 'package:corexchat/controller/single_chat_media_controller.dart';

import 'package:corexchat/model/chat_profile_model.dart';

import 'package:corexchat/src/global/global.dart';
import 'package:corexchat/src/global/pdf.dart';

import 'package:corexchat/src/screens/chat/FileView.dart';
import 'package:corexchat/src/screens/chat/chatvideo.dart';
import 'package:corexchat/src/screens/chat/imageView.dart';

// =============================================================================
// MEDIA SCREEN
// =============================================================================

class Media extends StatefulWidget {
  // ---------------------------------------------------------------------------
  // VARIABLES
  // ---------------------------------------------------------------------------

  String? peeid;

  String? peername;

  // ---------------------------------------------------------------------------
  // CONSTRUCTOR
  // ---------------------------------------------------------------------------

  Media({
    super.key,
    this.peeid,
    this.peername,
  });

  @override
  State<Media> createState() => _MediaState();
}

// =============================================================================
// MEDIA STATE
// =============================================================================

class _MediaState extends State<Media> {
  // ---------------------------------------------------------------------------
  // CONTROLLER
  // ---------------------------------------------------------------------------

  final ChatProfileController chatProfileController = Get.find();

  // =============================================================================
  // INIT STATE
  // =============================================================================

  @override
  void initState() {
    super.initState();

    initializeProfile();
  }

  // =============================================================================
  // INITIALIZE PROFILE
  // =============================================================================

  Future<void> initializeProfile() async {
    if (widget.peeid != null && widget.peeid!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) async {
          await chatProfileController.getProfileDATA(
            widget.peeid!,
          );
        },
      );
    }
  }

  // =============================================================================
  // BUILD UI
  // =============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // -----------------------------------------------------------------------
      // BACKGROUND
      // -----------------------------------------------------------------------

      backgroundColor: Colors.grey.shade100,

      // -----------------------------------------------------------------------
      // APP BAR
      // -----------------------------------------------------------------------

      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 50,
        titleSpacing: 0,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: Colors.black,
          ),
        ),
        title: Text(
          capitalizeFirstLetter(
            widget.peername.toString(),
          ),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 18,
            color: chatColor,
          ),
        ),
      ),

      // -----------------------------------------------------------------------
      // BODY
      // -----------------------------------------------------------------------

      body: Obx(
        () {
          return SafeArea(
            child: Container(
              color: Colors.transparent,
              height: MediaQuery.of(context).size.height,
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: <Widget>[
                    // ---------------------------------------------------------
                    // TOP SPACING
                    // ---------------------------------------------------------

                    const SizedBox(height: 10),

                    // ---------------------------------------------------------
                    // TAB BAR
                    // ---------------------------------------------------------

                    buildTabBar(),

                    // ---------------------------------------------------------
                    // LOADING
                    // ---------------------------------------------------------

                    buildBodyContent(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // =============================================================================
  // TAB BAR
  // =============================================================================

  Widget buildTabBar() {
    return Container(
      width: double.maxFinite,
      color: Colors.white,
      child: Center(
        child: TabBar(
          dividerColor: const Color.fromRGBO(
            236,
            236,
            236,
            1,
          ),
          indicatorColor: chatownColor,
          unselectedLabelStyle: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          labelStyle: TextStyle(
            color: chatownColor,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          tabs: [
            Tab(
              text:
                  '      ${languageController.textTranslate('Media')}        ',
            ),
            Tab(
              text: '      ${languageController.textTranslate('Links')}       ',
            ),
            Tab(
              text: '      ${languageController.textTranslate('Docs')}        ',
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // BODY CONTENT
  // =============================================================================

  Widget buildBodyContent() {
    final profile = chatProfileController.profileModel.value;

    // -------------------------------------------------------------------------
    // LOADING
    // -------------------------------------------------------------------------

    if (chatProfileController.isLoading.value &&
        profile != null &&
        profile.mediaData!.isEmpty &&
        profile.documentData!.isEmpty &&
        profile.linkData!.isEmpty) {
      return Center(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.4,
            ),
            loader(context),
          ],
        ),
      );
    }

    // -------------------------------------------------------------------------
    // EMPTY
    // -------------------------------------------------------------------------

    if (profile == null) {
      return const SizedBox();
    }

    // -------------------------------------------------------------------------
    // TAB VIEW
    // -------------------------------------------------------------------------

    return Expanded(
      child: TabBarView(
        children: [
          buildMediaTab(),
          buildLinksTab(),
          buildDocsTab(),
        ],
      ),
    );
  }

  // =============================================================================
  // MEDIA TAB
  // =============================================================================

  Widget buildMediaTab() {
    final mediaData = chatProfileController.profileModel.value!.mediaData!;

    if (mediaData.isEmpty) {
      return buildEmptyWidget(
        "You haven't share any media",
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        width: MediaQuery.of(context).size.width,
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        child: GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisExtent: 110,
            mainAxisSpacing: 10,
          ),
          itemCount: mediaData.length,
          itemBuilder: (context, index) {
            return mediaWidget(
              mediaData[index],
              index,
            );
          },
        ),
      ),
    );
  }

  // =============================================================================
  // LINKS TAB
  // =============================================================================

  Widget buildLinksTab() {
    final links = chatProfileController.profileModel.value!.linkData!;

    if (links.isEmpty) {
      return buildEmptyWidget(
        "You haven't share any link with",
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: links.length,
        itemBuilder: (context, index) {
          return linkWidget(
            links[index],
            index,
          );
        },
      ),
    );
  }

  // =============================================================================
  // DOCS TAB
  // =============================================================================

  Widget buildDocsTab() {
    final docs = chatProfileController.profileModel.value!.documentData!;

    if (docs.isEmpty) {
      return buildEmptyWidget(
        "You haven't share any doc with",
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: docs.length,
        itemBuilder: (context, index) {
          return docsWidget(
            docs[index],
            index,
          );
        },
      ),
    );
  }

  // =============================================================================
  // EMPTY WIDGET
  // =============================================================================

  Widget buildEmptyWidget(String text) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Container(
              width: MediaQuery.sizeOf(context).width * 0.90,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Text(
                  '$text ${widget.peername}',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: chatColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // MEDIA WIDGET
  // =============================================================================

  Widget mediaWidget(
    MediaData data,
    int index,
  ) {
    final isVideo = data.url.toString().contains(".mp4");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: () {
          if (isVideo) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoViewFix(
                  username: "",
                  url: data.url!,
                  play: true,
                  mute: false,
                  date: "",
                ),
              ),
            );
          } else {
            log(data.url!);

            Navigator.push(
              context,
              PageTransition(
                curve: Curves.linear,
                type: PageTransitionType.rightToLeft,
                child: ImageView(
                  image: data.url!,
                  userimg: "",
                ),
              ),
            );
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 100,
              width: 100,
              color: Colors.grey.shade200,
              child: ClipRRect(
                child: CachedNetworkImage(
                  imageUrl: isVideo ? data.thumbnail! : data.url!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (isVideo)
              Positioned(
                top: 42,
                child: Image.asset(
                  "assets/images/play1.png",
                  height: 22,
                  color: chatColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // LINK WIDGET
  // =============================================================================

  Widget linkWidget(
    LinkData data,
    int index,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 3,
      ),
      child: InkWell(
        onTap: () {
          launchURL(data.message!);
        },
        child: Container(
          decoration: BoxDecoration(
            color: secondaryColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              width: 1,
              color: const Color(0xffE8E8E8),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: FlutterLinkPreview(
              url: data.message!,
              builder: (info) {
                if (info is WebInfo) {
                  return Text(
                    data.message!,
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                  );
                }

                return const CircularProgressIndicator();
              },
            ),
          ),
        ),
      ),
    );
  }

  // =============================================================================
  // DOCS WIDGET
  // =============================================================================

  Widget docsWidget(
    DocumentData data,
    int index,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          PageTransition(
            curve: Curves.linear,
            type: PageTransitionType.rightToLeft,
            child: FileView(
              file: data.url!,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 3,
        ),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: secondaryColor,
          ),
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                const Image(
                  height: 28,
                  image: AssetImage(
                    'assets/images/pdf.png',
                  ),
                ),
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: getPdfInfo(data.url!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return buildPdfLoading(
                          data,
                        );
                      }

                      if (snapshot.hasData) {
                        return buildPdfData(
                          data,
                          snapshot.data!,
                        );
                      }

                      return const SizedBox();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =============================================================================
  // PDF LOADING
  // =============================================================================

  Widget buildPdfLoading(
    DocumentData data,
  ) {
    // -------------------------------------------------------------------------
    // SAFE FILE NAME
    // -------------------------------------------------------------------------

    final String safeFileName =
        extractFilename(data.url ?? '') ?? 'Unknown File';

    final List<String> fileParts = safeFileName.split("-");

    final String finalFileName =
        fileParts.isNotEmpty ? fileParts.last : safeFileName;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          finalFileName,
          style: const TextStyle(
            color: chatColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          languageController.textTranslate(
            '0 Page - 0 KB',
          ),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    ).paddingOnly(left: 12);
  }

  // =============================================================================
  // PDF DATA
  // =============================================================================

  Widget buildPdfData(
    DocumentData data,
    Map<String, dynamic> pdfData,
  ) {
    // -------------------------------------------------------------------------
    // PDF INFO
    // -------------------------------------------------------------------------

    final int pageCount = pdfData['pageCount'] ?? 0;

    final String fileSize = pdfData['fileSize'] ?? '0 KB';

    // -------------------------------------------------------------------------
    // SAFE FILE NAME
    // -------------------------------------------------------------------------

    final String safeFileName =
        extractFilename(data.url ?? '') ?? 'Unknown File';

    final List<String> fileParts = safeFileName.split("-");

    final String finalFileName =
        fileParts.isNotEmpty ? fileParts.last : safeFileName;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          finalFileName,
          style: const TextStyle(
            color: chatColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '$pageCount Page - $fileSize',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    ).paddingOnly(left: 12);
  }

  // =============================================================================
  // URL WIDGET
  // =============================================================================

  Widget getUrlWidget(String url) {
    if (url.endsWith('.mp4')) {
      return FutureBuilder<Uint8List?>(
        future: getThumbnail(url),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.fill,
            );
          }

          return Container();
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.fill,
    );
  }

  // =============================================================================
  // GET VIDEO THUMBNAIL
  // =============================================================================

  Future<Uint8List?> getThumbnail(
    String videoUrl,
  ) async {
    return await VideoThumbnail.thumbnailData(
      video: videoUrl,
      imageFormat: ImageFormat.JPEG,
      quality: 100,
      maxHeight: 100,
      maxWidth: 100,
    );
  }
}

// =============================================================================
// END OF FILE
// =============================================================================
