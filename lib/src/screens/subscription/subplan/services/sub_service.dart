import 'dart:convert';
import 'dart:developer';
import 'package:corexchat/src/screens/subscription/badge_model.dart';
import 'package:hive/hive.dart';
import 'package:corexchat/src/global/api_helper.dart';
import 'package:corexchat/src/global/strings.dart';
import 'package:corexchat/src/screens/subscription/subplan/sub_plan_model.dart';
import 'package:http/http.dart' as http;

class SubscriptionService {
  static const String baseUrl = ApiHelper.baseUrl;

  // Method to fetch subscription plans
  static Future<List<SubscriptionModel>> fetchSubscriptionPlans() async {
    try {
      // For debugging - print the request details
      print(
          'Fetching subscription plans from: $baseUrl/fetch-subscription-types');
      log('With token: ${Hive.box('userdata').get('authToken')}');

      final response = await http.post(
        Uri.parse('$baseUrl/fetch-subscription-types'),
        headers: {
          'Authorization': 'Bearer ${Hive.box(userdata).get(authToken)}',
          'Accept': 'application/json',
        },
      );

      // For debugging - print the response
      print('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true &&
            jsonData['subscriptionTypes'] != null) {
          List<dynamic> plansJson = jsonData['subscriptionTypes'];
          return plansJson
              .map((plan) => SubscriptionModel.fromJson(plan))
              .toList();
        } else {
          throw Exception('No subscription plans found in response');
        }
      } else {
        throw Exception(
            'Failed to load subscription plans: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in fetchSubscriptionPlans: $e');
      throw Exception('Error: $e');
    }
  }

  // Method to fetch badge types
  static Future<List<BadgeModel>> fetchBadgeTypes() async {
    try {
      print('Fetching badge types from: $baseUrl/fetch-badges-types');

      final response = await http.post(
        Uri.parse('$baseUrl/fetch-badges-types'),
        headers: {
          'Authorization': 'Bearer ${Hive.box(userdata).get(authToken)}',
          'Accept': 'application/json',
        },
      );

      print('Badge response status: ${response.statusCode}');
      log('Badge response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['badges_types'] != null) {
          List<dynamic> badgesJson = jsonData['badges_types'];
          return badgesJson.map((badge) => BadgeModel.fromJson(badge)).toList();
        } else {
          throw Exception('No badge types found in response');
        }
      } else {
        throw Exception('Failed to load badge types: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in fetchBadgeTypes: $e');
      throw Exception('Error: $e');
    }
  }

  // Method to get purchased badge
  static Future<BadgeModel?> getPurchasedBadge() async {
    try {
      final badges = await fetchBadgeTypes();
      final purchasedBadge = badges.firstWhere(
        (badge) => badge.title == 'Purchased',
        orElse: () => BadgeModel(
          logo: '',
          verificationTypeId: 0,
          title: '',
          isPaymentRequired: false,
          isGroup: false,
          cycle: '',
          planPrice: '',
          planDescription: '',
          createdAt: '',
          updatedAt: '',
        ),
      );

      return purchasedBadge;
    } catch (e) {
      print('Exception in getPurchasedBadge: $e');
      return null;
    }
  }

  // Method to get cheapest subscription plan price
  // static Future<String> getCheapestPlanPrice() async {
  //   try {
  //     final plans = await fetchSubscriptionPlans();
  //     if (plans.isEmpty) return 'IDR1';

  //     // Find the cheapest plan
  //     double? cheapestPrice;

  //     for (var plan in plans) {
  //       double price = double.tryParse(plan.planPrice) ?? double.infinity;
  //       if (cheapestPrice == null || price < cheapestPrice) {
  //         cheapestPrice = price;
  //       }
  //     }

  //     // Return formatted price or default to $1
  //     return 'IDR${cheapestPrice?.toStringAsFixed(2) ?? '1'}';
  //   } catch (e) {
  //     print('Exception in getCheapestPlanPrice: $e');
  //     return 'IDR1'; // Default fallback
  //   }
  // }
  static Future<String> getCheapestPlanPrice() async {
    try {
      final plans = await fetchSubscriptionPlans();
      if (plans.isEmpty) return 'IDR1';

      // Find the cheapest plan
      double? cheapestPrice;
      for (var plan in plans) {
        double price = double.tryParse(plan.planPrice) ?? double.infinity;
        if (cheapestPrice == null || price < cheapestPrice) {
          cheapestPrice = price;
        }
      }

      // Format with Indonesian currency format (using periods for thousands)
      if (cheapestPrice != null) {
        // If price is intended to be in thousands (e.g., 49.000 means 49,000)
        String formattedPrice = cheapestPrice.toInt().toString();
        // Add the thousands separator for numbers >= 1000
        if (cheapestPrice >= 1000) {
          formattedPrice = formattedPrice.replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
        }
        return 'IDR$formattedPrice';
      } else {
        return 'IDR1'; // Default fallback
      }
    } catch (e) {
      print('Exception in getCheapestPlanPrice: $e');
      return 'IDR1'; // Default fallback
    }
  }
}
