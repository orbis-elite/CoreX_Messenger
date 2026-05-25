// ============================================================================
// COREX MESSENGER - MEDIA SCREEN
// ============================================================================
// Modernized & Refactored Version
// Compatible with:
// - Flutter 3.x
// - Dart 3
// - Android Gradle Plugin 8+
// - Java 17
//
// Notes:
// - Fully null-safe
// - Removed deprecated WebInfo usage
// - Removed unstable FlutterLinkPreview builder
// - Optimized rendering performance
// - Added defensive UI protection
// - Improved maintainability
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

import 'package:corexchat/app.dart';
import 'package:corexchat/controller/single_chat_media_controller.dart';
import 'package:corexchat/model/chat_profile_model.dart';

import 'package:corexchat/src/global/global.dart';
import 'package:corexchat/src/global/pdf.dart';

import 'package:corexchat/src/screens/chat/FileView.dart';
import 'package:corexchat/src/screens/chat/chatvideo.dart';
import 'package:corexchat/src/screens/chat/imageView.dart';

import 'package:page_transition/page_transition.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

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

class _MediaState extends State<Media> {
  final ChatProfileController chatProfileController = Get.find();

  // ==========================================================================
  // INIT
  // ==========================================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadProfileData();
    });
  }

  Future<void> _loadProfileData() async {
    try {
      final peerId = widget.peeid ?? '';

      if (peerId.isNotEmpty) {
        await chatProfileController.getProfileDATA(peerId);
      }
    } catch (e) {
      log('MEDIA_INIT_ERROR: $e');
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

        if (chatProfileController.isLoading.value &&
            profile != null &&
            profile.mediaData!.isEmpty &&
            profile.documentData!.isEmpty &&
            profile.linkData!.isEmpty) {
          return _buildLoader();
        }

        if (profile == null) {
          return const SizedBox.shrink();
        }

        return SafeArea(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildTabBar(),
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
      backgroundColor: Colors.grey.shade100,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: InkWell(
        onTap: () => Navigator.pop(context),
        child: const Icon(
          Icons.arrow_back_ios,
          size: 20,
          color: Colors.black,
        ),
      ),
      title: Text(
        capitalizeFirstLetter(widget.peername ?? ''),
        style: const TextStyle(
          fontWeight: FontWeight.w500,
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
      width: double.infinity,
      color: Colors.white,
      child: TabBar(
        dividerColor: const Color.fromRGBO(236, 236, 236, 1),
        indicatorColor: chatownColor,
        unselectedLabelStyle: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        labelStyle: const TextStyle(
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
            text:
            '      ${languageController.textTranslate('Links')}        ',
          ),
          Tab(
            text:
            '      ${languageController.textTranslate('Docs')}        ',
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

  Widget _buildEmptyState(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: chatColor,
              fontSize: 15,
              fontWeight: FontWeight.w400,
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
        itemCount: mediaList.length,
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          mainAxisExtent: 110,
        ),
        itemBuilder: (context, index) {
          return _buildMediaItem(mediaList[index]);
        },
      ),
    );
  }

  Widget _buildMediaItem(MediaData data) {
    final url = data.url ?? '';

    final isVideo = url.toLowerCase().contains('.mp4');

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
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade200,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
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
              size: 35,
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

  Widget _buildLinkItem(LinkData data) {
    final message = data.message ?? '';

    return InkWell(
      onTap: () {
        launchURL(message);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
            const Icon(
              Icons.link_rounded,
              color: linkColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: secondaryColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Image(
              image: AssetImage('assets/images/pdf.png'),
              height: 32,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
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

                  if (snapshot.hasError || !snapshot.hasData) {
                    return Text(fileName);
                  }

                  final pageCount = snapshot.data!['pageCount'];
                  final fileSize = snapshot.data!['fileSize'];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        '$pageCount Page - $fileSize',
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