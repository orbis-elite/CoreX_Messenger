// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:corexchat/app.dart';
// import 'package:corexchat/src/global/global.dart';
// import 'package:corexchat/src/screens/support/models/support_ticket_model.dart';
// import 'package:corexchat/src/screens/support/providers/support_ticket_provider.dart';

// class SupportTicketChatScreen extends StatefulWidget {
//   final SupportTicket ticket;

//   const SupportTicketChatScreen({
//     Key? key,
//     required this.ticket,
//   }) : super(key: key);

//   @override
//   _SupportTicketChatScreenState createState() =>
//       _SupportTicketChatScreenState();
// }

// class _SupportTicketChatScreenState extends State<SupportTicketChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   bool _isSending = false;
//   late SupportTicketProvider _provider;
//   bool _isLoadingMore = false;

//   @override
//   void initState() {
//     super.initState();
//     // Create a local instance of the provider
//     _provider = SupportTicketProvider();

//     // Initialize the chat with selected ticket
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _provider.initChat(widget.ticket.ticketId ?? 0);

//       // Setup scroll controller for pagination
//       _scrollController.addListener(_scrollListener);
//     });
//   }

//   void _scrollListener() {
//     // For a reversed ListView, we need to check if we're at the TOP
//     // since that's where older messages would be loaded
//     final minScroll = _scrollController.position.minScrollExtent;
//     final currentScroll = _scrollController.position.pixels;
//     final threshold = 200.0; // Trigger 200 pixels before reaching the top

//     // Check if we're approaching the top of the reversed list
//     if (!_isLoadingMore &&
//         _provider.hasMoreMessages &&
//         (currentScroll - minScroll) < threshold) {
//       setState(() {
//         _isLoadingMore = true;
//       });

//       print('Loading more messages from scroll listener');
//       _provider.loadMoreMessages().then((_) {
//         if (mounted) {
//           setState(() {
//             _isLoadingMore = false;
//           });
//         }
//       });
//     }
//   }

//   void _sendMessage() async {
//     if (_messageController.text.trim().isEmpty) return;

//     setState(() {
//       _isSending = true;
//     });

//     // Use the local provider instance
//     final success = await _provider.sendChatMessage(
//       messageContent: _messageController.text.trim(),
//     );

//     if (success) {
//       _messageController.clear();
//     } else {
//       // Show error message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(_provider.chatErrorMessage),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }

//     setState(() {
//       _isSending = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Wrap the entire screen with ChangeNotifierProvider using our local instance
//     return ChangeNotifierProvider.value(
//       value: _provider,
//       child: Scaffold(
//         appBar: AppBar(
//           title: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 widget.ticket.reportTitle ?? 'Support Chat',
//                 style: TextStyle(fontSize: 18),
//                 overflow: TextOverflow.ellipsis,
//               ),
//               Text(
//                 'Ticket #${widget.ticket.ticketId}',
//                 style: TextStyle(fontSize: 12, color: Colors.grey[300]),
//               ),
//             ],
//           ),
//           actions: [
//             IconButton(
//               icon: Icon(Icons.info_outline),
//               onPressed: () {
//                 _showTicketDetailsDialog();
//               },
//             ),
//           ],
//         ),
//         body: Container(
//           decoration: const BoxDecoration(
//             image: DecorationImage(
//               opacity: 0.05,
//               image: AssetImage("assets/images/chat_back_img.png"),
//               fit: BoxFit.cover,
//             ),
//           ),
//           child: Column(
//             children: [
//               _buildStatusBar(),
//               Expanded(
//                 child: Consumer<SupportTicketProvider>(
//                   builder: (context, provider, child) {
//                     if (provider.isLoadingMessages &&
//                         provider.chatMessages.isEmpty) {
//                       return Center(
//                         child: loader(context),
//                       );
//                     }

//                     if (provider.hasChatError &&
//                         provider.chatMessages.isEmpty) {
//                       return Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text('Error: ${provider.chatErrorMessage}'),
//                             SizedBox(height: 16),
//                             ElevatedButton(
//                               onPressed: () => provider.refreshMessages(),
//                               child: Text('Retry'),
//                             ),
//                           ],
//                         ),
//                       );
//                     }

//                     return Stack(
//                       children: [
//                         RefreshIndicator(
//                             onRefresh: () => provider.refreshMessages(),
//                             child: ListView.builder(
//                               controller: _scrollController,
//                               reverse: true,
//                               padding: EdgeInsets.all(10),
//                               itemCount: provider.chatMessages.length +
//                                   (provider.hasMoreMessages
//                                       ? 1
//                                       : 0), // Add 1 for loading indicator if needed
//                               itemBuilder: (context, index) {
//                                 // Show the actual messages first
//                                 if (index < provider.chatMessages.length) {
//                                   final message = provider.chatMessages[index];
//                                   return _buildMessageItem(message);
//                                 }
//                                 // Show loading indicator at the end (which appears at the top when reversed)
//                                 else if (provider.hasMoreMessages &&
//                                     _isLoadingMore) {
//                                   return Padding(
//                                     padding: const EdgeInsets.all(8.0),
//                                     child: loader(context),
//                                   );
//                                 } else {
//                                   return SizedBox.shrink();
//                                 }
//                               },
//                             )),

//                         // Show loading indicator when sending a message
//                         if (_isSending)
//                           Positioned(
//                             right: 16,
//                             bottom: 8,
//                             child: Container(
//                               padding: EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: Colors.black54,
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                               child: Text(
//                                 'Sending...',
//                                 style: TextStyle(color: Colors.white),
//                               ),
//                             ),
//                           ),
//                       ],
//                     );
//                   },
//                 ),
//               ),
//               _buildInputArea(),
//               SizedBox(
//                 height: 20,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusBar() {
//     final status = widget.ticket.reportStatus?.toLowerCase() ?? '';
//     Color statusColor;
//     IconData statusIcon;

//     switch (status) {
//       case 'pending':
//         statusColor = Colors.green;
//         statusIcon = Icons.fiber_new;
//         break;
//       case 'closed':
//         statusColor = Colors.red;
//         statusIcon = Icons.check_circle;
//         break;
//       default:
//         statusColor = Colors.blue;
//         statusIcon = Icons.question_mark;
//     }

//     return Container(
//       padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//       color: statusColor.withOpacity(0.1),
//       child: Row(
//         children: [
//           Icon(statusIcon, size: 16, color: statusColor),
//           SizedBox(width: 8),
//           Text(
//             'Status: ${widget.ticket.reportStatus ?? 'Unknown'}',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: statusColor,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInputArea() {
//     return Consumer<SupportTicketProvider>(
//       builder: (context, provider, child) {
//         // Disable send button if ticket is closed
//         final isClosed = widget.ticket.reportStatus?.toLowerCase() != 'pending';
//         // Removed unused variables

//         return isClosed
//             ? SizedBox.shrink()
//             : Container(
//                 margin: EdgeInsets.all(10),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: Container(
//                         margin:
//                             EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//                         decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(10),
//                             border: Border.all(color: Colors.grey),
//                             color: Colors.white),
//                         child: TextFormField(
//                           maxLines: 4,
//                           minLines: 1,
//                           cursorColor: Colors.black,

//                           textCapitalization: TextCapitalization.sentences,
//                           style: TextStyle(
//                               color: isURL(_messageController.text.trim())
//                                   ? const Color.fromARGB(255, 6, 6, 252)
//                                   : Colors.black),
//                           controller: _messageController,
//                           // enabled: !isClosed,
//                           decoration: InputDecoration(
//                               contentPadding: const EdgeInsets.symmetric(
//                                   horizontal: 12, vertical: 10),
//                               alignLabelWithHint: true,
//                               border: InputBorder.none,
//                               hintText: languageController
//                                   .textTranslate('Type Message'),
//                               hintStyle: TextStyle(
//                                   color: darkGreyColor,
//                                   fontSize: 13,
//                                   fontWeight: FontWeight.w400),
//                               isDense: true),
//                           onEditingComplete: () {},

//                           // onSubmitted: isClosed ? null : (_) => _sendMessage(),
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: 8),
//                     Container(
//                         height: 45,
//                         width: 45,
//                         decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(10),
//                             gradient: LinearGradient(
//                                 colors: [secondaryColor, chatownColor],
//                                 begin: Alignment.topCenter,
//                                 end: Alignment.bottomCenter)),
//                         child: Image.asset("assets/images/send.png",
//                                 color: chatColor)
//                             .paddingAll(12)),

//                     // Container(
//                     //   decoration: BoxDecoration(
//                     //     color: isClosed ? Colors.grey : chatownColor,
//                     //     shape: BoxShape.circle,
//                     //   ),
//                     //   child: IconButton(
//                     //     icon: Icon(Icons.send),
//                     //     color: Colors.white,
//                     //     onPressed: isClosed ? null : _sendMessage,
//                     //   ),
//                     // ),
//                   ],
//                 ),
//               );
//       },
//     );
//   }

//   Widget _buildMessageItem(ChatMessage message) {
//     final bool isUserMessage = message.senderId == 0;
//     final dateFormat = DateFormat('MMM dd, h:mm a');

//     return Container(
//       padding: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
//       child: Column(
//         crossAxisAlignment:
//             isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment:
//                 isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
//             children: [
//               Text(
//                 dateFormat.format(message.createdAt),
//                 style: TextStyle(
//                   fontSize: 10,
//                   color: Colors.grey,
//                 ),
//               ),

//               // Show seen status for user messages
//               if (isUserMessage && message.adminSeen)
//                 Padding(
//                   padding: const EdgeInsets.only(left: 4),
//                   child: Icon(
//                     Icons.done_all,
//                     size: 12,
//                     color: Colors.blue,
//                   ),
//                 ),
//             ],
//           ),
//           SizedBox(height: 2),
//           Row(
//             mainAxisAlignment:
//                 isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               if (!isUserMessage)
//                 _buildAvatar(message.admin.profilePic, Icons.support_agent,
//                     message.admin.adminName),
//               SizedBox(width: isUserMessage ? 0 : 8),
//               Flexible(
//                 child: Container(
//                   margin: EdgeInsets.only(
//                     right: isUserMessage ? 0 : 48,
//                     left: isUserMessage ? 48 : 0,
//                   ),
//                   decoration: BoxDecoration(
//                     color: isUserMessage ? secondaryColor : Colors.grey[200],
//                     borderRadius: isUserMessage == false
//                         ? const BorderRadius.only(
//                             topLeft: Radius.circular(15),
//                             topRight: Radius.circular(15),
//                             bottomRight: Radius.circular(15))
//                         : const BorderRadius.only(
//                             topRight: Radius.circular(15),
//                             topLeft: Radius.circular(15),
//                             bottomLeft: Radius.circular(15)),
//                   ),
//                   padding: EdgeInsets.all(12),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       if (message.messageContent.isNotEmpty)
//                         Text(
//                           message.messageContent,
//                           style: TextStyle(
//                             color: Colors.black87,
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//               SizedBox(width: isUserMessage ? 8 : 0),
//               if (isUserMessage)
//                 _buildAvatar(message.user.profileImage, Icons.person,
//                     message.user.userName),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAvatar(String imageUrl, IconData fallbackIcon, String name) {
//     return Tooltip(
//       message: name,
//       child: CircleAvatar(
//         radius: 16,
//         backgroundColor: Theme.of(context).primaryColor,
//         child: imageUrl.isNotEmpty
//             ? ClipRRect(
//                 borderRadius: BorderRadius.circular(16),
//                 child: CachedNetworkImage(
//                   imageUrl: imageUrl,
//                   placeholder: (context, url) => Container(
//                     color: Colors.grey[300],
//                     child: Icon(fallbackIcon, color: Colors.white, size: 16),
//                   ),
//                   errorWidget: (context, url, error) => Icon(
//                     fallbackIcon,
//                     color: Colors.white,
//                     size: 18,
//                   ),
//                   width: 32,
//                   height: 32,
//                   fit: BoxFit.cover,
//                 ),
//               )
//             : Icon(
//                 fallbackIcon,
//                 color: Colors.white,
//                 size: 18,
//               ),
//       ),
//     );
//   }

//   void _showTicketDetailsDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         elevation: 0,
//         backgroundColor: Colors.transparent,
//         child: Container(
//           padding: EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black26,
//                 blurRadius: 10.0,
//                 offset: Offset(0.0, 10.0),
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header with ticket ID and status badge
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Ticket Details',
//                     style: TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                       color: chatownColor,
//                     ),
//                   ),
//                   _buildStatusBadge(widget.ticket.reportStatus ?? 'Unknown'),
//                 ],
//               ),
//               Divider(height: 25, thickness: 1),

//               // Ticket ID and date in a row
//               Row(
//                 children: [
//                   _buildIconDetailItem(
//                     Icons.confirmation_number_outlined,
//                     'ID: ${widget.ticket.ticketId.toString() ?? ""}',
//                   ),
//                   SizedBox(width: 16),
//                   _buildIconDetailItem(
//                     Icons.calendar_today,
//                     DateFormat('MMM dd, yyyy').format(
//                         DateTime.parse(widget.ticket.createdAt.toString())),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 16),

//               // Title with full width
//               Container(
//                 width: double.infinity,
//                 // padding: EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade50,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Title',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                     SizedBox(height: 4),
//                     Text(
//                       widget.ticket.reportTitle ?? '',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: 16),

//               // Description label
//               Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   'Description',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey.shade600,
//                   ),
//                 ),
//               ),
//               SizedBox(height: 8),

//               // Description with scrolling in a card
//               Container(
//                 height: 120,
//                 width: double.infinity,
//                 padding: EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade50,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.grey.shade200),
//                 ),
//                 child: SingleChildScrollView(
//                   child: Text(
//                     widget.ticket.reportText ?? '',
//                     style: TextStyle(
//                       fontSize: 15,
//                       height: 1.5,
//                     ),
//                   ),
//                 ),
//               ),

//               SizedBox(height: 24),

//               // Action buttons
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   OutlinedButton(
//                     onPressed: () => Navigator.pop(context),
//                     style: OutlinedButton.styleFrom(
//                       side: BorderSide(color: chatownColor),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                       padding:
//                           EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                     ),
//                     child: Text(
//                       'Cancel',
//                       style: TextStyle(color: chatownColor),
//                     ),
//                   ),
//                   SizedBox(width: 12),
//                   ElevatedButton(
//                     onPressed: () {
//                       // Handle primary action (e.g., update or view more details)
//                       Navigator.pop(context);
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: chatownColor,
//                       foregroundColor: Colors.white,
//                       elevation: 0,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                       padding:
//                           EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                     ),
//                     child: Text('Close'),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

// // Helper method to build detail items with icons
//   Widget _buildIconDetailItem(IconData icon, String text) {
//     return Row(
//       children: [
//         Icon(icon, size: 16, color: Colors.grey.shade600),
//         SizedBox(width: 6),
//         Text(
//           text,
//           style: TextStyle(
//             fontSize: 14,
//             color: Colors.grey.shade800,
//           ),
//         ),
//       ],
//     );
//   }

// // Helper to create a status badge
//   Widget _buildStatusBadge(String status) {
//     Color badgeColor;

//     switch (status.toLowerCase()) {
//       case 'pending':
//         badgeColor = Colors.blue;
//         break;

//       case 'closed':
//         badgeColor = Colors.grey;
//         break;
//       default:
//         badgeColor = Colors.purple;
//     }

//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         color: badgeColor.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: badgeColor),
//       ),
//       child: Text(
//         status,
//         style: TextStyle(
//           color: badgeColor,
//           fontWeight: FontWeight.bold,
//           fontSize: 12,
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     // Clean up resources - here we don't need to get provider from context
//     _provider.disposeChat();
//     _messageController.dispose();
//     _scrollController.removeListener(_scrollListener);
//     _scrollController.dispose();
//     super.dispose();
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:corexchat/app.dart';
import 'package:corexchat/src/global/global.dart';
import 'package:corexchat/src/screens/support/models/support_ticket_model.dart';
import 'package:corexchat/src/screens/support/providers/support_ticket_provider.dart';

class SupportTicketChatScreen extends StatefulWidget {
  final SupportTicket ticket;

  const SupportTicketChatScreen({
    Key? key,
    required this.ticket,
  }) : super(key: key);

  @override
  _SupportTicketChatScreenState createState() =>
      _SupportTicketChatScreenState();
}

class _SupportTicketChatScreenState extends State<SupportTicketChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  late SupportTicketProvider _provider;
  bool _isLoadingMore = false;
  bool isThisScreen = true; // Flag to track if this screen is active
  Timer? typingTimer;

  @override
  void initState() {
    super.initState();
    // Create a local instance of the provider
    _provider = SupportTicketProvider();

    // Initialize the chat with selected ticket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.initChat(widget.ticket.ticketId ?? 0,
          scrollController: _scrollController);

      // Setup scroll controller for pagination
      _scrollController.addListener(_scrollListener);
    });
  }

  void _scrollListener() {
    // For a reversed ListView, we need to check if we're at the TOP
    // since that's where older messages would be loaded
    final minScroll = _scrollController.position.minScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = 200.0; // Trigger 200 pixels before reaching the top

    // Check if we're approaching the top of the reversed list
    if (!_isLoadingMore &&
        _provider.hasMoreMessages &&
        (currentScroll - minScroll) < threshold) {
      setState(() {
        _isLoadingMore = true;
      });

      print('Loading more messages from scroll listener');
      _provider.loadMoreMessages().then((_) {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _isSending = true;
    });

    // Use the provider to send message (which now handles socket communication)
    final success = await _provider.sendChatMessage(
      messageContent: _messageController.text.trim(),
    );

    if (success) {
      _messageController.clear();
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_provider.chatErrorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the entire screen with ChangeNotifierProvider using our local instance
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: appColorWhite,
        appBar: AppBar(
          backgroundColor: appColorWhite,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.ticket.reportTitle ?? 'Support Chat',
                style: TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Ticket #${widget.ticket.ticketId}',
                style: TextStyle(fontSize: 12, color: Colors.grey[300]),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () {
                _showTicketDetailsDialog();
              },
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              opacity: 0.05,
              image: AssetImage("assets/images/chat_back_img.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              _buildStatusBar(),
              Expanded(
                child: Consumer<SupportTicketProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoadingMessages &&
                        provider.chatMessages.isEmpty) {
                      return Center(
                        child: loader(context),
                      );
                    }

                    if (provider.hasChatError &&
                        provider.chatMessages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: ${provider.chatErrorMessage}'),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => provider.refreshMessages(),
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    return Stack(
                      children: [
                        RefreshIndicator(
                            onRefresh: () => provider.refreshMessages(),
                            child: ListView.builder(
                              controller: _scrollController,
                              reverse: true,
                              padding: EdgeInsets.all(10),
                              itemCount: provider.chatMessages.length +
                                  (provider.hasMoreMessages
                                      ? 1
                                      : 0), // Add 1 for loading indicator if needed
                              itemBuilder: (context, index) {
                                // Show the actual messages first
                                if (index < provider.chatMessages.length) {
                                  final message = provider.chatMessages[index];
                                  return _buildMessageItem(message);
                                }
                                // Show loading indicator at the end (which appears at the top when reversed)
                                else if (provider.hasMoreMessages &&
                                    _isLoadingMore) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: loader(context),
                                  );
                                } else {
                                  return SizedBox.shrink();
                                }
                              },
                            )),

                        // Show loading indicator when sending a message
                        if (_isSending)
                          Positioned(
                            right: 16,
                            bottom: 8,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Sending...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              _buildInputArea(),
              SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    final status = widget.ticket.reportStatus?.toLowerCase() ?? '';
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        statusColor = Colors.green;
        statusIcon = Icons.fiber_new;
        break;
      case 'closed':
        statusColor = Colors.red;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.question_mark;
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: statusColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          SizedBox(width: 8),
          Text(
            'Status: ${widget.ticket.reportStatus ?? 'Unknown'}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Consumer<SupportTicketProvider>(
      builder: (context, provider, child) {
        // Disable send button if ticket is closed
        final isClosed = widget.ticket.reportStatus?.toLowerCase() != 'pending';

        return isClosed
            ? SizedBox.shrink()
            : Container(
                margin: EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey),
                            color: Colors.white),
                        child: TextFormField(
                          maxLines: 4,
                          minLines: 1,
                          cursorColor: Colors.black,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(
                              color: isURL(_messageController.text.trim())
                                  ? const Color.fromARGB(255, 6, 6, 252)
                                  : Colors.black),
                          controller: _messageController,
                          decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              alignLabelWithHint: true,
                              border: InputBorder.none,
                              hintText: languageController
                                  .textTranslate('Type Message'),
                              hintStyle: TextStyle(
                                  color: darkGreyColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400),
                              isDense: true),
                          onEditingComplete: () {},
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                          height: 45,
                          width: 45,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(
                                  colors: [secondaryColor, chatownColor],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter)),
                          child: Image.asset("assets/images/send.png",
                                  color: chatColor)
                              .paddingAll(12)),
                    ),
                  ],
                ),
              );
      },
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    final bool isUserMessage = message.senderId == 0;
    final dateFormat = DateFormat('MMM dd, h:mm a');

    return Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: Column(
        crossAxisAlignment:
            isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                dateFormat.format(message.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),

              // Show seen status for user messages
              if (isUserMessage && message.adminSeen)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.done_all,
                    size: 12,
                    color: Colors.blue,
                  ),
                ),
            ],
          ),
          SizedBox(height: 2),
          Row(
            mainAxisAlignment:
                isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUserMessage)
                _buildAvatar(message.admin.profilePic, Icons.support_agent,
                    message.admin.adminName),
              SizedBox(width: isUserMessage ? 0 : 8),
              Flexible(
                child: Container(
                  margin: EdgeInsets.only(
                    right: isUserMessage ? 0 : 48,
                    left: isUserMessage ? 48 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: isUserMessage ? secondaryColor : Colors.grey[200],
                    borderRadius: isUserMessage == false
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                            bottomRight: Radius.circular(15))
                        : const BorderRadius.only(
                            topRight: Radius.circular(15),
                            topLeft: Radius.circular(15),
                            bottomLeft: Radius.circular(15)),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.messageContent.isNotEmpty)
                        Text(
                          message.messageContent,
                          style: TextStyle(
                            color:
                                !isUserMessage ? Colors.black87 : Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: isUserMessage ? 8 : 0),
              if (isUserMessage)
                _buildAvatar(message.user.profileImage, Icons.person,
                    message.user.userName),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String imageUrl, IconData fallbackIcon, String name) {
    return Tooltip(
      message: name,
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Theme.of(context).primaryColor,
        child: imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: Icon(fallbackIcon, color: Colors.white, size: 16),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    fallbackIcon,
                    color: Colors.white,
                    size: 18,
                  ),
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              )
            : Icon(
                fallbackIcon,
                color: Colors.white,
                size: 18,
              ),
      ),
    );
  }

  void _showTicketDetailsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with ticket ID and status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ticket Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: chatownColor,
                    ),
                  ),
                  _buildStatusBadge(widget.ticket.reportStatus ?? 'Unknown'),
                ],
              ),
              Divider(height: 25, thickness: 1),

              // Ticket ID and date in a row
              Row(
                children: [
                  _buildIconDetailItem(
                    Icons.confirmation_number_outlined,
                    'ID: ${widget.ticket.ticketId.toString() ?? ""}',
                  ),
                  SizedBox(width: 16),
                  _buildIconDetailItem(
                    Icons.calendar_today,
                    DateFormat('MMM dd, yyyy').format(
                        DateTime.parse(widget.ticket.createdAt.toString())),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Title with full width
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Title',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.ticket.reportTitle ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Description label
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              SizedBox(height: 8),

              // Description with scrolling in a card
              Container(
                height: 120,
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    widget.ticket.reportText ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: chatownColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: chatownColor),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      // Handle primary action (e.g., update or view more details)
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: chatownColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;

    switch (status.toLowerCase()) {
      case 'pending':
        badgeColor = Colors.blue;
        break;

      case 'closed':
        badgeColor = Colors.grey;
        break;
      default:
        badgeColor = Colors.purple;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up resources
    _provider.disposeChat();
    _messageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();

    // Set flag for screen no longer active
    isThisScreen = false;

    // Cancel any timers
    typingTimer?.cancel();

    super.dispose();
  }
}
