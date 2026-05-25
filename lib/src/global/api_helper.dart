import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class ApiHelper {
  // //live demo
  // static const String baseUrl = 'https://control.corexmessenger.com/api';
  // static const String baseUrlIp = '18.138.138.163';
  // static const int basePort = 3008; // socket port

  //live
  static const String baseUrl = 'https://control.corexmessenger.com/api';
  static const String baseUrlIp = 'control.corexmessenger.com';
  static const int basePort = 3008; // socket port
  static const String callBasepeerUrl = '18.138.138.163'; //video call

  //whoxa live
  // static const String baseUrl = 'https://whoxachat.com/api';
  // static const String whoxabaseUrlIp = '62.72.36.245';
  // static const int basePort = 3000;

  // //local
  // static const String baseUrl = 'http://192.168.0.69:3008/api';
  // static const String baseUrlIp = '192.168.0.69';
  // static const int basePort = 3008; // socket port
  // static const String callBasepeerUrl = '18.138.138.163'; //video call

  // static const String basepeerUrl = '18.138.138.163'; //video call
  static const int peerPort = 4001; //video call

  /// API Paths
  String registerPhone = "$baseUrl/register-phone";
  String verifyOtpPhone = "$baseUrl/verify-phone-otp";

  final String registerEmail = "${baseUrl}/register-email";
  final String verifyOtpEmail = "${baseUrl}/verify-email-otp";

  String userCreateProfile = "$baseUrl/user-details";
  String userNameCheck = "$baseUrl/check-user-name";
  String getAllContact = "$baseUrl/get-all-available-contacts";
  String addContact = "$baseUrl/add-contact-name";
  String sendChatMsg = "$baseUrl/send-message";
  String deleteChatMsg = "$baseUrl/delete-messages";
  String getOnetoOneMedia = "$baseUrl/get-one-to-one-media";
  String createGroupAdmin = "$baseUrl/create-group-admin";
  String removeGroupAdmin = "$baseUrl/remove-member-from-group";
  String createGroup = "$baseUrl/create-group";
  String addMemberToGroup = "$baseUrl/add-member-to-group";
  String addArchive = "$baseUrl/add-to-archive";
  String addStar = "$baseUrl/add-to-star-message";
  String getRoomIdUrl = "$baseUrl/call-user";
  String blockUserUrl = "$baseUrl/block-user";
  String allStarredUrl = '$baseUrl/star-message-list';
  String blockUserList = '$baseUrl/block-user-list';
  String getReplyUrl = '$baseUrl/get-message-details';
  String exitGroupUrl = '$baseUrl/exit-from-group';
  String addStoryUrl = '$baseUrl/add-status';
  String statusListUrl = '$baseUrl/status-list';
  String clearChatUrl = '$baseUrl/clear-all-chat';
  String viewStatusUrl = '$baseUrl/view-status';
  String myStatusSeenListUrl = '$baseUrl/status-view-list';
  String addStatusUrl = '$baseUrl/add-status';
  String callCutByMe = '$baseUrl/call-cut-by-me';
  String callCutByReceiver = '$baseUrl/call-cut-by-receiver';
  String statusDetele = '$baseUrl/delete-status-media-by-id';
  String callHistory = '$baseUrl/call-list';
  String listOfAvatars = '$baseUrl/list-all-avtars';
  String defaultLanguage = '$baseUrl/fetch-default-language';
  String listOfLanguages = '$baseUrl/List-Language';
  String myContacts = '$baseUrl/my-contacts';
  String deleteAccount = '$baseUrl/delete-account';
  String getAppSettings = '$baseUrl/get-settings';
  String getReportTypesList = '$baseUrl/Report-type-list';
  String reportUser = '$baseUrl/report-user';
  String reportMessage = '$baseUrl/report-message';
  String addPinRemovePin = "$baseUrl/add-to-pin-message";

  static const String staticBaseUrl = 'https://your-domain-name/api';

  Future<Map<String, dynamic>> getMethod(
      {required String url,
      Map<String, String>? headers,
      Map<String, String>? queryParameters}) async {
    try {
      final uri = queryParameters != null
          ? Uri.parse(url).replace(queryParameters: queryParameters)
          : Uri.parse(url);
      final response = await http.get(
        uri,
        headers: headers ??
            <String, String>{
              'Content-Type': 'application/json',
            },
      );
      log("GET URL: $uri");
      // log("$headers");

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        log('jsonResponse--->$jsonData');
        return jsonData;
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> postMethod(
      {required String url,
      Map<String, String>? headers,
      required Map<String, dynamic> requestBody}) async {
    try {
      final body = jsonEncode(requestBody);

      final response = await http.post(
        Uri.parse(url),
        headers: headers ??
            <String, String>{
              'Content-Type': 'application/json',
            },
        body: body,
      );

      log('POST URL: $url');
      log('Body: $body');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        log('jsonResponse--->$jsonResponse');
        return jsonResponse;
      } else if (response.statusCode == 404) {
        final jsonResponse = jsonDecode(response.body);
        log('jsonResponse--->$jsonResponse');
        return jsonResponse;
      } else if (response.statusCode == 422) {
        final jsonResponse = jsonDecode(response.body);
        log('jsonResponse--->$jsonResponse');
        return jsonResponse;
      } else {
        throw Exception('Failed to perform the POST request');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
