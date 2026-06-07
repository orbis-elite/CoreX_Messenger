import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:corexchat/Models/user_profile_model.dart';
import 'package:corexchat/src/global/api_helper.dart';
import 'package:corexchat/src/global/strings.dart';
import 'package:corexchat/src/screens/subscription/apple_pay/apple_service.dart';
import 'package:corexchat/src/screens/subscription/badge_model.dart';
import 'package:corexchat/src/screens/subscription/stpper_widget.dart';
import 'package:corexchat/src/screens/user/pp_and_tc_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:corexchat/src/global/global.dart';
import 'package:corexchat/src/screens/layout/bottombar.dart';
import 'package:corexchat/src/screens/subscription/payment/services/payment_service.dart';
import 'package:corexchat/src/screens/subscription/subplan/sub_plan_model.dart';
import 'package:corexchat/src/screens/subscription/subplan/services/sub_service.dart';
import 'package:corexchat/Models/app_settings_model.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';

// Dynamic Apple Plan class
class DynamicApplePlan {
  final ProductDetails product;
  final String planId;
  final int subscriptionTypeId;
  final bool isSubscribed;
  final bool isExpired;
  final String expireDate;
  final int durationMonths;
  final String iconUrl;

  DynamicApplePlan({
    required this.product,
    required this.planId,
    required this.subscriptionTypeId,
    required this.isSubscribed,
    required this.isExpired,
    required this.expireDate,
    required this.durationMonths,
    required this.iconUrl,
  });

  // Get formatted price with correct currency
  String get formattedPrice => product.price;

  // Get currency code
  String get currencyCode => product.currencyCode;

  // Get title from Apple
  String get title => product.title;

  // Get description from Apple
  String get description => product.description;

  // Get product ID
  String get productId => product.id;

  // Get icon URL
  String get planIcon => iconUrl;

  // Get monthly price for comparison
  double get monthlyPrice {
    final priceString = product.price.replaceAll(RegExp(r'[^\d.]'), '');
    final price = double.tryParse(priceString) ?? 0.0;
    return durationMonths > 0 ? price / durationMonths : price;
  }
}

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

// Fixed: Properly extend State with WidgetsBindingObserver for app lifecycle
class _SubscriptionScreenState extends State<SubscriptionScreen>
    with WidgetsBindingObserver {
  List<SubscriptionModel> subscriptionPlans = [];
  List<dynamic> applePlans = []; // Dynamic list for Apple products
  bool isLoading = true;
  bool isProcessingPayment = false;
  String errorMessage = '';
  int? selectedPlanIndex = 0;
  bool hasActivePlan = false;
  bool hasCancelled = false;
  int? activePlanIndex;

  // Current step in the subscription flow
  int currentStep = 1;

  BadgeModel? purchasedBadge;
  String cheapestPlanPrice = 'IDR1';
  bool isInitializing = true;

  // Apple Pay variables
  late ApplePaySubscriptionService _applePayService;
  bool _isApplePayAvailable = false;
  bool _showPaymentOptions = false;
  String? _selectedPaymentMethod; // 'xendit' or 'apple_pay'

  // App settings
  AppSettingsModel? _appSettings;
  bool _isXenditEnabled = true;
  bool _isApplePayEnabled = true;

  @override
  void initState() {
    print('sub plan call>>>>');
    super.initState();
    // Add this widget as an observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    _initializeApplePay();
    _fetchAppSettings();
    _initializeData();
  }

  @override
  void dispose() {
    // Remove observer and dispose Apple Pay service
    WidgetsBinding.instance.removeObserver(this);
    _applePayService.dispose();
    super.dispose();
  }

  // Fixed: Properly override the lifecycle method
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _applePayService.handleAppLifecycle(state);
  }

  Future<void> _initializeApplePay() async {
    _applePayService = ApplePaySubscriptionService();
    if (Platform.isIOS) {
      _isApplePayAvailable = await _applePayService.initialize();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _fetchAppSettings() async {
    print('_fetchAppSettings from subplan >>>');
    try {
      final token = Hive.box(userdata).get(authToken);
      if (token == null) return;

      final response = await http.post(
        Uri.parse(apiHelper.getAppSettings),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        _appSettings = AppSettingsModel.fromJson(jsonData);

        if (_appSettings?.settings?.isNotEmpty == true) {
          final settings = _appSettings!.settings!.first;
          print('apple pay check: ${settings.applePayMethod}');
          print('xendit pay check: ${settings.applePayMethod}');
          _isXenditEnabled = settings.xenditPayMethod ?? true;
          _isApplePayEnabled = settings.applePayMethod ?? true;
        }

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('Error fetching app settings: $e');
    }
  }

  Future<void> _initializeData() async {
    print("DEBUG: _initializeData started");

    setState(() {
      isInitializing = true;
      hasCancelled = false;
    });

    try {
      purchasedBadge = await SubscriptionService.getPurchasedBadge();
      print("DEBUG: Purchased badge loaded: ${purchasedBadge != null}");

      cheapestPlanPrice = await SubscriptionService.getCheapestPlanPrice();
      print("DEBUG: Cheapest plan price: $cheapestPlanPrice");

      await _fetchSubscriptionPlans();
      print(
          "DEBUG: After _fetchSubscriptionPlans: hasActivePlan=$hasActivePlan, hasCancelled=$hasCancelled");
    } catch (e) {
      print('ERROR in initialization: $e');
      setState(() {
        errorMessage = 'Failed to load subscription data. Please try again.';
      });
    } finally {
      setState(() {
        isInitializing = false;
        print(
            "DEBUG: _initializeData complete: hasActivePlan=$hasActivePlan, hasCancelled=$hasCancelled, currentStep=$currentStep");
      });
    }
  }

  Future<void> _fetchSubscriptionPlans() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      if (Platform.isIOS) {
        // For iOS, load dynamic Apple plans
        if (!_applePayService.isInitializedWithProducts) {
          print("DEBUG: Apple Pay service not yet initialized, waiting...");
          await _applePayService.initialize();
        }
        await _loadDynamicApplePlans();
      } else {
        // For Android, use the existing backend API
        await _loadAndroidPlans();
      }
    } catch (e) {
      print("ERROR in _fetchSubscriptionPlans: $e");
      setState(() {
        errorMessage = 'Failed to load subscription plans. Please try again.';
        isLoading = false;
      });
    }
  }

  Future<void> _loadAndroidPlans() async {
    final plans = await SubscriptionService.fetchSubscriptionPlans();
    int? activeIndex;
    bool foundCancelledPlan = false;

    print("DEBUG: Received ${plans.length} Android subscription plans");

    // Check for active/cancelled plans
    for (int i = 0; i < plans.length; i++) {
      if (plans[i].isSubscribed &&
          !isSubscriptionExpired(plans[i].expireDate)) {
        activeIndex = i;
        if (plans[i].isExpired) {
          foundCancelledPlan = true;
        }
        break;
      }
    }

    if (activeIndex == null) {
      for (int i = 0; i < plans.length; i++) {
        if (plans[i].isSubscribed && plans[i].isExpired) {
          foundCancelledPlan = true;
          break;
        }
      }
    }

    setState(() {
      subscriptionPlans = plans;
      applePlans = []; // Clear Apple plans
      isLoading = false;
      hasCancelled = foundCancelledPlan;

      if (activeIndex != null) {
        activePlanIndex = activeIndex;
        hasActivePlan = true;
        selectedPlanIndex = null;
        currentStep = 3;
      } else {
        hasActivePlan = false;
        activePlanIndex = null;
        selectedPlanIndex = 0;
        currentStep = 1;
      }
    });
  }

  Future<void> _loadDynamicApplePlans() async {
    final availableProducts = _applePayService.availableProducts;
    final backendPlans = await SubscriptionService.fetchSubscriptionPlans();

    print(
        "DEBUG: Loading ${availableProducts.length} Apple products dynamically");

    List<DynamicApplePlan> dynamicPlans = [];
    bool foundCancelledPlan = false;

    for (final product in availableProducts) {
      print("DEBUG: Processing Apple product: ${product.id}");
      print("  - Title: ${product.title}");
      print("  - Description: ${product.description}");
      print("  - Price: ${product.price}");
      print("  - Currency: ${product.currencyCode}");

      final planId = _getApplePlanIdFromProductId(product.id);
      final subscriptionTypeId = _getSubscriptionTypeIdFromApplePlanId(planId);
      final durationMonths = _getDurationFromPlanId(planId);
      // final iconUrl = _getApplePlanIcon(planId);

      print("  - Plan ID: $planId");
      print("  - Subscription Type ID: $subscriptionTypeId");
      print("  - Duration: $durationMonths months");

      // Find matching backend plan for subscription status
      SubscriptionModel? matchingBackendPlan;
      for (final backendPlan in backendPlans) {
        if (backendPlan.subscriptionTypeId == subscriptionTypeId) {
          matchingBackendPlan = backendPlan;
          break;
        }
      }

      // Use Android plan icon from backend instead of hardcoded URLs
      final iconUrl =
          matchingBackendPlan?.planIcon ?? _getApplePlanIcon(planId);
      print("  - Icon URL: $iconUrl");

      final dynamicPlan = DynamicApplePlan(
        product: product,
        planId: planId,
        subscriptionTypeId: subscriptionTypeId,
        isSubscribed: matchingBackendPlan?.isSubscribed ?? false,
        isExpired: matchingBackendPlan?.isExpired ?? false,
        expireDate: matchingBackendPlan?.expireDate ?? '',
        durationMonths: durationMonths,
        iconUrl: iconUrl,
      );

      dynamicPlans.add(dynamicPlan);

      // Check for canceled but active plans
      if (dynamicPlan.isSubscribed &&
          dynamicPlan.isExpired &&
          !isSubscriptionExpired(dynamicPlan.expireDate)) {
        foundCancelledPlan = true;
      }
    }

    // Sort by duration (shortest first)
    dynamicPlans.sort((a, b) => a.durationMonths.compareTo(b.durationMonths));

    // Re-find the active plan index after sorting
    int? newActiveIndex;
    for (int i = 0; i < dynamicPlans.length; i++) {
      if (dynamicPlans[i].isSubscribed &&
          !isSubscriptionExpired(dynamicPlans[i].expireDate)) {
        newActiveIndex = i;
        break;
      }
    }

    setState(() {
      applePlans = dynamicPlans;
      subscriptionPlans = []; // Clear Android plans
      isLoading = false;
      hasCancelled = foundCancelledPlan;

      if (newActiveIndex != null) {
        activePlanIndex = newActiveIndex;
        hasActivePlan = true;
        selectedPlanIndex = null;
        currentStep = 3;
      } else {
        hasActivePlan = false;
        activePlanIndex = null;
        selectedPlanIndex = 0;
        currentStep = 1;
      }
    });

    print(
        "DEBUG: Successfully loaded ${dynamicPlans.length} dynamic Apple plans");
  }

  int _getDurationFromPlanId(String planId) {
    switch (planId) {
      case 'velvet_access':
        return 1;
      case 'sapphire_pass':
        return 3;
      case 'golden_privilege':
        return 6;
      case 'elite_infinity':
        return 12;
      default:
        return 1;
    }
  }

  /// Load subscription plans from Apple's in-app purchase products for iOS
  Future<List<SubscriptionModel>> _loadAppleSubscriptionPlans() async {
    try {
      // Get available Apple products
      final availableProducts = _applePayService.availableProducts;

      print("DEBUG: Raw Apple products loaded: ${availableProducts.length}");
      for (int i = 0; i < availableProducts.length; i++) {
        final product = availableProducts[i];
        print("DEBUG: Apple Product [$i]:");
        print("  - ID: ${product.id}");
        print("  - Title: ${product.title}");
        print("  - Description: ${product.description}");
        print("  - Price: ${product.price}");
        print("  - Currency Code: ${product.currencyCode}");
        print("  ---");
      }

      if (availableProducts.isEmpty) {
        print(
            "DEBUG: No Apple products available, falling back to backend API");
        return await SubscriptionService.fetchSubscriptionPlans();
      }

      // Get current subscription status from backend
      final backendPlans = await SubscriptionService.fetchSubscriptionPlans();

      print("DEBUG: Backend plans loaded: ${backendPlans.length}");
      for (int i = 0; i < backendPlans.length; i++) {
        final plan = backendPlans[i];
        print("DEBUG: Backend Plan [$i]:");
        print("  - Title: ${plan.title}");
        print("  - Subscription Type ID: ${plan.subscriptionTypeId}");
        print("  - Is Subscribed: ${plan.isSubscribed}");
        print("  - Is Expired: ${plan.isExpired}");
        print("  - Expire Date: ${plan.expireDate}");
        print("  ---");
      }

      List<SubscriptionModel> applePlans = [];

      // Map Apple products to subscription models
      for (final product in availableProducts) {
        print("DEBUG: Processing Apple product: ${product.id}");

        final planId = _getApplePlanIdFromProductId(product.id);
        final subscriptionTypeId =
            _getSubscriptionTypeIdFromApplePlanId(planId);

        print(
            "DEBUG: Mapped ${product.id} -> planId: $planId -> subscriptionTypeId: $subscriptionTypeId");

        // Find matching backend plan for subscription status
        SubscriptionModel? matchingBackendPlan;
        for (final backendPlan in backendPlans) {
          if (backendPlan.subscriptionTypeId == subscriptionTypeId) {
            matchingBackendPlan = backendPlan;
            print("DEBUG: Found matching backend plan: ${backendPlan.title}");
            break;
          }
        }

        if (matchingBackendPlan == null) {
          print(
              "DEBUG: No matching backend plan found for subscriptionTypeId: $subscriptionTypeId");
        }

        // Create subscription model from Apple product
        final subscriptionModel = SubscriptionModel(
          planIcon: _getApplePlanIcon(planId),
          subscriptionTypeId: subscriptionTypeId,
          title: _getApplePlanTitle(planId),
          cycle: _getApplePlanCycle(planId),
          planPrice: _extractPriceFromProduct(product),
          planDescription: product.description,
          status: matchingBackendPlan?.status ??
              true, // Apple products are active by default
          createdAt: matchingBackendPlan?.createdAt ??
              DateTime.now().toIso8601String(),
          updatedAt: matchingBackendPlan?.updatedAt ??
              DateTime.now().toIso8601String(),
          // Use backend plan data for subscription status if available
          isSubscribed: matchingBackendPlan?.isSubscribed ?? false,
          isExpired: matchingBackendPlan?.isExpired ?? false,
          expireDate: matchingBackendPlan?.expireDate ?? '',
        );

        applePlans.add(subscriptionModel);
      }

      // Sort plans by subscription type ID to maintain consistent order
      applePlans
          .sort((a, b) => a.subscriptionTypeId.compareTo(b.subscriptionTypeId));

      print(
          "DEBUG: Successfully loaded ${applePlans.length} Apple subscription plans");

      // Print detailed information about each loaded dynamic plan
      for (int i = 0; i < applePlans.length; i++) {
        final plan = applePlans[i] as DynamicApplePlan;
        print("DEBUG: Dynamic Apple Plan [$i]:");
        print("  - Title: ${plan.title}");
        print("  - Description: ${plan.description}");
        print("  - Price: ${plan.formattedPrice}");
        print("  - Currency: ${plan.currencyCode}");
        print("  - Duration: ${plan.durationMonths} months");
        print("  - Icon URL: ${plan.planIcon}");
        print("  - Product ID: ${plan.productId}");
        print("  - Plan ID: ${plan.planId}");
        print("  - Subscription Type ID: ${plan.subscriptionTypeId}");
        print("  - Is Subscribed: ${plan.isSubscribed}");
        print("  - Is Expired: ${plan.isExpired}");
        print("  - Expire Date: ${plan.expireDate}");
        print("  - Monthly Price: ${plan.monthlyPrice}");
        print("  ---");
      }

      return applePlans;
    } catch (e) {
      print("ERROR loading Apple subscription plans: $e");
      // Fallback to backend API if Apple products fail
      return await SubscriptionService.fetchSubscriptionPlans();
    }
  }

  /// Extract price from Apple product and convert to string
  String _extractPriceFromProduct(dynamic product) {
    try {
      // For ProductDetails, the price is already formatted
      final priceString = product.price;
      // Remove currency symbol and convert to numeric string
      final numericPrice = priceString.replaceAll(RegExp(r'[^\d.]'), '');
      // Convert to Indonesian Rupiah (assuming your backend expects IDR)
      final double price = double.tryParse(numericPrice) ?? 0.0;
      // Convert from USD to IDR (approximate rate, you should use real exchange rates)
      final double idrPrice = price * 15000; // 1 USD ≈ 15,000 IDR
      return idrPrice.toInt().toString();
    } catch (e) {
      print("ERROR extracting price from product: $e");
      return "0";
    }
  }

  /// Get plan ID from Apple product ID
  String _getApplePlanIdFromProductId(String productId) {
    // Reverse lookup from ApplePaySubscriptionService.productIds
    const reverseMap = {
      'velvet_access': 'velvet_access',
      'sapphire_pass': 'sapphire_pass',
      'golden_privilege': 'golden_privilege',
      'elite_infinity': 'elite_infinity',
    };

    return reverseMap[productId] ?? 'velvet_access';
  }

  /// Get subscription type ID from Apple plan ID
  int _getSubscriptionTypeIdFromApplePlanId(String planId) {
    switch (planId) {
      case 'velvet_access':
        return 7;
      case 'sapphire_pass':
        return 8;
      case 'golden_privilege':
        return 9;
      case 'elite_infinity':
        return 10;
      default:
        return 7;
    }
  }

  /// Get Apple plan ID from subscription type ID (reverse mapping)
  String _getApplePlanIdFromSubscriptionType(int subscriptionTypeId) {
    switch (subscriptionTypeId) {
      case 7:
        return 'velvet_access';
      case 8:
        return 'sapphire_pass';
      case 9:
        return 'golden_privilege';
      case 10:
        return 'elite_infinity';
      default:
        return 'velvet_access';
    }
  }

  /// Get plan title for Apple plan ID
  String _getApplePlanTitle(String planId) {
    switch (planId) {
      case 'velvet_access':
        return 'Velvet Access';
      case 'sapphire_pass':
        return 'Sapphire Pass';
      case 'golden_privilege':
        return 'Golden Privilege';
      case 'elite_infinity':
        return 'Elite Infinity';
      default:
        return 'Premium Plan';
    }
  }

  /// Get plan icon for Apple plan ID
  String _getApplePlanIcon(String planId) {
    switch (planId) {
      case 'velvet_access':
        return 'https://cdn-icons-png.flaticon.com/512/3003/3003984.png'; // Velvet/Premium icon
      case 'sapphire_pass':
        return 'https://cdn-icons-png.flaticon.com/512/2917/2917995.png'; // Sapphire/Diamond icon
      case 'golden_privilege':
        return 'https://cdn-icons-png.flaticon.com/512/2917/2917928.png'; // Golden/Crown icon
      case 'elite_infinity':
        return 'https://cdn-icons-png.flaticon.com/512/3003/3003467.png'; // Elite/Infinity icon
      default:
        return 'https://cdn-icons-png.flaticon.com/512/3003/3003984.png'; // Default premium icon
    }
  }

  /// Get plan cycle for Apple plan ID
  String _getApplePlanCycle(String planId) {
    switch (planId) {
      case 'velvet_access':
        return '1';
      case 'sapphire_pass':
        return '3';
      case 'golden_privilege':
        return '6';
      case 'elite_infinity':
        return '12';
      default:
        return '1';
    }
  }

  void _nextStep() {
    setState(() {
      currentStep++;
    });
  }

  void _previousStep() {
    setState(() {
      if (currentStep > 1) {
        currentStep--;
      }
    });
  }

  bool isSubscriptionExpired(String expiryDateString) {
    try {
      if (expiryDateString.isEmpty) {
        return true;
      }

      DateTime expiryDate = DateTime.parse(expiryDateString);
      DateTime today = DateTime.now();
      DateTime todayWithoutTime = DateTime(today.year, today.month, today.day);

      return todayWithoutTime.isAfter(expiryDate);
    } catch (e) {
      print("Error parsing expiry date: $e");
      return true;
    }
  }

  String formatExpiryDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      final List<String> months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      return '${date.day} ${months[date.month - 1]}, ${date.year}';
    } catch (e) {
      print("Error formatting date: $e");
      return dateString;
    }
  }

  void _handleSubscriptionPurchase() async {
    if (selectedPlanIndex == null) {
      return;
    }

    if (Platform.isIOS) {
      if (selectedPlanIndex! >= applePlans.length) {
        return;
      }
      final selectedPlan = applePlans[selectedPlanIndex!] as DynamicApplePlan;
      _processApplePaymentDynamic(selectedPlan);
    } else {
      if (selectedPlanIndex! >= subscriptionPlans.length) {
        return;
      }
      final selectedPlan = subscriptionPlans[selectedPlanIndex!];
      _processXenditPayment(selectedPlan);
    }
  }

  void _processApplePaymentDynamic(DynamicApplePlan selectedPlan) async {
    print(
        'DEBUG: Processing Apple Pay for dynamic plan: ${selectedPlan.title}');
    print('DEBUG: Apple Product ID: ${selectedPlan.productId}');
    print('DEBUG: Price: ${selectedPlan.formattedPrice}');
    print('DEBUG: Currency: ${selectedPlan.currencyCode}');

    final success = await _applePayService.purchaseSubscription(
      amount: selectedPlan.formattedPrice.replaceAll(RegExp(r'[^\d.]'), ''),
      cycle: selectedPlan.durationMonths.toString(),
      planId: selectedPlan.productId, // Use Apple product ID directly
      context: context,
      onPaymentStarted: () {
        print('DEBUG: Apple Pay payment started');
        setState(() {
          isProcessingPayment = true;
        });
      },
      onPaymentCompleted: () {
        print('DEBUG: Apple Pay payment completed');
        setState(() {
          isProcessingPayment = false;
        });
      },
      onError: (errorMsg) {
        print('ERROR: Apple Pay error: $errorMsg');
        setState(() {
          isProcessingPayment = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      },
      onSuccess: (transactionId, productId) {
        print(
            'DEBUG: Apple Pay success - Transaction: $transactionId, Product: $productId');
        _handleApplePaySuccess(transactionId, productId);
      },
    );
  }

  void _processOriginalApplePayment(SubscriptionModel selectedPlan) async {
    // Check if both payment methods are available based on app settings
    bool canUseApplePay =
        _isApplePayAvailable && _isApplePayEnabled && Platform.isIOS;
    bool canUseXendit =
        _isXenditEnabled && Platform.isAndroid; // Xendit only for Android

    print(
        'DEBUG: Payment method availability - ApplePay: $canUseApplePay, Xendit: $canUseXendit');

    if (Platform.isIOS) {
      // For iOS, always use Apple Pay (in-app purchases)
      if (canUseApplePay) {
        _processApplePayment(selectedPlan);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Apple Pay subscriptions are not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (Platform.isAndroid) {
      // For Android, use Xendit or show both options if needed
      if (canUseXendit) {
        _processXenditPayment(selectedPlan);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No payment methods are currently available'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPaymentMethodSelection(SubscriptionModel selectedPlan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Payment Method',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Apple Pay Option - only show if enabled
            if (_isApplePayEnabled && _isApplePayAvailable) ...[
              _buildPaymentOption(
                title: 'Apple Pay',
                subtitle: 'Pay with Touch ID or Face ID',
                icon: Icons.apple,
                isApplePay: true,
                onTap: () {
                  Navigator.pop(context);
                  _processApplePayment(selectedPlan);
                },
              ),
              const SizedBox(height: 12),
            ],

            // Xendit Payment Option - only show if enabled
            if (_isXenditEnabled)
              _buildPaymentOption(
                title: 'Credit/Debit Card',
                subtitle: 'Pay with your card',
                icon: Icons.credit_card,
                isApplePay: false,
                onTap: () {
                  Navigator.pop(context);
                  _processXenditPayment(selectedPlan);
                },
              ),

            const SizedBox(height: 20),

            // Cancel button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isApplePay,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isApplePay ? Colors.black : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isApplePay ? Colors.white : Colors.blue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  void _processApplePayment(SubscriptionModel selectedPlan) async {
    print('DEBUG: Processing Apple Pay for plan: ${selectedPlan.title}');
    print('DEBUG: Subscription type ID: ${selectedPlan.subscriptionTypeId}');

    String planId;
    if (Platform.isIOS) {
      // For iOS, get the Apple product ID from the subscription type
      planId =
          _getApplePlanIdFromSubscriptionType(selectedPlan.subscriptionTypeId);
    } else {
      // For Android fallback, use the subscription type mapping
      planId = _getPlanIdFromSubscriptionType(selectedPlan.subscriptionTypeId);
    }
    print('DEBUG: Final plan ID for Apple Pay: $planId');

    // This will internally set the selected product ID similar to your _kProductIds approach
    final success = await _applePayService.purchaseSubscription(
      amount: selectedPlan.planPrice,
      cycle: selectedPlan.cycle,
      planId: planId, // This will map to the correct Apple product ID
      context: context,
      onPaymentStarted: () {
        print('DEBUG: Apple Pay payment started');
        setState(() {
          isProcessingPayment = true;
        });
      },
      onPaymentCompleted: () {
        print('DEBUG: Apple Pay payment completed');
        setState(() {
          isProcessingPayment = false;
        });
      },
      onError: (errorMsg) {
        print('ERROR: Apple Pay error: $errorMsg');
        setState(() {
          isProcessingPayment = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      },
      onSuccess: (transactionId, productId) {
        print(
            'DEBUG: Apple Pay success - Transaction: $transactionId, Product: $productId');
        _handleApplePaySuccess(transactionId, productId);
      },
    );
  }

  bool _isProcessingApplePaySuccess = false;

  void _handleApplePaySuccess(String transactionId, String productId) {
    // Prevent multiple success processing
    if (_isProcessingApplePaySuccess || !mounted) {
      print('DEBUG: Apple Pay success already being processed, skipping');
      return;
    }

    _isProcessingApplePaySuccess = true;
    print(
        'DEBUG: Processing Apple Pay success for transaction: $transactionId');

    // Update subscription plans first
    _fetchSubscriptionPlans().then((_) {
      if (mounted) {
        _showPaymentSuccessDialog(isApplePay: true);
      }
    }).catchError((error) {
      print('ERROR: Failed to fetch subscription plans: $error');
      if (mounted) {
        _showPaymentSuccessDialog(isApplePay: true);
      }
    }).whenComplete(() {
      _isProcessingApplePaySuccess = false;
    });
  }

  // Fixed: Updated plan ID mapping to match your actual subscription type IDs
  String _getPlanIdFromSubscriptionType(int subscriptionTypeId) {
    print('DEBUG: Getting plan ID for subscription type: $subscriptionTypeId');

    String planId;
    switch (subscriptionTypeId) {
      case 7: // Velvet Access
        planId = 'velvet_access';
        break;
      case 8: // Sapphire Pass
        planId = 'sapphire_pass';
        break;
      case 9: // Golden Privilege
        planId = 'golden_privilege';
        break;
      case 10: // Elite Infinity
        planId = 'elite_infinity';
        break;
      default:
        planId = 'velvet_access'; // default fallback
        break;
    }

    print('DEBUG: Mapped to plan ID: $planId');
    return planId;
  }

// Debug: You can also check what product IDs are selected
  void _debugSelectedProducts() {
    List<String> selectedIds = _applePayService.selectedProductIds;
    print('DEBUG: Currently selected product IDs: $selectedIds');
  }

  void _processXenditPayment(SubscriptionModel selectedPlan) async {
    double planPrice = double.tryParse(selectedPlan.planPrice) ?? 0;
    int durationInMonths = int.tryParse(selectedPlan.cycle) ?? 1;
    int subscriptionTypeId = selectedPlan.subscriptionTypeId;
    String planCycle = selectedPlan.cycle ?? '0';

    final success = await PaymentService.showSubscriptionFormAndProcessPayment(
      cycle: planCycle,
      amount: planPrice,
      durationInMonths: durationInMonths,
      subscriptionTypeId: subscriptionTypeId,
      context: context,
      onPaymentStarted: () {
        setState(() {
          isProcessingPayment = true;
        });
      },
      onPaymentCompleted: () {
        setState(() {
          isProcessingPayment = false;
        });
      },
      onError: (errorMsg) {
        setState(() {
          isProcessingPayment = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      },
    );

    if (success) {
      _showPaymentSuccessDialog(isApplePay: false);
    }
  }

  void _showPaymentSuccessDialog({required bool isApplePay}) {
    // Prevent multiple dialogs
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 50,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isApplePay
                  ? 'Your subscription has been activated.'
                  : 'Your subscription has been activated successfully',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context); // Close dialog
                }
                // Use a slight delay to ensure dialog is closed before navigation
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => TabbarScreen()),
                      (route) => false,
                    );
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> cancelSubscription() async {
    // Check if user has Apple Pay subscription
    final appleStatus = await _applePayService.getSubscriptionStatus();

    if (appleStatus != null && appleStatus['has_active_subscription'] == true) {
      // Show Apple Pay cancellation instructions
      _applePayService.cancelSubscription();
      return;
    }

    // Continue with existing Xendit cancellation logic
    setState(() {
      isCancellingSubscription = true;
    });

    try {
      await _getToken();
      closeKeyboard();

      var uri = Uri.parse(apiHelper.userCreateProfile);
      var request = http.MultipartRequest("POST", uri);

      Map<String, String> headers = {
        "Accept": "application/json",
        'Authorization': 'Bearer ${Hive.box(userdata).get(authToken)}'
      };

      request.headers.addAll(headers);
      request.fields['cancle_badge'] = 'true';

      var response = await request.send();
      String responseData =
          await response.stream.transform(utf8.decoder).join();
      var userData = json.decode(responseData);
      userProfileModel = UserProfileModel.fromJson(userData);

      if (userProfileModel.success == true) {
        await Hive.box(userdata)
            .put(userBio, userProfileModel.resData!.bio.toString());

        Fluttertoast.showToast(
          msg: "Subscription cancelled successfully",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        await _fetchSubscriptionPlans();
        setState(() {
          isCancellingSubscription = false;
        });
      } else {
        Fluttertoast.showToast(
          msg: "Failed to cancel subscription. Please try again.",
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red,
        );
        setState(() {
          isCancellingSubscription = false;
        });
      }
    } catch (e) {
      print("Error cancelling subscription: $e");
      Fluttertoast.showToast(
        msg: "An error occurred. Please try again.",
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
      );
      setState(() {
        isCancellingSubscription = false;
      });
    }
  }

  // Helper variables and methods
  bool isCancellingSubscription = false;
  String _fcmtoken = '';
  late UserProfileModel userProfileModel;
  final apiHelper = ApiHelper();

  Future<void> _getToken() async {
    _fcmtoken = Hive.box(userdata).get(authToken) ?? '';
  }

  void closeKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we have a canceled but still active plan
    bool hasCanceledActivePlan = false;

    if (activePlanIndex != null) {
      if (Platform.isIOS && activePlanIndex! < applePlans.length) {
        // For iOS, check Apple plans
        final activePlan = applePlans[activePlanIndex!] as DynamicApplePlan;
        hasCanceledActivePlan = activePlan.isExpired &&
            !isSubscriptionExpired(activePlan.expireDate);
      } else if (Platform.isAndroid &&
          activePlanIndex! < subscriptionPlans.length) {
        // For Android, check subscription plans
        final activePlan = subscriptionPlans[activePlanIndex!];
        hasCanceledActivePlan = activePlan.isExpired &&
            !isSubscriptionExpired(activePlan.expireDate);
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(context),
              SubscriptionStepper(currentStep: hasActivePlan ? 3 : currentStep),
              Expanded(
                child: isLoading
                    ? Center(child: loader(context))
                    : errorMessage.isNotEmpty
                        ? _buildErrorView()
                        : _buildContent(),
              ),
              // Bottom button logic
              if (!hasActivePlan)
                Container(
                  padding: EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    top: 16.0,
                    bottom: 16.0 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: _buildBottomButton(),
                ),
              // For active plans, show either cancel button or resubscribe button
              if (hasActivePlan && !hasCanceledActivePlan)
                Container(
                  padding: EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    top: 16.0,
                    bottom: 16.0 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: hasCanceledActivePlan
                      ? _buildResubscribeButton()
                      : _buildCancelButton(),
                ),
            ],
          ),
          // Full-screen loading overlay for payment processing
          if (isProcessingPayment)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: loader(context),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResubscribeButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.blue.shade700],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: TextButton(
        onPressed: () {
          setState(() {
            hasActivePlan = false;
            selectedPlanIndex = 0;
            currentStep = 2;
          });
        },
        child: const Text(
          'Subscribe Again',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade300),
      ),
      child: TextButton(
        onPressed: _showCancellationConfirmDialog,
        child: Text(
          'Cancel Subscription',
          style: TextStyle(
            color: Colors.red.shade700,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showCancellationConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: appColorWhite,
          title: const Text('Cancel Subscription'),
          content: const Text(
            'Are you sure you want to cancel your subscription? Your verified badge and premium benefits will be removed.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No, Keep It'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                cancelSubscription();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchSubscriptionPlans,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade50,
              foregroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Try Again'),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildContent() {
    print(
        "DEBUG: _buildContent() called with hasActivePlan=$hasActivePlan, hasCancelled=$hasCancelled, currentStep=$currentStep");

    if (hasActivePlan) {
      if (Platform.isIOS &&
          activePlanIndex != null &&
          activePlanIndex! < applePlans.length) {
        // For iOS, check Apple plans
        final activePlan = applePlans[activePlanIndex!] as DynamicApplePlan;
        if (activePlan.isExpired &&
            !isSubscriptionExpired(activePlan.expireDate)) {
          print("DEBUG: Showing active but canceled Apple plan");
        } else {
          print("DEBUG: Showing fully active Apple plan");
        }
      } else if (Platform.isAndroid &&
          activePlanIndex != null &&
          activePlanIndex! < subscriptionPlans.length) {
        // For Android, check subscription plans
        final activePlan = subscriptionPlans[activePlanIndex!];
        if (activePlan.isExpired &&
            !isSubscriptionExpired(activePlan.expireDate)) {
          print("DEBUG: Showing active but canceled plan");
        } else {
          print("DEBUG: Showing fully active plan");
        }
      }
      return _buildActivePlanContent();
    }

    if (hasCancelled) {
      print("DEBUG: User has a canceled and expired plan");
      return _buildCancelledContent();
    }

    print("DEBUG: Showing regular step content for step $currentStep");
    return _buildStepContent();
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case 1:
        return _buildStep1Content();
      case 2:
        return _buildStep2Content();
      default:
        return _buildStep1Content();
    }
  }

  Widget _buildBottomButton() {
    if (currentStep == 1) {
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors: [secondaryColor, chatownColor],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: TextButton(
          onPressed: _nextStep,
          child: const Text(
            'Unlock benefits',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.blue.shade700],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: TextButton(
          onPressed: () {
            if (selectedPlanIndex != null) {
              _handleSubscriptionPurchase();
            } else {
              Fluttertoast.showToast(
                msg: "Please select a subscription plan to continue",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Colors.red.shade800,
                textColor: Colors.white,
                fontSize: 16.0,
              );
              HapticFeedback.lightImpact();
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (Platform.isIOS &&
                  _isApplePayAvailable &&
                  _isApplePayEnabled) ...[
                // Icon(
                //   Icons.apple,
                //   color: Colors.white,
                //   size: 18,
                // ),
                const SizedBox(width: 8),
                const Text(
                  'Subscribe Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else ...[
                const Text(
                  'Subscribe Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
  }

  Widget _buildHeader(BuildContext context) {
    return AppBar(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      surfaceTintColor: Colors.white,
      backgroundColor: Colors.white,
      scrolledUnderElevation: 0,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          InkWell(
            onTap: () {
              if (currentStep > 1 && !hasActivePlan) {
                _previousStep();
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Image.asset(
              "assets/images/arrow-left.png",
              height: 22,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Orbis Elite Verified',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Add all the remaining UI building methods from your original code
  Widget _buildActivePlanContent() {
    return Scrollbar(
      thickness: 6,
      radius: const Radius.circular(10),
      thumbVisibility: true,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildTitle(),
                const SizedBox(height: 16),
                _buildActivePlanInfo(),
                const SizedBox(height: 24),
                _buildActiveSubscriptionDetails(),
                const SizedBox(height: 24),
                _buildActivePlanOnly(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelledContent() {
    return Scrollbar(
      thickness: 6,
      radius: const Radius.circular(10),
      thumbVisibility: true,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildCanceledPlanNotification(),
                const SizedBox(height: 24),
                Text(
                  'Starting at just ${cheapestPlanPrice}/month',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _buildUserProfile(),
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    children: [
                      _buildBenefitsList(),
                      SizedBox(
                        height: 20,
                      ),
                      // _buildEligibilitySection()
                      privacyPolicyWidget()
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1Content() {
    print("DEBUG: _buildStep1Content called with hasCancelled=$hasCancelled");

    return Scrollbar(
      thickness: 6,
      radius: const Radius.circular(10),
      thumbVisibility: true,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                if (hasCancelled) _buildCanceledPlanNotification(),
                Text(
                  'Starting at just ${cheapestPlanPrice}/month',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _buildUserProfile(),
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    children: [
                      _buildBenefitsList(),
                      SizedBox(
                        height: 20,
                      ),
                      // _buildEligibilitySection()
                      privacyPolicyWidget()
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep2Content() {
    return Scrollbar(
      thickness: 6,
      radius: const Radius.circular(10),
      thumbVisibility: true,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Our Plan',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      _buildUserProfile(),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Orbis Elite Verified Nexus",
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildSubscriptionPlans(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Add the remaining UI building methods...
  Widget _buildTitle() {
    return Text(
      hasActivePlan ? 'Our Subscription' : 'Select Your Plan',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
    );
  }

  Widget _buildUserProfile() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(45),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(45),
                    child: Hive.box(userdata).get(userImage) != null &&
                            Hive.box(userdata)
                                .get(userImage)
                                .toString()
                                .isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: Hive.box(userdata).get(userImage),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => loader(context),
                            errorWidget: (context, url, error) => Image.asset(
                              "assets/images/user_placeholder.png",
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            "assets/images/user_placeholder.png",
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Image.asset(
                    "assets/icons/Nobg_qr.png",
                    height: 24,
                    width: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              Hive.box(userdata).get(userName) ?? "User",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 5),
            if (purchasedBadge != null && purchasedBadge!.logo.isNotEmpty)
              Container(
                width: 24,
                height: 24,
                child: CachedNetworkImage(
                  imageUrl: purchasedBadge!.logo,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCanceledPlanNotification() {
    SubscriptionModel? canceledPlan;
    for (var plan in subscriptionPlans) {
      if (plan.isSubscribed && plan.isExpired) {
        canceledPlan = plan;
        break;
      }
    }

    if (canceledPlan == null) {
      print("DEBUG: No canceled plan found despite hasCancelled=true");
      return const SizedBox.shrink();
    }

    print(
        "DEBUG: Showing canceled plan notification for ${canceledPlan.title}");

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              const Text(
                'Subscription Cancelled',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your ${canceledPlan.title} subscription has been cancelled.',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your verified badge and premium features are no longer active.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              setState(() {
                hasActivePlan = false;
                activePlanIndex = null;
                selectedPlanIndex = 0;
                currentStep = 2;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Subscribe Again',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePlanInfo() {
    if (activePlanIndex == null) {
      return const SizedBox.shrink();
    }

    String formattedExpiryDate;
    bool isCanceledButActive;
    String planTitle;

    if (Platform.isIOS && activePlanIndex! < applePlans.length) {
      // For iOS, use Apple plans
      final activePlan = applePlans[activePlanIndex!] as DynamicApplePlan;
      formattedExpiryDate = formatExpiryDate(activePlan.expireDate);
      isCanceledButActive =
          activePlan.isExpired && !isSubscriptionExpired(activePlan.expireDate);
      planTitle = activePlan.title;
    } else if (Platform.isAndroid &&
        activePlanIndex! < subscriptionPlans.length) {
      // For Android, use subscription plans
      final activePlan = subscriptionPlans[activePlanIndex!];
      formattedExpiryDate = formatExpiryDate(activePlan.expireDate);
      isCanceledButActive =
          activePlan.isExpired && !isSubscriptionExpired(activePlan.expireDate);
      planTitle = activePlan.title;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isCanceledButActive ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCanceledButActive
              ? Colors.orange.shade300
              : Colors.green.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isCanceledButActive
                        ? Icons.info_outline
                        : Icons.check_circle,
                    color: isCanceledButActive
                        ? Colors.orange.shade700
                        : Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCanceledButActive
                        ? 'Canceled Subscription'
                        : 'Active Subscription',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isCanceledButActive
                ? 'Your $planTitle subscription has been canceled.'
                : 'You are currently subscribed to the $planTitle plan.',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isCanceledButActive
                ? 'Your premium features will remain active until the expiry date.'
                : 'Your verified badge is active and all premium features are unlocked.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.event_available,
                color: isCanceledButActive
                    ? Colors.orange.shade700
                    : Colors.blue.shade700,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                isCanceledButActive
                    ? 'Access until: $formattedExpiryDate'
                    : 'Valid until: $formattedExpiryDate',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isCanceledButActive
                      ? Colors.orange.shade800
                      : Colors.blue.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSubscriptionDetails() {
    if (activePlanIndex == null ||
        activePlanIndex! >= subscriptionPlans.length) {
      return const SizedBox.shrink();
    }

    final perks = [
      'Your verified badge is active',
      'Increased account protection enabled',
      'Enhanced support available',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Premium Benefits',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...perks.map((text) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  child: Center(
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildActivePlanOnly() {
    if (activePlanIndex == null) {
      return const SizedBox.shrink();
    }

    bool isCanceledButActive;
    String expireDate;

    if (Platform.isIOS && activePlanIndex! < applePlans.length) {
      // For iOS, use Apple plans
      final activePlan = applePlans[activePlanIndex!] as DynamicApplePlan;
      isCanceledButActive =
          activePlan.isExpired && !isSubscriptionExpired(activePlan.expireDate);
      expireDate = activePlan.expireDate;
    } else if (Platform.isAndroid &&
        activePlanIndex! < subscriptionPlans.length) {
      // For Android, use subscription plans
      final activePlan = subscriptionPlans[activePlanIndex!];
      isCanceledButActive =
          activePlan.isExpired && !isSubscriptionExpired(activePlan.expireDate);
      expireDate = activePlan.expireDate;
    } else {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Current Plan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Platform.isIOS && activePlanIndex! < applePlans.length
            ? _buildDynamicApplePlanCard(
                plan: applePlans[activePlanIndex!] as DynamicApplePlan,
                isSelected: false,
                isActive: true,
                onTap: () {},
              )
            : _buildSubscriptionPlanCard(
                plan: subscriptionPlans[activePlanIndex!],
                isSelected: false,
                isActive: true,
                onTap: () {},
              ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            children: [
              Icon(
                isCanceledButActive ? Icons.hourglass_top : Icons.access_time,
                size: 16,
                color: isCanceledButActive
                    ? Colors.orange.shade700
                    : Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                isCanceledButActive
                    ? 'Service ends on: ${formatExpiryDate(expireDate)}'
                    : 'Expires on: ${formatExpiryDate(expireDate)}',
                style: TextStyle(
                  fontSize: 14,
                  color: isCanceledButActive
                      ? Colors.orange.shade800
                      : Colors.grey.shade800,
                  fontWeight:
                      isCanceledButActive ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsList() {
    final benefits = [
      {
        'title': 'A verified badge',
        'description':
            'Your audience can trust that you\'re a real person sharing your real stories.'
      },
      {
        'title': 'Increased account protection',
        'description':
            'Worry less about impersonation with proactive identity monitoring.'
      },
      {
        'title': 'Enhanced support',
        'description':
            'Contact a help agent via email or chat. Support is currently available in 15 languages.'
      },
      {
        'title': 'Upgraded profile features',
        'description': 'Add a banner or cover image to your profile.'
      },
      {
        'title': 'Get exclusive stickers or gifs',
        'description':
            'Express yourself with stickers or gifs only available to Orbis Elite subscribers.'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: benefits.map((benefit) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                child: Center(
                  child: Image.asset(
                    'assets/icons/checkmark_sub.png',
                    width: 18,
                    height: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      benefit['title']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    benefit['title'] == 'Enhanced support'
                        ? _buildEnhancedSupportText(benefit['description']!)
                        : Text(
                            benefit['description']!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEnhancedSupportText(String text) {
    const String blueHighlight = "15 languages";
    final int index = text.indexOf(blueHighlight);

    if (index == -1) {
      return Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          height: 1.4,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          height: 1.4,
        ),
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: blueHighlight,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          TextSpan(text: text.substring(index + blueHighlight.length)),
        ],
      ),
    );
  }

  Widget _buildEligibilitySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
              children: const [
                TextSpan(
                  text:
                      'Orbis Elite Verified is not available for people younger than 21 years of age. ',
                ),
                TextSpan(
                  text: 'See all Orbis Elite Verified eligibility requirements',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: '.'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
              children: [
                const TextSpan(
                    text: 'Information you provide is subject to our '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Get.to(() => PpAndTcScreen(isFromPP: true));
                    },
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPlans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (Platform.isIOS) ...[
          // For iOS, show dynamic Apple plans
          ...List.generate(
            applePlans.length,
            (index) => Column(
              children: [
                _buildDynamicApplePlanCard(
                  plan: applePlans[index] as DynamicApplePlan,
                  isSelected: selectedPlanIndex == index,
                  isActive: hasActivePlan && activePlanIndex == index,
                  onTap: () {
                    setState(() {
                      selectedPlanIndex = index;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ] else ...[
          // For Android, show traditional subscription plans
          ...List.generate(
            subscriptionPlans.length,
            (index) => Column(
              children: [
                _buildSubscriptionPlanCard(
                  plan: subscriptionPlans[index],
                  isSelected: selectedPlanIndex == index,
                  isActive: hasActivePlan && activePlanIndex == index,
                  onTap: () {
                    setState(() {
                      selectedPlanIndex = index;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        privacyPolicyWidget()
      ],
    );
  }

  Widget privacyPolicyWidget() {
    return Platform.isAndroid ? _privacyPolicyAndroid() : _privacyPolicyiOS();
  }

  Widget _buildDynamicApplePlanCard({
    required DynamicApplePlan plan,
    required bool isSelected,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isActive
                    ? Colors.green
                    : (isSelected ? Colors.blue : Colors.grey.shade300),
                width: isActive || isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isActive ? Colors.green.shade50 : Colors.white,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green : Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                            imageUrl: plan.planIcon,
                            placeholder: (context, url) => loader(context),
                            errorWidget: (context, url, error) => Center(
                              child: Icon(
                                Icons.diamond,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${plan.formattedPrice} per ${plan.durationMonths} ${plan.durationMonths == 1 ? 'month' : 'months'}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            plan.description,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // if (Platform.isIOS)
                          //   Container(
                          //     margin: const EdgeInsets.only(top: 4),
                          //     padding: const EdgeInsets.symmetric(
                          //         horizontal: 6, vertical: 2),
                          //     decoration: BoxDecoration(
                          //       color: Colors.black.withOpacity(0.1),
                          //       borderRadius: BorderRadius.circular(4),
                          //     ),
                          //     child: Row(
                          //       mainAxisSize: MainAxisSize.min,
                          //       children: [
                          //         Icon(
                          //           Icons.apple,
                          //           size: 12,
                          //           color: Colors.black,
                          //         ),
                          //         const SizedBox(width: 2),
                          //         const Text(
                          //           'Apple Pay',
                          //           style: TextStyle(
                          //             fontSize: 8,
                          //             color: Colors.black,
                          //             fontWeight: FontWeight.w500,
                          //           ),
                          //         ),
                          //       ],
                          //     ),
                          //   ),
                          if (isActive)
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        plan.formattedPrice,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.green : Colors.blue,
                        ),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.blue,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(11),
                  bottomLeft: Radius.circular(11),
                ),
              ),
              child: Text(
                '${plan.durationMonths} ${plan.durationMonths == 1 ? 'Month' : 'Months'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPlanCard({
    required SubscriptionModel plan,
    required bool isSelected,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    double planPrice = double.tryParse(plan.planPrice) ?? 0;
    int cycle = int.tryParse(plan.cycle) ?? 1;
    double pricePerMonth = cycle > 0 ? planPrice / cycle : planPrice;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isActive
                    ? Colors.green
                    : (isSelected ? Colors.blue : Colors.grey.shade300),
                width: isActive || isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isActive ? Colors.green.shade50 : Colors.white,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green : Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                            imageUrl: plan.planIcon,
                            placeholder: (context, url) => loader(context),
                            errorWidget: (context, url, error) => Center(
                              child: Image.asset(
                                'assets/icons/diamond.png',
                                width: 22,
                                height: 22,
                                color: Colors.white,
                              ),
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'IDR ${pricePerMonth.toStringAsFixed(0)} per month',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            plan.planDescription ?? '',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isActive)
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        formatToIDR(plan.planPrice),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.green : Colors.blue,
                        ),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.blue,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(11),
                  bottomLeft: Radius.circular(11),
                ),
              ),
              child: Text(
                '${cycle} ${cycle == 1 ? 'Month' : 'Months'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String formatToIDR(String price) {
    try {
      double parsed = double.tryParse(price) ?? 0;
      int rounded = parsed.toInt();
      String formatted = rounded.toString();

      if (rounded >= 1000) {
        formatted = formatted.replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
      }

      return 'IDR $formatted';
    } catch (e) {
      return 'IDR 0';
    }
  }

  Widget _privacyPolicyAndroid() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          children: [
            const TextSpan(text: 'By continuing, you agree the '),
            TextSpan(
              text: 'Privacy Policy',
              style: TextStyle(
                color: Colors.blue.shade600,
                fontWeight: FontWeight.bold,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Get.to(PpAndTcScreen(isFromPP: true));
                },
            ),
            const TextSpan(
              text:
                  ' apply to your Orbis Elite Verified subscription. Cancel 24 hours before your next payment date to avoid charges. ',
            ),
            TextSpan(
              text: 'Terms of Service',
              style: TextStyle(
                color: Colors.blue.shade600,
                fontWeight: FontWeight.bold,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Get.to(PpAndTcScreen(isFromPP: false));
                },
            ),
          ],
        ),
      ),
    );
  }

  Widget _privacyPolicyiOS() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Apple Pay integration indicator - More prominent for App Store reviewers
          // if (_isApplePayAvailable && _isApplePayEnabled)
          //   Container(
          //     padding: const EdgeInsets.all(16),
          //     margin: const EdgeInsets.only(bottom: 16),
          //     decoration: BoxDecoration(
          //       color: Colors.black.withOpacity(0.08),
          //       borderRadius: BorderRadius.circular(12),
          //       border: Border.all(color: Colors.black.withOpacity(0.15)),
          //     ),
          //     child: Column(
          //       children: [
          //         Row(
          //           mainAxisAlignment: MainAxisAlignment.center,
          //           children: [
          //             Icon(
          //               Icons.apple,
          //               color: Colors.black,
          //               size: 24,
          //             ),
          //             const SizedBox(width: 8),
          //             const Text(
          //               'Apple Pay In-App Purchase',
          //               style: TextStyle(
          //                 color: Colors.black,
          //                 fontWeight: FontWeight.bold,
          //                 fontSize: 16,
          //               ),
          //             ),
          //           ],
          //         ),
          //         const SizedBox(height: 8),
          //         const Text(
          //           'Secure payments powered by Apple Pay and PassKit framework',
          //           style: TextStyle(
          //             color: Colors.black87,
          //             fontSize: 12,
          //           ),
          //           textAlign: TextAlign.center,
          //         ),
          //       ],
          //     ),
          //   ),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              children: [
                const TextSpan(
                  text:
                      'This purchase uses Apple Pay In-App Purchase and can only be used on iOS system. Payment will be charged to your iTunes account at confirmation of purchase. Subscriptions will automatically renew unless auto-renew is turned off at least 24 hours before the end of the current period. You can manage or turn off auto-renew in your Apple ID account settings any time after purchase.\n\n',
                ),
                TextSpan(
                  text: 'Terms of Use',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Get.to(PpAndTcScreen(isFromPP: false));
                    },
                ),
                const TextSpan(text: ' | '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Get.to(PpAndTcScreen(isFromPP: true));
                    },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
