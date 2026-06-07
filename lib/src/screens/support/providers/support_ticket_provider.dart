// import 'dart:convert';
// import 'dart:io';
// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
// import 'package:http/http.dart' as http;
// import 'package:corexchat/src/global/api_helper.dart';
// import 'package:corexchat/src/global/strings.dart';
// import 'package:corexchat/src/screens/support/models/support_ticket_model.dart';

// class SupportTicketProvider extends ChangeNotifier {
//   // Ticket list related properties
//   List<SupportTicket> _tickets = [];
//   bool _isLoading = false;
//   bool _hasError = false;
//   String _errorMessage = '';
//   Pagination? _pagination;
//   bool _hasMorePages = false;
//   bool _isCreatingTicket = false;

//   // Chat related properties
//   List<ChatMessage> _chatMessages = [];
//   bool _isLoadingMessages = false;
//   bool _hasChatError = false;
//   String _chatErrorMessage = '';
//   int _currentMessagePage = 1;
//   bool _hasMoreMessages = true;
//   int _currentTicketId = 0;

//   // General getters
//   List<SupportTicket> get tickets => _tickets;
//   bool get isLoading => _isLoading;
//   bool get hasError => _hasError;
//   String get errorMessage => _errorMessage;
//   Pagination? get pagination => _pagination;
//   bool get hasMorePages => _hasMorePages;
//   bool get isCreatingTicket => _isCreatingTicket;

//   // Chat getters
//   List<ChatMessage> get chatMessages => _chatMessages;
//   bool get isLoadingMessages => _isLoadingMessages;
//   bool get hasChatError => _hasChatError;
//   String get chatErrorMessage => _chatErrorMessage;
//   bool get hasMoreMessages => _hasMoreMessages;

//   // Helper method to check if response is HTML
//   bool _isHtmlResponse(String body) {
//     final trimmedBody = body.trim();
//     return trimmedBody.startsWith('<!DOCTYPE') ||
//         trimmedBody.startsWith('<html') ||
//         trimmedBody.startsWith('<?xml');
//   }

//   // Fetch support tickets with pagination
//   Future<void> fetchSupportTickets(
//       {int page = 1, int limit = 10, bool refresh = false}) async {
//     if (refresh) {
//       // Clear existing data if refreshing
//       _tickets = [];
//       _pagination = null;
//       _hasMorePages = false;
//     }

//     if (_isLoading) return; // Prevent multiple simultaneous calls

//     // If we're loading a new page and there are no more pages, return
//     if (page > 1 && !_hasMorePages) return;

//     _isLoading = true;
//     _hasError = false;
//     notifyListeners();

//     try {
//       final response = await http.post(
//         Uri.parse('${ApiHelper.baseUrl}/get-support-tickets'),
//         headers: {
//           'Authorization': 'Bearer ${Hive.box(userdata).get(authToken)}',
//           'Accept': 'application/json',
//           'Content-Type': 'application/x-www-form-urlencoded',
//         },
//         body: {
//           'page': page.toString(),
//           'limit': limit.toString(),
//         },
//       );

//       // Check for HTML response (error page)
//       if (_isHtmlResponse(response.body)) {
//         _hasError = true;
//         _errorMessage =
//             'Server returned an HTML page instead of JSON. The server may be experiencing issues.';
//         print('API Error: Received HTML instead of JSON (tickets)');
//         print(
//             'Response preview: ${response.body.substring(0, min(100, response.body.length))}...');
//         _isLoading = false;
//         notifyListeners();
//         return;
//       }

//       if (response.statusCode == 200) {
//         try {
//           final Map<String, dynamic> responseData = json.decode(response.body);
//           final supportTicketResponse =
//               SupportTicketResponse.fromJson(responseData);

//           if (supportTicketResponse.success == true) {
//             // If refreshing or first page, replace the list
//             // Otherwise, append to the existing list
//             if (refresh || page == 1) {
//               _tickets = supportTicketResponse.data ?? [];
//             } else {
//               _tickets.addAll(supportTicketResponse.data ?? []);
//             }

//             _pagination = supportTicketResponse.pagination;

//             // Check if there are more pages
//             _hasMorePages = (_pagination?.currentPage ?? 0) <
//                 (_pagination?.totalPages ?? 0);
//           } else {
//             _hasError = true;
//             _errorMessage = 'Failed to load tickets';
//           }
//         } catch (e) {
//           _hasError = true;
//           _errorMessage = 'JSON parsing error: ${e.toString()}';
//           print('JSON parsing error: ${e.toString()}');
//           print(
//               'Response was: ${response.body.substring(0, min(100, response.body.length))}...');
//         }
//       } else {
//         _hasError = true;
//         _errorMessage = 'Server error: ${response.statusCode}';
//       }
//     } catch (e) {
//       _hasError = true;
//       _errorMessage = 'Network error: ${e.toString()}';
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // Load more tickets (for pagination)
//   Future<void> loadMore() async {
//     if (!_isLoading && _hasMorePages) {
//       final nextPage = (_pagination?.currentPage ?? 0) + 1;
//       await fetchSupportTickets(page: nextPage, refresh: false);
//     }
//   }

//   // Refresh tickets
//   Future<void> refreshTickets() async {
//     await fetchSupportTickets(refresh: true);
//   }

//   // Create new support ticket
//   Future<bool> createSupportTicket({
//     required String reportTitle,
//     required String reportText,
//     List<File>? files,
//   }) async {
//     _isCreatingTicket = true;
//     _hasError = false;
//     _errorMessage = '';
//     notifyListeners();

//     try {
//       // Create multipart request
//       var uri = Uri.parse('${ApiHelper.baseUrl}/raise-support-ticket');
//       var request = http.MultipartRequest('POST', uri);

//       // Add text fields
//       request.fields['report_title'] = reportTitle;
//       request.fields['report_text'] = reportText;
//       request.headers.addAll({
//         'Authorization': 'Bearer ${Hive.box(userdata).get(authToken)}',
//         'Accept': 'application/json',
//       });

//       // Add files if available
//       if (files != null && files.isNotEmpty) {
//         for (var i = 0; i < files.length; i++) {
//           final file = files[i];
//           final fileName = file.path.split('/').last;
//           final fileField = await http.MultipartFile.fromPath(
//             'files',
//             file.path,
//             filename: fileName,
//           );
//           request.files.add(fileField);
//         }
//       }

//       // Send the request
//       final streamedResponse = await request.send();
//       final response = await http.Response.fromStream(streamedResponse);

//       // Check for HTML response
//       if (_isHtmlResponse(response.body)) {
//         _hasError = true;
//         _errorMessage =
//             'Server returned an HTML page instead of JSON. The server may be experiencing issues.';
//         _isCreatingTicket = false;
//         notifyListeners();
//         return false;
//       }

//       if (response.statusCode == 200) {
//         try {
//           final Map<String, dynamic> responseData = json.decode(response.body);

//           if (responseData['success'] == true) {
//             // Refresh the tickets list to include the new ticket
//             await refreshTickets();
//             _isCreatingTicket = false;
//             notifyListeners();
//             return true;
//           } else {
//             _hasError = true;
//             _errorMessage =
//                 responseData['message'] ?? 'Failed to create ticket';
//             _isCreatingTicket = false;
//             notifyListeners();
//             return false;
//           }
//         } catch (e) {
//           _hasError = true;
//           _errorMessage = 'JSON parsing error: ${e.toString()}';
//           _isCreatingTicket = false;
//           notifyListeners();
//           return false;
//         }
//       } else {
//         _hasError = true;
//         _errorMessage = 'Server error: ${response.statusCode}';
//         _isCreatingTicket = false;
//         notifyListeners();
//         return false;
//       }
//     } catch (e) {
//       _hasError = true;
//       _errorMessage = 'Network error: ${e.toString()}';
//       _isCreatingTicket = false;
//       notifyListeners();
//       return false;
//     }
//   }

//   // ----- CHAT RELATED METHODS -----

//   // Initialize chat for a specific ticket and start real-time updates
//   void initChat(int ticketId) {
//     print('Initializing chat for ticket ID: $ticketId');
//     _currentTicketId = ticketId;
//     _chatMessages = [];
//     _currentMessagePage = 1;
//     _hasMoreMessages = true;

//     // Initial fetch
//     fetchChatMessages(refresh: true);
//   }

//   // Make an API request with the proper error handling
//   Future<Map<String, dynamic>?> _makeMessagesApiRequest(
//       {required int ticketId, required int page, required int limit}) async {
//     try {
//       final response = await http.post(
//         Uri.parse('${ApiHelper.baseUrl}/get-messages'),
//         headers: {
//           'Authorization': 'Bearer ${Hive.box(userdata).get(authToken)}',
//           'Accept': 'application/json',
//         },
//         body: {
//           'ticket_id': ticketId.toString(),
//           'page': page.toString(),
//           'limit': limit.toString(),
//         },
//       );

//       print(
//           'API Response Status: ${response.statusCode}, Page: $page, Ticket: $ticketId');

//       // Check for non-200 status codes
//       if (response.statusCode != 200) {
//         print('API Error: Server returned status code ${response.statusCode}');
//         return null;
//       }

//       // Check for HTML response
//       if (_isHtmlResponse(response.body)) {
//         print('API Error: Received HTML instead of JSON (messages)');
//         print(
//             'Response preview: ${response.body.substring(0, min(100, response.body.length))}...');
//         return null;
//       }

//       // Try to parse the JSON
//       try {
//         final responseData = json.decode(response.body);
//         return responseData;
//       } catch (e) {
//         print('JSON parsing error: ${e.toString()}');
//         print(
//             'Response was: ${response.body.substring(0, min(100, response.body.length))}...');
//         return null;
//       }
//     } catch (e) {
//       print('Network error: ${e.toString()}');
//       return null;
//     }
//   }

//   // Fetch chat messages with pagination
// // ---- SupportTicketProvider.dart ----

// // 1. Updated fetchChatMessages method
//   Future<void> fetchChatMessages({bool refresh = false}) async {
//     if (refresh) {
//       _chatMessages = [];
//       _currentMessagePage = 1;
//       _hasMoreMessages = true;
//     }

//     if (_isLoadingMessages || !_hasMoreMessages || _currentTicketId <= 0)
//       return;

//     _isLoadingMessages = true;
//     _hasChatError = false;
//     notifyListeners();

//     print(
//         'Fetching messages for ticket: $_currentTicketId, page: $_currentMessagePage');

//     final responseData = await _makeMessagesApiRequest(
//         ticketId: _currentTicketId, page: _currentMessagePage, limit: 10);

//     if (responseData == null) {
//       _hasChatError = true;
//       _chatErrorMessage = 'Failed to get response from server';
//       _isLoadingMessages = false;
//       notifyListeners();
//       return;
//     }

//     if (responseData['success'] == true) {
//       final List<dynamic> messageData = responseData['data'] ?? [];
//       final List<ChatMessage> newMessages = [];

//       // Parse messages from JSON
//       for (var data in messageData) {
//         newMessages.add(_parseChatMessage(data));
//       }

//       // Sort messages in reverse chronological order (newest first)
//       newMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

//       // Add new messages to existing ones (for pagination)
//       if (refresh) {
//         _chatMessages = newMessages;
//       } else {
//         _chatMessages.addAll(newMessages);
//       }

//       // Check if there are more messages to load
//       _hasMoreMessages = messageData.length >= 10; // Assuming page size of 10
//       _currentMessagePage++;

//       print(
//           'Loaded ${newMessages.length} messages, hasMoreMessages: $_hasMoreMessages, nextPage: $_currentMessagePage');
//     } else {
//       _hasChatError = true;
//       _chatErrorMessage = responseData['message'] ?? 'Failed to load messages';
//     }

//     _isLoadingMessages = false;
//     notifyListeners();
//   }

//   // Parse a chat message from JSON
//   ChatMessage _parseChatMessage(Map<String, dynamic> data) {
//     try {
//       return ChatMessage(
//         chatId: data['chat_id'] ?? 0,
//         messageType: data['message_type'] ?? 'Text',
//         messageContent: data['message_content'] ?? '',
//         userSeen: data['user_seen'] ?? false,
//         adminSeen: data['admin_seen'] ?? false,
//         senderId: data['sender_id'] ?? 0,
//         createdAt: data['createdAt'] != null
//             ? DateTime.parse(data['createdAt'])
//             : DateTime.now(),
//         updatedAt: data['updatedAt'] != null
//             ? DateTime.parse(data['updatedAt'])
//             : DateTime.now(),
//         adminId: data['admin_id'] ?? 0,
//         ticketId: data['ticket_id'] ?? 0,
//         userId: data['user_id'] ?? 0,
//         admin: Admin(
//           profilePic: data['Admin']?['profile_pic'] ?? '',
//           adminId: data['Admin']?['admin_id'] ?? 0,
//           adminName: data['Admin']?['admin_name'] ?? 'Admin',
//         ),
//         user: User(
//           profileImage: data['User']?['profile_image'] ?? '',
//           userId: data['User']?['user_id'] ?? 0,
//           userName: data['User']?['user_name'] ?? 'User',
//           firstName: data['User']?['first_name'] ?? '',
//           lastName: data['User']?['last_name'] ?? '',
//           lastSeen: data['User']?['last_seen'] ?? 0,
//           blockedByAdmin: data['User']?['Blocked_by_admin'] ?? false,
//           isAccountDeleted: data['User']?['is_account_deleted'] ?? false,
//         ),
//         supportTicket: SupportTicketInfo(
//           ticketId: data['Support_ticket']?['ticket_id'] ?? 0,
//           reportTitle: data['Support_ticket']?['report_title'] ?? '',
//           reportText: data['Support_ticket']?['report_text'] ?? '',
//           reportStatus: data['Support_ticket']?['report_status'] ?? '',
//           adminRemarks: data['Support_ticket']?['admin_remarks'] ?? '',
//           superAdminRemarks:
//               data['Support_ticket']?['super_admin_remarks'] ?? '',
//           createdAt: data['Support_ticket']?['createdAt'] != null
//               ? DateTime.parse(data['Support_ticket']?['createdAt'])
//               : DateTime.now(),
//           updatedAt: data['Support_ticket']?['updatedAt'] != null
//               ? DateTime.parse(data['Support_ticket']?['updatedAt'])
//               : DateTime.now(),
//           adminId: data['Support_ticket']?['admin_id'] ?? 0,
//           userId: data['Support_ticket']?['user_id'] ?? 0,
//           mediaFiles: _extractMediaFiles(data['Support_ticket'] ?? {}),
//         ),
//       );
//     } catch (e) {
//       print('Error parsing chat message: ${e.toString()}');
//       print('Message data: $data');

//       // Return a fallback message in case of parsing error
//       return ChatMessage(
//         chatId: 0,
//         messageType: 'Text',
//         messageContent: 'Error loading message',
//         userSeen: false,
//         adminSeen: false,
//         senderId: 1,
//         createdAt: DateTime.now(),
//         updatedAt: DateTime.now(),
//         adminId: 0,
//         ticketId: _currentTicketId,
//         userId: 0,
//         admin: Admin(
//           profilePic: '',
//           adminId: 0,
//           adminName: 'Admin',
//         ),
//         user: User(
//           profileImage: '',
//           userId: 0,
//           userName: 'User',
//           firstName: '',
//           lastName: '',
//           lastSeen: 0,
//           blockedByAdmin: false,
//           isAccountDeleted: false,
//         ),
//         supportTicket: SupportTicketInfo(
//           ticketId: _currentTicketId,
//           reportTitle: '',
//           reportText: '',
//           reportStatus: '',
//           adminRemarks: '',
//           superAdminRemarks: '',
//           createdAt: DateTime.now(),
//           updatedAt: DateTime.now(),
//           adminId: 0,
//           userId: 0,
//           mediaFiles: [],
//         ),
//       );
//     }
//   }

//   // Extract media files from ticket data
//   List<String> _extractMediaFiles(Map<String, dynamic> ticketData) {
//     List<String> media = [];

//     // Extract media files from report_media_1 to report_media_5
//     for (int i = 1; i <= 5; i++) {
//       String mediaKey = 'report_media_$i';
//       if (ticketData[mediaKey] != null &&
//           ticketData[mediaKey].toString().isNotEmpty) {
//         media.add(ticketData[mediaKey]);
//       }
//     }

//     return media;
//   }

//   // Load more messages (for pagination)
//   Future<void> loadMoreMessages() async {
//     print(
//         'loadMoreMessages called - isLoading: $_isLoadingMessages, hasMore: $_hasMoreMessages');

//     if (_isLoadingMessages || !_hasMoreMessages || _currentTicketId <= 0) {
//       print('Skipping loadMoreMessages - conditions not met');
//       return;
//     }

//     _isLoadingMessages = true;
//     notifyListeners(); // Notify at the beginning to show loading state

//     print('Loading more messages for page: $_currentMessagePage');

//     final responseData = await _makeMessagesApiRequest(
//         ticketId: _currentTicketId, page: _currentMessagePage, limit: 10);

//     if (responseData == null) {
//       _hasChatError = true;
//       _chatErrorMessage = 'Failed to get response from server';
//       _isLoadingMessages = false;
//       notifyListeners();
//       return;
//     }

//     if (responseData['success'] == true) {
//       final List<dynamic> messageData = responseData['data'] ?? [];
//       final List<ChatMessage> newMessages = [];

//       // Parse messages from JSON
//       for (var data in messageData) {
//         newMessages.add(_parseChatMessage(data));
//       }

//       newMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
//       // Add new messages to existing ones (for pagination)
//       _chatMessages.addAll(newMessages);

//       // Check if there are more messages to load
//       _hasMoreMessages = messageData.length >= 10; // Assuming page size of 10
//       _currentMessagePage++;

//       print(
//           'Loaded ${newMessages.length} messages, hasMoreMessages: $_hasMoreMessages, nextPage: $_currentMessagePage');
//     } else {
//       _hasChatError = true;
//       _chatErrorMessage = responseData['message'] ?? 'Failed to load messages';
//     }

//     _isLoadingMessages = false;
//     notifyListeners();
//   }

//   // Refresh messages (manual refresh)
//   Future<void> refreshMessages() async {
//     await fetchChatMessages(refresh: true);
//   }

//   // Send a new message
//   Future<bool> sendChatMessage({
//     required String messageContent,
//     String messageType = 'Text',
//   }) async {
//     if (_currentTicketId <= 0) return false;

//     // First optimistically add the message to UI for better UX
//     final optimisticChatId = DateTime.now().millisecondsSinceEpoch;
//     final optimisticMessage = ChatMessage(
//       chatId: optimisticChatId,
//       messageType: messageType,
//       messageContent: messageContent,
//       userSeen: true,
//       adminSeen: false,
//       senderId: 0, // 0 = user
//       createdAt: DateTime.now(),
//       updatedAt: DateTime.now(),
//       adminId: 0,
//       ticketId: _currentTicketId,
//       userId: 0, // Fill with actual user ID if available
//       admin: Admin(
//         profilePic: '',
//         adminId: 0,
//         adminName: 'Admin',
//       ),
//       user: User(
//         profileImage: '', // Fill with actual user profile if available
//         userId: 0, // Fill with actual user ID if available
//         userName: 'You',
//         firstName: '',
//         lastName: '',
//         lastSeen: 0,
//         blockedByAdmin: false,
//         isAccountDeleted: false,
//       ),
//       supportTicket: SupportTicketInfo(
//         ticketId: _currentTicketId,
//         reportTitle: '',
//         reportText: '',
//         reportStatus: '',
//         adminRemarks: '',
//         superAdminRemarks: '',
//         createdAt: DateTime.now(),
//         updatedAt: DateTime.now(),
//         adminId: 0,
//         userId: 0,
//         mediaFiles: [],
//       ),
//     );

//     // Add to the beginning of the list
//     _chatMessages.insert(0, optimisticMessage);
//     notifyListeners();

//     try {
//       final response = await http.post(
//         Uri.parse('${ApiHelper.baseUrl}/send-message'),
//         headers: {
//           'Authorization': 'Bearer ${Hive.box(userdata).get(authToken)}',
//           'Accept': 'application/json',
//           'Content-Type': 'application/x-www-form-urlencoded',
//         },
//         body: {
//           'ticket_id': _currentTicketId.toString(),
//           'message_type': messageType,
//           'message_content': messageContent,
//         },
//       );

//       // Check for HTML response
//       if (_isHtmlResponse(response.body)) {
//         // Remove the optimistic message since it failed
//         _chatMessages.removeWhere((msg) => msg.chatId == optimisticChatId);
//         _hasChatError = true;
//         _chatErrorMessage =
//             'Server returned HTML instead of JSON. The server may be experiencing issues.';
//         notifyListeners();
//         return false;
//       }

//       if (response.statusCode == 200) {
//         try {
//           final Map<String, dynamic> responseData = json.decode(response.body);

//           if (responseData['success'] == true) {
//             // Success! The message is already shown in the UI
//             return true;
//           } else {
//             // Remove the optimistic message since it failed
//             _chatMessages.removeWhere((msg) => msg.chatId == optimisticChatId);
//             _hasChatError = true;
//             _chatErrorMessage =
//                 responseData['message'] ?? 'Failed to send message';
//             notifyListeners();
//             return false;
//           }
//         } catch (e) {
//           // Remove the optimistic message since it failed
//           _chatMessages.removeWhere((msg) => msg.chatId == optimisticChatId);
//           _hasChatError = true;
//           _chatErrorMessage = 'JSON parsing error: ${e.toString()}';
//           notifyListeners();
//           return false;
//         }
//       } else {
//         // Remove the optimistic message since it failed
//         _chatMessages.removeWhere((msg) => msg.chatId == optimisticChatId);
//         _hasChatError = true;
//         _chatErrorMessage = 'Server error: ${response.statusCode}';
//         notifyListeners();
//         return false;
//       }
//     } catch (e) {
//       // Remove the optimistic message since it failed
//       _chatMessages.removeWhere((msg) => msg.chatId == optimisticChatId);
//       _hasChatError = true;
//       _chatErrorMessage = 'Network error: ${e.toString()}';
//       notifyListeners();
//       return false;
//     }
//   }

//   // Clean up resources when done with chat
//   void disposeChat() {
//     _chatMessages.clear();
//     _currentTicketId = 0;
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:corexchat/src/global/api_helper.dart';
import 'package:corexchat/src/global/strings.dart';
import 'package:corexchat/src/screens/support/models/support_ticket_model.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:corexchat/main.dart';
import 'dart:developer' as dev;

class SupportTicketProvider extends ChangeNotifier {
  // Ticket list related properties
  List<SupportTicket> _tickets = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  Pagination? _pagination;
  bool _hasMorePages = false;
  bool _isCreatingTicket = false;

  // Chat related properties
  List<ChatMessage> _chatMessages = [];
  bool _isLoadingMessages = false;
  bool _hasChatError = false;
  String _chatErrorMessage = '';
  int _currentMessagePage = 1;
  bool _hasMoreMessages = true;
  int _currentTicketId = 0;

  // Socket related
  bool _isSocketListening = false;

  // General getters
  List<SupportTicket> get tickets => _tickets;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  Pagination? get pagination => _pagination;
  bool get hasMorePages => _hasMorePages;
  bool get isCreatingTicket => _isCreatingTicket;

  // Chat getters
  List<ChatMessage> get chatMessages => _chatMessages;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get hasChatError => _hasChatError;
  String get chatErrorMessage => _chatErrorMessage;
  bool get hasMoreMessages => _hasMoreMessages;

  ScrollController? _scrollController;
  final bool _shouldAutoScroll = true;

  // Helper method to check if response is HTML
  bool _isHtmlResponse(String body) {
    final trimmedBody = body.trim();
    return trimmedBody.startsWith('<!DOCTYPE') ||
        trimmedBody.startsWith('<html') ||
        trimmedBody.startsWith('<?xml');
  }

  void _scrollToBottom() {
    if (_scrollController != null && _shouldAutoScroll) {
      // Use a small delay to ensure the UI has updated before scrolling
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController!.hasClients) {
          // Since the ListView is reversed, to scroll to the "bottom" (newest messages)
          // we actually need to scroll to the "top" of the reversed list (position 0)
          _scrollController!.animateTo(
            0.0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  // Fetch support tickets with pagination
  Future<void> fetchSupportTickets(
      {int page = 1, int limit = 10, bool refresh = false}) async {
    if (refresh) {
      // Clear existing data if refreshing
      _tickets = [];
      _pagination = null;
      _hasMorePages = false;
    }

    if (_isLoading) return; // Prevent multiple simultaneous calls

    // If we're loading a new page and there are no more pages, return
    if (page > 1 && !_hasMorePages) return;

    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiHelper.baseUrl}/get-support-tickets'),
        headers: {
          'Authorization': 'Bearer ${Hive.box(userdata).get(authToken)}',
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      // Check for HTML response (error page)
      if (_isHtmlResponse(response.body)) {
        _hasError = true;
        _errorMessage =
            'Server returned an HTML page instead of JSON. The server may be experiencing issues.';
        print('API Error: Received HTML instead of JSON (tickets)');
        print(
            'Response preview: ${response.body.substring(0, min(100, response.body.length))}...');
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final supportTicketResponse =
              SupportTicketResponse.fromJson(responseData);

          if (supportTicketResponse.success == true) {
            // If refreshing or first page, replace the list
            // Otherwise, append to the existing list
            if (refresh || page == 1) {
              _tickets = supportTicketResponse.data ?? [];
            } else {
              _tickets.addAll(supportTicketResponse.data ?? []);
            }

            _pagination = supportTicketResponse.pagination;

            // Check if there are more pages
            _hasMorePages = (_pagination?.currentPage ?? 0) <
                (_pagination?.totalPages ?? 0);
          } else {
            _hasError = true;
            _errorMessage = 'Failed to load tickets';
          }
        } catch (e) {
          _hasError = true;
          _errorMessage = 'JSON parsing error: ${e.toString()}';
          print('JSON parsing error: ${e.toString()}');
          print(
              'Response was: ${response.body.substring(0, min(100, response.body.length))}...');
        }
      } else {
        _hasError = true;
        _errorMessage = 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Network error: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more tickets (for pagination)
  Future<void> loadMore() async {
    if (!_isLoading && _hasMorePages) {
      final nextPage = (_pagination?.currentPage ?? 0) + 1;
      await fetchSupportTickets(page: nextPage, refresh: false);
    }
  }

  // Refresh tickets
  Future<void> refreshTickets() async {
    await fetchSupportTickets(refresh: true);
  }

  // Create new support ticket
  Future<bool> createSupportTicket({
    required String reportTitle,
    required String reportText,
    List<File>? files,
  }) async {
    _isCreatingTicket = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      // Create multipart request
      var uri = Uri.parse('${ApiHelper.baseUrl}/raise-support-ticket');
      var request = http.MultipartRequest('POST', uri);

      // Add text fields
      request.fields['report_title'] = reportTitle;
      request.fields['report_text'] = reportText;
      request.headers.addAll({
        'Authorization': 'Bearer ${Hive.box(userdata).get(authToken)}',
        'Accept': 'application/json',
      });

      // Add files if available
      if (files != null && files.isNotEmpty) {
        for (var i = 0; i < files.length; i++) {
          final file = files[i];
          final fileName = file.path.split('/').last;
          final fileField = await http.MultipartFile.fromPath(
            'files',
            file.path,
            filename: fileName,
          );
          request.files.add(fileField);
        }
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Check for HTML response
      if (_isHtmlResponse(response.body)) {
        _hasError = true;
        _errorMessage =
            'Server returned an HTML page instead of JSON. The server may be experiencing issues.';
        _isCreatingTicket = false;
        notifyListeners();
        return false;
      }

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);

          if (responseData['success'] == true) {
            // Refresh the tickets list to include the new ticket
            await refreshTickets();
            _isCreatingTicket = false;
            notifyListeners();
            return true;
          } else {
            _hasError = true;
            _errorMessage =
                responseData['message'] ?? 'Failed to create ticket';
            _isCreatingTicket = false;
            notifyListeners();
            return false;
          }
        } catch (e) {
          _hasError = true;
          _errorMessage = 'JSON parsing error: ${e.toString()}';
          _isCreatingTicket = false;
          notifyListeners();
          return false;
        }
      } else {
        _hasError = true;
        _errorMessage = 'Server error: ${response.statusCode}';
        _isCreatingTicket = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Network error: ${e.toString()}';
      _isCreatingTicket = false;
      notifyListeners();
      return false;
    }
  }

  // ----- CHAT RELATED METHODS -----

  // Initialize chat for a specific ticket and start socket listeners
  void initChat(int ticketId, {ScrollController? scrollController}) {
    print('Initializing chat for ticket ID: $ticketId');
    _currentTicketId = ticketId;
    _chatMessages = [];
    _currentMessagePage = 1;
    _hasMoreMessages = true;
    _scrollController = scrollController;

    // Initial fetch
    fetchChatMessages(refresh: true);

    // Initialize socket listeners
    _setupSocketListeners();
  }

  // Setup socket listeners for this ticket
  // Setup socket listeners for this ticket
  void _setupSocketListeners() {
    // Prevent duplicate listeners
    if (_isSocketListening) return;

    if (socketIntilized.socket != null && socketIntilized.socket!.connected) {
      dev.log("Setting up socket listeners for ticket: $_currentTicketId");

      // Listen for new messages
      socketIntilized.socket!.on("send_message_support", (data) {
        dev.log("Socket received message: $data");
        if (data != null) {
          _handleIncomingSocketMessage(data);
        }
      });

      _isSocketListening = true;
      dev.log("Socket listeners successfully established");
    } else {
      dev.log("Socket not connected, could not set up listeners");
    }
  }
  // // Handle message read receipt updates
  // void _handleMessageReadReceipt(Map<String, dynamic> data) {
  //   final String messageId = data["message_id"].toString();

  //   // Find the message to update
  //   for (int i = 0; i < _chatMessages.length; i++) {
  //     if (_chatMessages[i].chatId.toString() == messageId) {
  //       _chatMessages[i].adminSeen = true;
  //       notifyListeners();
  //       break;
  //     }
  //   }
  // }

  // Handle incoming socket message
// Handle incoming socket message
  void _handleIncomingSocketMessage(Map<String, dynamic> socketData) {
    dev.log("Processing incoming socket message: $socketData");

    // Check if we have data in the response and if it's for the current ticket
    if (socketData['success'] != true || socketData['data'] == null) {
      dev.log("Invalid socket data format or not successful");
      return;
    }

    Map<String, dynamic> data = socketData['data'];

    // Make sure this message is for the current ticket
    if (data['ticket_id'].toString() != _currentTicketId.toString()) {
      dev.log(
          "Message is for a different ticket: ${data['ticket_id']}, current: $_currentTicketId");
      return;
    }

    try {
      // Determine if this is a user message or admin message
      final int senderId = data['sender_id'] ?? 0;
      // final bool isUserMessage = senderId == 0;

      // Create a chat message from socket data
      final newMessage = ChatMessage(
        chatId: data['chat_id'] ?? DateTime.now().millisecondsSinceEpoch,
        messageType: data['message_type'] ?? 'Text',
        messageContent: data['message_content'] ?? '',
        userSeen: data['user_seen'] ?? false,
        adminSeen: data['admin_seen'] ?? false,
        senderId: senderId,
        createdAt: data['createdAt'] != null
            ? DateTime.parse(data['createdAt'])
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null
            ? DateTime.parse(data['updatedAt'])
            : DateTime.now(),
        adminId: data['admin_id'] ?? 0,
        ticketId: data['ticket_id'] ?? _currentTicketId,
        userId: data['user_id'] ?? 0,
        admin: Admin(
          profilePic: data['Admin']?['profile_pic'] ?? '',
          adminId: data['Admin']?['admin_id'] ?? 0,
          adminName: data['Admin']?['admin_name'] ?? 'Admin',
        ),
        user: User(
          profileImage: data['User']?['profile_image'] ?? '',
          userId: data['User']?['user_id'] ?? 0,
          userName: data['User']?['user_name'] ?? 'User',
          firstName: data['User']?['first_name'] ?? '',
          lastName: data['User']?['last_name'] ?? '',
          lastSeen: data['User']?['last_seen'] ?? 0,
          blockedByAdmin: data['User']?['Blocked_by_admin'] ?? false,
          isAccountDeleted: data['User']?['is_account_deleted'] ?? false,
        ),
        supportTicket: SupportTicketInfo(
          ticketId: data['Support_ticket']?['ticket_id'] ?? _currentTicketId,
          reportTitle: data['Support_ticket']?['report_title'] ?? '',
          reportText: data['Support_ticket']?['report_text'] ?? '',
          reportStatus: data['Support_ticket']?['report_status'] ?? '',
          adminRemarks: data['Support_ticket']?['admin_remarks'] ?? '',
          superAdminRemarks:
              data['Support_ticket']?['super_admin_remarks'] ?? '',
          createdAt: data['Support_ticket']?['createdAt'] != null
              ? DateTime.parse(data['Support_ticket']?['createdAt'])
              : DateTime.now(),
          updatedAt: data['Support_ticket']?['updatedAt'] != null
              ? DateTime.parse(data['Support_ticket']?['updatedAt'])
              : DateTime.now(),
          adminId: data['Support_ticket']?['admin_id'] ?? 0,
          userId: data['Support_ticket']?['user_id'] ?? 0,
          mediaFiles: _extractMediaFiles(data['Support_ticket'] ?? {}),
        ),
      );

      // Check if this message already exists in our chat (to avoid duplicates)
      bool isDuplicate =
          _chatMessages.any((msg) => msg.chatId == newMessage.chatId);

      if (!isDuplicate) {
        // Add to the beginning of the list (since ListView is reversed)
        _chatMessages.insert(0, newMessage);
        dev.log("Added new message to chat: ${newMessage.messageContent}");
        notifyListeners();
        // _scrollToBottom();
        dev.log("Added new message to chat: ${newMessage.messageContent}");
      } else {
        dev.log("Ignoring duplicate message with ID: ${newMessage.chatId}");
      }
    } catch (e) {
      dev.log("Error handling socket message: $e");
    }
  }

  // Make an API request with the proper error handling
  Future<Map<String, dynamic>?> _makeMessagesApiRequest(
      {required int ticketId, required int page, required int limit}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiHelper.baseUrl}/get-messages'),
        headers: {
          'Authorization': 'Bearer ${Hive.box(userdata).get(authToken)}',
          'Accept': 'application/json',
        },
        body: {
          'ticket_id': ticketId.toString(),
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      print(
          'API Response Status: ${response.statusCode}, Page: $page, Ticket: $ticketId');

      // Check for non-200 status codes
      if (response.statusCode != 200) {
        print('API Error: Server returned status code ${response.statusCode}');
        return null;
      }

      // Check for HTML response
      if (_isHtmlResponse(response.body)) {
        print('API Error: Received HTML instead of JSON (messages)');
        print(
            'Response preview: ${response.body.substring(0, min(100, response.body.length))}...');
        return null;
      }

      // Try to parse the JSON
      try {
        final responseData = json.decode(response.body);
        return responseData;
      } catch (e) {
        print('JSON parsing error: ${e.toString()}');
        print(
            'Response was: ${response.body.substring(0, min(100, response.body.length))}...');
        return null;
      }
    } catch (e) {
      print('Network error: ${e.toString()}');
      return null;
    }
  }

  // Fetch chat messages with pagination
  Future<void> fetchChatMessages({bool refresh = false}) async {
    if (refresh) {
      _chatMessages = [];
      _currentMessagePage = 1;
      _hasMoreMessages = true;
    }

    if (_isLoadingMessages || !_hasMoreMessages || _currentTicketId <= 0)
      return;

    _isLoadingMessages = true;
    _hasChatError = false;
    notifyListeners();

    print(
        'Fetching messages for ticket: $_currentTicketId, page: $_currentMessagePage');

    final responseData = await _makeMessagesApiRequest(
        ticketId: _currentTicketId, page: _currentMessagePage, limit: 10);

    if (responseData == null) {
      _hasChatError = true;
      _chatErrorMessage = 'Failed to get response from server';
      _isLoadingMessages = false;
      notifyListeners();
      return;
    }

    if (responseData['success'] == true) {
      final List<dynamic> messageData = responseData['data'] ?? [];
      final List<ChatMessage> newMessages = [];

      // Parse messages from JSON
      for (var data in messageData) {
        newMessages.add(_parseChatMessage(data));
      }

      // Sort messages in reverse chronological order (newest first)
      newMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Add new messages to existing ones (for pagination)
      if (refresh) {
        _chatMessages = newMessages;
      } else {
        _chatMessages.addAll(newMessages);
      }

      // Check if there are more messages to load
      _hasMoreMessages = messageData.length >= 10; // Assuming page size of 10
      _currentMessagePage++;

      print(
          'Loaded ${newMessages.length} messages, hasMoreMessages: $_hasMoreMessages, nextPage: $_currentMessagePage');
    } else {
      _hasChatError = true;
      _chatErrorMessage = responseData['message'] ?? 'Failed to load messages';
    }

    _isLoadingMessages = false;
    notifyListeners();
  }

  // Parse a chat message from JSON
  ChatMessage _parseChatMessage(Map<String, dynamic> data) {
    try {
      return ChatMessage(
        chatId: data['chat_id'] ?? 0,
        messageType: data['message_type'] ?? 'Text',
        messageContent: data['message_content'] ?? '',
        userSeen: data['user_seen'] ?? false,
        adminSeen: data['admin_seen'] ?? false,
        senderId: data['sender_id'] ?? 0,
        createdAt: data['createdAt'] != null
            ? DateTime.parse(data['createdAt'])
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null
            ? DateTime.parse(data['updatedAt'])
            : DateTime.now(),
        adminId: data['admin_id'] ?? 0,
        ticketId: data['ticket_id'] ?? 0,
        userId: data['user_id'] ?? 0,
        admin: Admin(
          profilePic: data['Admin']?['profile_pic'] ?? '',
          adminId: data['Admin']?['admin_id'] ?? 0,
          adminName: data['Admin']?['admin_name'] ?? 'Admin',
        ),
        user: User(
          profileImage: data['User']?['profile_image'] ?? '',
          userId: data['User']?['user_id'] ?? 0,
          userName: data['User']?['user_name'] ?? 'User',
          firstName: data['User']?['first_name'] ?? '',
          lastName: data['User']?['last_name'] ?? '',
          lastSeen: data['User']?['last_seen'] ?? 0,
          blockedByAdmin: data['User']?['Blocked_by_admin'] ?? false,
          isAccountDeleted: data['User']?['is_account_deleted'] ?? false,
        ),
        supportTicket: SupportTicketInfo(
          ticketId: data['Support_ticket']?['ticket_id'] ?? 0,
          reportTitle: data['Support_ticket']?['report_title'] ?? '',
          reportText: data['Support_ticket']?['report_text'] ?? '',
          reportStatus: data['Support_ticket']?['report_status'] ?? '',
          adminRemarks: data['Support_ticket']?['admin_remarks'] ?? '',
          superAdminRemarks:
              data['Support_ticket']?['super_admin_remarks'] ?? '',
          createdAt: data['Support_ticket']?['createdAt'] != null
              ? DateTime.parse(data['Support_ticket']?['createdAt'])
              : DateTime.now(),
          updatedAt: data['Support_ticket']?['updatedAt'] != null
              ? DateTime.parse(data['Support_ticket']?['updatedAt'])
              : DateTime.now(),
          adminId: data['Support_ticket']?['admin_id'] ?? 0,
          userId: data['Support_ticket']?['user_id'] ?? 0,
          mediaFiles: _extractMediaFiles(data['Support_ticket'] ?? {}),
        ),
      );
    } catch (e) {
      print('Error parsing chat message: ${e.toString()}');
      print('Message data: $data');

      // Return a fallback message in case of parsing error
      return ChatMessage(
        chatId: 0,
        messageType: 'Text',
        messageContent: 'Error loading message',
        userSeen: false,
        adminSeen: false,
        senderId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        adminId: 0,
        ticketId: _currentTicketId,
        userId: 0,
        admin: Admin(
          profilePic: '',
          adminId: 0,
          adminName: 'Admin',
        ),
        user: User(
          profileImage: '',
          userId: 0,
          userName: 'User',
          firstName: '',
          lastName: '',
          lastSeen: 0,
          blockedByAdmin: false,
          isAccountDeleted: false,
        ),
        supportTicket: SupportTicketInfo(
          ticketId: _currentTicketId,
          reportTitle: '',
          reportText: '',
          reportStatus: '',
          adminRemarks: '',
          superAdminRemarks: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          adminId: 0,
          userId: 0,
          mediaFiles: [],
        ),
      );
    }
  }

  // Extract media files from ticket data
  List<String> _extractMediaFiles(Map<String, dynamic> ticketData) {
    List<String> media = [];

    // Extract media files from report_media_1 to report_media_5
    for (int i = 1; i <= 5; i++) {
      String mediaKey = 'report_media_$i';
      if (ticketData[mediaKey] != null &&
          ticketData[mediaKey].toString().isNotEmpty) {
        media.add(ticketData[mediaKey]);
      }
    }

    return media;
  }

  // Load more messages (for pagination)
  Future<void> loadMoreMessages() async {
    print(
        'loadMoreMessages called - isLoading: $_isLoadingMessages, hasMore: $_hasMoreMessages');

    if (_isLoadingMessages || !_hasMoreMessages || _currentTicketId <= 0) {
      print('Skipping loadMoreMessages - conditions not met');
      return;
    }

    _isLoadingMessages = true;
    notifyListeners(); // Notify at the beginning to show loading state

    print('Loading more messages for page: $_currentMessagePage');

    final responseData = await _makeMessagesApiRequest(
        ticketId: _currentTicketId, page: _currentMessagePage, limit: 10);

    if (responseData == null) {
      _hasChatError = true;
      _chatErrorMessage = 'Failed to get response from server';
      _isLoadingMessages = false;
      notifyListeners();
      return;
    }

    if (responseData['success'] == true) {
      final List<dynamic> messageData = responseData['data'] ?? [];
      final List<ChatMessage> newMessages = [];

      // Parse messages from JSON
      for (var data in messageData) {
        newMessages.add(_parseChatMessage(data));
      }

      newMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      // Add new messages to existing ones (for pagination)
      _chatMessages.addAll(newMessages);

      // Check if there are more messages to load
      _hasMoreMessages = messageData.length >= 10; // Assuming page size of 10
      _currentMessagePage++;

      print(
          'Loaded ${newMessages.length} messages, hasMoreMessages: $_hasMoreMessages, nextPage: $_currentMessagePage');
    } else {
      _hasChatError = true;
      _chatErrorMessage = responseData['message'] ?? 'Failed to load messages';
    }

    _isLoadingMessages = false;
    notifyListeners();
  }

  // Refresh messages (manual refresh)
  Future<void> refreshMessages() async {
    await fetchChatMessages(refresh: true);
  }

// Send a new message via socket only
  Future<bool> sendChatMessage({
    required String messageContent,
    String messageType = 'Text',
  }) async {
    if (_currentTicketId <= 0) return false;

    // // First optimistically add the message to UI for better UX
    // final optimisticChatId = DateTime.now().millisecondsSinceEpoch;
    // final optimisticMessage = ChatMessage(
    //   chatId: optimisticChatId,
    //   messageType: messageType,
    //   messageContent: messageContent,
    //   userSeen: true,
    //   adminSeen: false,
    //   senderId: 0, // 0 = user
    //   createdAt: DateTime.now(),
    //   updatedAt: DateTime.now(),
    //   adminId: 0,
    //   ticketId: _currentTicketId,
    //   userId: 0, // Fill with actual user ID if available
    //   admin: Admin(
    //     profilePic: '',
    //     adminId: 0,
    //     adminName: 'Admin',
    //   ),
    //   user: User(
    //     profileImage: '', // Fill with actual user profile if available
    //     userId: 0, // Fill with actual user ID if available
    //     userName: 'You',
    //     firstName: '',
    //     lastName: '',
    //     lastSeen: 0,
    //     blockedByAdmin: false,
    //     isAccountDeleted: false,
    //   ),
    //   supportTicket: SupportTicketInfo(
    //     ticketId: _currentTicketId,
    //     reportTitle: '',
    //     reportText: '',
    //     reportStatus: '',
    //     adminRemarks: '',
    //     superAdminRemarks: '',
    //     createdAt: DateTime.now(),
    //     updatedAt: DateTime.now(),
    //     adminId: 0,
    //     userId: 0,
    //     mediaFiles: [],
    //   ),
    // );

    // Add to the beginning of the list
    // _chatMessages.insert(0, optimisticMessage);
    notifyListeners();

    // Send message via socket
    if (socketIntilized.socket != null && socketIntilized.socket!.connected) {
      print("Sending message via socket");
      // Prepare data for socket
      Map<String, dynamic> messageData = {
        'is_user': true,
        'ticket_id': _currentTicketId,
        'message_type': messageType,
        'message_content': messageContent,
      };

      // Emit the message to socket
      socketIntilized.socket!.emit("send_message_support", messageData);
      notifyListeners();
      return true;
    } else {
      print("Socket not available for sending message");
      // Remove the optimistic message since socket is not available
      // _chatMessages.removeWhere((msg) => msg.chatId == optimisticChatId);
      _hasChatError = true;
      _chatErrorMessage =
          'Socket connection not available. Please try again later.';
      notifyListeners();
      return false;
    }
  }

  // Clean up resources when done with chat
  void disposeChat() {
    _chatMessages.clear();
    _currentTicketId = 0;

    // Remove socket listeners
    if (socketIntilized.socket != null) {
      // socketIntilized.socket!.off("update_message_read");
      socketIntilized.socket!.off("send_message_support");
    }

    _isSocketListening = false;
  }

  @override
  void dispose() {
    disposeChat();
    super.dispose();
  }
}

// Chat related models
class ChatMessage {
  final int chatId;
  final String messageType;
  final String messageContent;
  final bool userSeen;
  final bool adminSeen;
  final int senderId; // 0 = user, 1 = admin
  final DateTime createdAt;
  final DateTime updatedAt;
  final int adminId;
  final int ticketId;
  final int userId;
  final Admin admin;
  final User user;
  final SupportTicketInfo supportTicket;

  ChatMessage({
    required this.chatId,
    required this.messageType,
    required this.messageContent,
    required this.userSeen,
    required this.adminSeen,
    required this.senderId,
    required this.createdAt,
    required this.updatedAt,
    required this.adminId,
    required this.ticketId,
    required this.userId,
    required this.admin,
    required this.user,
    required this.supportTicket,
  });
}

class Admin {
  final String profilePic;
  final int adminId;
  final String adminName;

  Admin({
    required this.profilePic,
    required this.adminId,
    required this.adminName,
  });
}

class User {
  final String profileImage;
  final int userId;
  final String userName;
  final String firstName;
  final String lastName;
  final int lastSeen;
  final bool blockedByAdmin;
  final bool isAccountDeleted;

  User({
    required this.profileImage,
    required this.userId,
    required this.userName,
    required this.firstName,
    required this.lastName,
    required this.lastSeen,
    required this.blockedByAdmin,
    required this.isAccountDeleted,
  });
}

class SupportTicketInfo {
  final int ticketId;
  final String reportTitle;
  final String reportText;
  final String reportStatus;
  final String adminRemarks;
  final String superAdminRemarks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int adminId;
  final int userId;
  final List<String> mediaFiles;

  SupportTicketInfo({
    required this.ticketId,
    required this.reportTitle,
    required this.reportText,
    required this.reportStatus,
    required this.adminRemarks,
    required this.superAdminRemarks,
    required this.createdAt,
    required this.updatedAt,
    required this.adminId,
    required this.userId,
    required this.mediaFiles,
  });
}
