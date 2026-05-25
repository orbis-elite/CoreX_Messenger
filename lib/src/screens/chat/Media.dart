// ============================================================================
// COREX MESSENGER - MEDIA SCREEN
// ============================================================================
// Professional Refactored Version
// Optimized for:
// - Flutter 3.x
// - Dart 3
// - Android Gradle Plugin 8+
// - Java 17
//
// Features:
// - Full null safety
// - Stable rendering
// - Production ready
// - Cleaner architecture
// - Optimized performance
// - Defensive programming
// - Better maintainability
// - Modern Flutter standards
//
// IMPORTANT:
// This file intentionally removes deprecated FlutterLinkPreview
// and unstable WebInfo implementation to prevent build failures.
//
// ============================================================================

// ignore_for_file: deprecated_member_use
// ignore_for_file: must_be_immutable
// ignore_for_file: file_names
// ignore_for_file: avoid_print
// ignore_for_file: non_constant_identifier_names

import 'dart:developer';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:page_transition/page_transition.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'package:corexchat/app.dart';

import 'package:corexchat/controller/single_chat_media_controller.dart';

import 'package:corexchat/model/chat_profile_model.dart';

import 'package:corexchat/src/global/global.dart';
import 'package:corexchat/src/global/pdf.dart';

import 'package:corexchat/src/screens/chat/FileView.dart';
import 'package:corexchat/src/screens/chat/chatvideo.dart';
import 'package:corexchat/src/screens/chat/imageView.dart';

// ============================================================================
// MAIN MEDIA SCREEN
// ============================================================================

class Media extends StatefulWidget {
  final String? peeid;
  final String? peername;

  const Media({
    super.key,
    this.peeid,
    this.peername,
  });

  @override
  State<Media> createState() => _MediaState();
}

// ============================================================================
// MEDIA STATE
// ============================================================================

class _MediaState extends State<Media> {
  final ChatProfileController chatProfileController = Get.find();

  // ==========================================================================
  // INITIALIZATION
  // ==========================================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadProfileData();
    });
  }

  // ==========================================================================
  // LOAD PROFILE DATA
  // ==========================================================================

  Future<void> _loadProfileData() async {
    try {
      final peerId = widget.peeid ?? '';

      if (peerId.isNotEmpty) {
        await chatProfileController.getProfileDATA(peerId);
      }
    } catch (e) {
      log('MEDIA_SCREEN_ERROR: $e');
    }
  }

  // ==========================================================================
  // MAIN BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _buildAppBar(),
      body: Obx(() {
        final profile = chatProfileController.profileModel.value;

        if (profile == null) {
          return _buildLoader();
        }

        return SafeArea(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const SizedBox(height: 10),

                // ============================================================
                // TAB BAR
                // ============================================================

                _buildTabBar(),

                // ============================================================
                // CONTENT
                // ============================================================

                Expanded(
                  child: TabBarView(
                    children: [
                      _buildMediaTab(profile.mediaData ?? []),
                      _buildLinksTab(profile.linkData ?? []),
                      _buildDocsTab(profile.documentData ?? []),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ==========================================================================
  // APP BAR
  // ==========================================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.grey.shade100,
      automaticallyImplyLeading: false,
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
        capitalizeFirstLetter(widget.peername ?? ''),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: chatColor,
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB BAR
  // ==========================================================================

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        indicatorColor: chatownColor,
        dividerColor: const Color.fromRGBO(236, 236, 236, 1),

        labelStyle: TextStyle(
          color: chatownColor,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),

        unselectedLabelStyle: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),

        tabs: [
          Tab(
            text:
            "      ${languageController.textTranslate('Media')}      ",
          ),
          Tab(
            text:
            "      ${languageController.textTranslate('Links')}      ",
          ),
          Tab(
            text:
            "      ${languageController.textTranslate('Docs')}      ",
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // LOADER
  // ==========================================================================

  Widget _buildLoader() {
    return Center(
      child: loader(context),
    );
  }

  // ==========================================================================
  // EMPTY STATE
  // ==========================================================================

  Widget _buildEmptyState(String title) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: chatColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // MEDIA TAB
  // ==========================================================================

  Widget _buildMediaTab(List<MediaData> mediaList) {
    if (mediaList.isEmpty) {
      return _buildEmptyState(
        "${languageController.textTranslate("You haven't share any media")} ${widget.peername}",
      );
    }

    return Padding(
      padding: const EdgeInsets.all(15),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: mediaList.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 110,
        ),
        itemBuilder: (context, index) {
          return _buildMediaItem(mediaList[index]);
        },
      ),
    );
  }

  // ==========================================================================
  // MEDIA ITEM
  // ==========================================================================

  Widget _buildMediaItem(MediaData data) {
    final url = data.url ?? '';

    final isVideo =
        url.toLowerCase().contains('.mp4') ||
            url.toLowerCase().contains('.mov');

    return InkWell(
      onTap: () {
        if (isVideo) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoViewFix(
                username: '',
                url: url,
                play: true,
                mute: false,
                date: '',
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.rightToLeft,
              child: ImageView(
                image: url,
                userimg: '',
              ),
            ),
          );
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 110,
            width: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.grey.shade200,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: isVideo
                    ? (data.thumbnail ?? '')
                    : url,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) {
                  return const Icon(Icons.broken_image);
                },
              ),
            ),
          ),

          if (isVideo)
            const Icon(
              Icons.play_circle_fill_rounded,
              size: 38,
              color: Colors.white,
            ),
        ],
      ),
    );
  }

  // ==========================================================================
  // LINKS TAB
  // ==========================================================================

  Widget _buildLinksTab(List<LinkData> links) {
    if (links.isEmpty) {
      return _buildEmptyState(
        "${languageController.textTranslate("You haven't share any link with")} ${widget.peername}",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: links.length,
      itemBuilder: (context, index) {
        return _buildLinkItem(links[index]);
      },
    );
  }

  // ==========================================================================
  // LINK ITEM
  // ==========================================================================

  Widget _buildLinkItem(LinkData data) {
    final message = data.message ?? '';

    return InkWell(
      onTap: () {
        launchURL(message);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: secondaryColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xffE8E8E8),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.link_rounded,
              color: linkColor,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: linkColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // DOCS TAB
  // ==========================================================================

  Widget _buildDocsTab(List<DocumentData> docs) {
    if (docs.isEmpty) {
      return _buildEmptyState(
        "${languageController.textTranslate("You haven't share any doc with")} ${widget.peername}",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        return _buildDocItem(docs[index]);
      },
    );
  }

  // ==========================================================================
  // DOC ITEM
  // ==========================================================================

  Widget _buildDocItem(DocumentData data) {
    final url = data.url ?? '';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeft,
            child: FileView(file: url),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: secondaryColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Image(
              image: AssetImage('assets/images/pdf.png'),
              height: 34,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: getPdfInfo(url),
                builder: (context, snapshot) {
                  final fileName = extractFilename(url)
                      .toString()
                      .split("-")
                      .last;

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          'Loading...',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    );
                  }

                  if (!snapshot.hasData) {
                    return Text(fileName);
                  }

                  final pageCount =
                  snapshot.data!['pageCount'];

                  final fileSize =
                  snapshot.data!['fileSize'];

                  return Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '$pageCount Page • $fileSize',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // VIDEO THUMBNAIL
  // ==========================================================================

  Future<Uint8List?> getThumbnail(String videoUrl) async {
    try {
      return await VideoThumbnail.thumbnailData(
        video: videoUrl,
        imageFormat: ImageFormat.JPEG,
        quality: 100,
        maxHeight: 100,
        maxWidth: 100,
      );
    } catch (e) {
      log('THUMBNAIL_ERROR: $e');
      return null;
    }
  }
}