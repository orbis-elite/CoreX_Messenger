import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

// Import your existing services and models
import 'package:corexchat/src/global/api_helper.dart';
import 'package:corexchat/src/global/strings.dart';
import 'package:corexchat/src/global/global.dart';
import 'package:corexchat/src/screens/subscription/subplan/sub_plan_model.dart';

class ApplePaySubscriptionService {
  static final ApplePaySubscriptionService _instance =
      ApplePaySubscriptionService._internal();
  factory ApplePaySubscriptionService() => _instance;
  ApplePaySubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final ApiHelper _apiHelper = ApiHelper();

  // Stream subscription for purchase updates
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Product IDs mapping - similar to your _kProductIds approach
  static const Map<String, String> productIds = {
    'velvet_access': 'velvet_access',
    'sapphire_pass': 'sapphire_pass',
    'golden_privilege': 'golden_privilege',
    'elite_infinity': 'elite_infinity',
  };

  // Current selected products - similar to your _kProductIds list
  List<String> _selectedProductIds = <String>[];
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  Set<String> _processedTransactions = {}; // Track processed transactions
  
  // Debug mode for testing
  bool _debugMode = false;

  bool _isAvailable = false;
  bool _purchasePending = false;
  String? _queryProductError;
  bool _isInitialized = false;

  // Track purchase timing to prevent rapid duplicates
  Map<String, DateTime> _purchaseTimestamps = {};

  // Callbacks
  VoidCallback? _onPaymentStarted;
  VoidCallback? _onPaymentCompleted;
  Function(String)? _onError;
  Function(String, String)? _onSuccess;

  // Current subscription cycle
  int _currentCycle = 1;
  String _planamount = '';

  /// Initialize Apple Pay subscription service
  Future<bool> initialize() async {
    if (!Platform.isIOS) {
      print('Apple Pay subscription only available on iOS');
      return false;
    }

    // Prevent multiple initializations
    if (_isInitialized) {
      print('DEBUG: Apple Pay service already initialized');
      return _isAvailable;
    }

    try {
      _isAvailable = await _inAppPurchase.isAvailable();
      if (!_isAvailable) {
        print('In-app purchases not available');
        return false;
      }

      // Cancel existing subscription if any
      await _subscription?.cancel();

      // Listen to purchase stream
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (error) => _handleError('Purchase stream error: $error'),
      );

      // Load all available products initially
      await _loadAllProducts();

      // Check for any pending transactions to prevent duplicate errors
      await _checkAndCompletePendingTransactions();

      _isInitialized = true;
      print('DEBUG: Apple Pay service initialized successfully');
      return true;
    } catch (e) {
      print('Error initializing Apple Pay service: $e');
      return false;
    }
  }

  /// Load all available products (similar to your initStoreInfo)
  Future<void> _loadAllProducts() async {
    try {
      // Get all product IDs - similar to your _kProductIds approach
      final Set<String> allProductIds = productIds.values.toSet();
      print('DEBUG: Attempting to load products: $allProductIds');

      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(allProductIds.toSet());

      print('DEBUG: Product query response:');
      print('DEBUG: - Found products: ${response.productDetails.length}');
      print('DEBUG: - Not found IDs: ${response.notFoundIDs}');
      print('DEBUG: - Error: ${response.error}');

      if (response.notFoundIDs.isNotEmpty) {
        print(
            'WARN: Products not found in App Store Connect: ${response.notFoundIDs}');
      }

      if (response.error != null) {
        _queryProductError = response.error!.message;
        print('ERROR: Query product error: $_queryProductError');
      }

      _products = response.productDetails;

      // Print details of loaded products
      for (var product in _products) {
        print(
            'DEBUG: Loaded product: ${product.id} - ${product.title} - ${product.price}');
      }

      print('DEBUG: Total loaded ${_products.length} products');
    } catch (e) {
      print('ERROR: Exception loading products: $e');
      _queryProductError = 'Failed to load products: $e';
    }
  }

  /// Set selected product for purchase (similar to your _kProductIds approach)
  void setSelectedProduct(String planId) {
    String productId;

    // Check if planId is already a product ID (for iOS direct mapping)
    if (productIds.containsValue(planId)) {
      productId = planId;
    } else {
      // Use the mapping for plan ID to product ID
      productId = productIds[planId] ?? planId;
    }

    if (productId.isNotEmpty) {
      // Update _selectedProductIds similar to your _kProductIds
      _selectedProductIds = <String>[productId];
      print('DEBUG: Selected product ID: $productId for plan: $planId');
    } else {
      print('ERROR: No product ID found for plan: $planId');
      _selectedProductIds = <String>[];
    }
  }

  /// Get product details for a specific plan
  ProductDetails? getProductForPlan(String planId) {
    print('DEBUG: Looking for plan ID: $planId');

    String productId;

    // Check if planId is already a product ID (for iOS direct mapping)
    if (productIds.containsValue(planId)) {
      productId = planId;
    } else {
      // Use the mapping for plan ID to product ID
      productId = productIds[planId] ?? planId;
    }

    print('DEBUG: Mapped product ID: $productId');

    if (productId.isEmpty) {
      print('ERROR: No product ID found for plan: $planId');
      return null;
    }

    print('DEBUG: Available products: ${_products.map((p) => p.id).toList()}');

    try {
      final product =
          _products.firstWhere((product) => product.id == productId);
      print('DEBUG: Found product: ${product.id} - ${product.title}');
      return product;
    } catch (e) {
      print('ERROR: Product not found in loaded products: $productId');
      return null;
    }
  }

  /// Check if Apple Pay subscription is available
  bool get isAvailable => _isAvailable && Platform.isIOS;

  /// Check if Apple Pay service is properly initialized with products
  bool get isInitializedWithProducts => _isInitialized && _products.isNotEmpty;

  /// Get all available products
  List<ProductDetails> get availableProducts => _products;

  /// Check if purchase is pending
  bool get isPurchasePending => _purchasePending;

  /// Get query error if any
  String? get queryError => _queryProductError;

  /// Purchase a subscription (similar to your purchase flow)
  Future<bool> purchaseSubscription({
    required String amount,
    required String planId,
    required BuildContext context,
    required String cycle, // Dynamic cycle from SubscriptionModel
    VoidCallback? onPaymentStarted,
    VoidCallback? onPaymentCompleted,
    Function(String)? onError,
    Function(String, String)? onSuccess,
  }) async {
    if (!_isAvailable) {
      onError?.call('Apple Pay subscriptions not available');
      return false;
    }

    // Set the selected product (similar to your _kProductIds approach)
    setSelectedProduct(planId);

    if (_selectedProductIds.isEmpty) {
      onError?.call(
          'No subscription products available. Please ensure products are configured in App Store Connect.');
      return false;
    }

    final product = getProductForPlan(planId);
    if (product == null) {
      onError?.call(
          'Product not found for plan: $planId. Please check App Store Connect configuration.');
      return false;
    }

    // Set callbacks and convert cycle to int
    _onPaymentStarted = onPaymentStarted;
    _onPaymentCompleted = onPaymentCompleted;
    _onError = onError;
    _onSuccess = onSuccess;
    _currentCycle = int.parse(cycle);
    _planamount = amount;

    try {
      // Check for existing pending transactions for this product
      PurchaseDetails? existingPendingTransaction;
      try {
        existingPendingTransaction = _purchases.firstWhere(
          (purchase) => purchase.productID == product.id && purchase.pendingCompletePurchase,
        );
      } catch (e) {
        // No matching transaction found, which is expected
        existingPendingTransaction = null;
      }

      if (existingPendingTransaction != null) {
        print('DEBUG: Found existing pending transaction for ${product.id}, completing it first');
        await _inAppPurchase.completePurchase(existingPendingTransaction);
        _purchaseTimestamps.remove(product.id);
        
        // Wait a bit before proceeding with new purchase
        await Future.delayed(Duration(milliseconds: 500));
      }

      _purchasePending = true;
      onPaymentStarted?.call();

      // Create purchase param (similar to your approach)
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: Hive.box(userdata).get(userId)?.toString(),
      );

      print('DEBUG: Initiating purchase for product: ${product.id}');

      // Use buyNonConsumable for auto-renewable subscriptions
      // Note: For Apple subscriptions, we use buyNonConsumable as it handles auto-renewable subscriptions
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!success) {
        _purchasePending = false;
        onPaymentCompleted?.call();
        onError?.call('Failed to initiate purchase');
        return false;
      }

      return true;
    } catch (e) {
      _purchasePending = false;
      onPaymentCompleted?.call();
      
      // Check if it's a duplicate product error
      if (e.toString().contains('storekit_duplicate_product_object') ||
          e.toString().contains('pending transaction')) {
        onError?.call('Purchase error: There is a pending transaction for this product. Please wait for it to complete or try again later.');
      } else {
        onError?.call('Purchase error: $e');
      }
      return false;
    }
  }

  /// Handle purchase updates from the stream (similar to your _listenToPurchaseUpdated)
  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      final transactionId = purchaseDetails.purchaseID ?? '';
      print(
          'DEBUG: Purchase status: ${purchaseDetails.status}, Transaction: $transactionId');

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _showPendingUI();
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _handleSuccessfulPurchase(purchaseDetails);
          break;
        case PurchaseStatus.error:
          _handlePurchaseError(purchaseDetails);
          break;
        case PurchaseStatus.canceled:
          _handlePurchaseCanceled(purchaseDetails);
          break;
      }
    }
  }

  /// Handle successful purchase
  void _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    final transactionId = purchaseDetails.purchaseID ?? '';
    final productId = purchaseDetails.productID;
    final now = DateTime.now();

    // Prevent multiple processing of the same transaction
    if (_processedTransactions.contains(transactionId)) {
      print('DEBUG: Transaction $transactionId already processed, skipping');
      // Still need to complete the purchase if pending
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
      return;
    }

    // Check if this product was processed recently (within last 5 seconds)
    if (_purchaseTimestamps.containsKey(productId)) {
      final lastPurchaseTime = _purchaseTimestamps[productId]!;
      if (now.difference(lastPurchaseTime).inSeconds < 5) {
        print(
            'DEBUG: Product $productId was processed recently, skipping duplicate');
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
        return;
      }
    }

    // Mark transaction as being processed IMMEDIATELY to prevent race conditions
    _processedTransactions.add(transactionId);
    _purchaseTimestamps[productId] = now;

    try {
      print(
          'DEBUG: Processing successful purchase: ${purchaseDetails.productID}, Transaction: $transactionId');

      // Add to purchases list (similar to your approach)
      _purchases.add(purchaseDetails);

      // Verify purchase with your backend (enhance this similar to your _successPayment)
      final bool verified = await _verifyPurchaseWithBackend(purchaseDetails);

      if (verified) {
        _onSuccess?.call(
          transactionId,
          purchaseDetails.productID,
        );

        Fluttertoast.showToast(
          msg: "Subscription activated successfully!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        _onError?.call('Purchase verification failed');
        // Only remove from processed set if we want to allow retry
        // For now, keep it to prevent duplicate calls even on failure
        // _processedTransactions.remove(transactionId);
      }
    } catch (e) {
      _onError?.call('Error processing purchase: $e');
      // Only remove from processed set if we want to allow retry
      // For now, keep it to prevent duplicate calls even on error
      // _processedTransactions.remove(transactionId);
    } finally {
      _purchasePending = false;
      _onPaymentCompleted?.call();

      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  /// Verify purchase with your backend using existing confirmSubscription API
  /// This method handles both production and sandbox receipts as per Apple's requirements
  Future<bool> _verifyPurchaseWithBackend(
      PurchaseDetails purchaseDetails) async {
    final transactionId = purchaseDetails.purchaseID ?? '';

    try {
      final savedToken = Hive.box(userdata).get(authToken);
      if (savedToken == null) {
        throw Exception('No auth token found');
      }

      // Find plan ID from product ID
      String? planId;
      int? subscriptionTypeId;
      for (var entry in productIds.entries) {
        if (entry.value == purchaseDetails.productID) {
          planId = entry.key;
          // Map plan ID to subscription type ID
          subscriptionTypeId = _mapPlanToSubscriptionTypeId(planId);
          break;
        }
      }

      if (planId == null || subscriptionTypeId == null) {
        throw Exception('Unknown product ID: ${purchaseDetails.productID}');
      }

      // Get receipt data for server-side validation
      String? receiptData;
      if (purchaseDetails is AppStorePurchaseDetails) {
        // For StoreKit, we need to get the receipt data differently
        receiptData = purchaseDetails.verificationData.serverVerificationData;
      }

      // Call existing confirmSubscription API with Apple Pay specific parameters
      final uri = Uri.parse('${ApiHelper.baseUrl}/confirm-subscription');

      // Prepare body data with receipt information for proper validation
      final bodyData = {
        'amount': _planamount,
        // Use Apple Pay transaction details instead of recurring_id and customer_id
        'recurring_id': transactionId, // Apple transaction ID
        'csutomer_id': purchaseDetails.productID, // Apple product ID (matches backend typo)
        'subscription_type_id': subscriptionTypeId,
        'duration_in_months': _currentCycle, // Dynamic cycle converted to int
        // Add Apple Pay specific parameters for better backend handling
        'apple_pay': true,
        'receipt_data': receiptData, // Add receipt data for validation
        'product_id': purchaseDetails.productID, // Apple product ID
        'transaction_id': transactionId, // Apple transaction ID
      };

      // Print body data before sending to backend
      print('DEBUG: Body data being sent to backend:');
      print('DEBUG: ${jsonEncode(bodyData)}');

      // First attempt: Try production validation (recommended Apple approach)
      var response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $savedToken',
        },
        body: jsonEncode({
          ...bodyData,
          'environment': 'production', // Specify production environment
        }),
      );

      print(
          'DEBUG: confirmSubscription API response status: ${response.statusCode}');
      print('DEBUG: confirmSubscription API response body: ${response.body}');

      // If production validation fails, check if it's a sandbox receipt
      // This follows Apple's recommended approach: always try production first
      if (response.statusCode != 200) {
        try {
          final responseData = jsonDecode(response.body);
          
          // Check for various sandbox receipt indicators
          bool isSandboxReceipt = false;
          
          if (responseData['error'] != null) {
            final errorString = responseData['error'].toString();
            // Error 21007 means sandbox receipt used in production
            // Also check for other sandbox-related errors
            if (errorString.contains('21007') || 
                errorString.contains('sandbox') ||
                errorString.contains('Sandbox receipt used in production')) {
              isSandboxReceipt = true;
            }
          }
          
          // Also check response message for sandbox indicators
          if (responseData['message'] != null) {
            final messageString = responseData['message'].toString().toLowerCase();
            if (messageString.contains('sandbox') || 
                messageString.contains('test environment')) {
              isSandboxReceipt = true;
            }
          }
          
          if (isSandboxReceipt) {
            print(
                'DEBUG: Sandbox receipt detected (error: ${responseData['error']}), retrying with sandbox environment');

            // Second attempt: Try sandbox validation
            response = await http.post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $savedToken',
              },
              body: jsonEncode({
                ...bodyData,
                'environment': 'sandbox', // Specify sandbox environment
              }),
            );

            print(
                'DEBUG: Sandbox retry response status: ${response.statusCode}');
            print('DEBUG: Sandbox retry response body: ${response.body}');
          }
        } catch (e) {
          print('DEBUG: Error parsing response for sandbox retry: $e');
        }
      }

      if (response.statusCode == 200) {
        // Based on existing PaymentService, return true for 200 status
        return true;
      } else {
        print('Backend verification failed: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error verifying purchase: $e');
      return false;
    }
  }

  /// Map plan ID to subscription type ID
  int _mapPlanToSubscriptionTypeId(String planId) {
    switch (planId) {
      case 'velvet_access':
        return 7; // Match the subscription type IDs from sub_plan.dart
      case 'sapphire_pass':
        return 8;
      case 'golden_privilege':
        return 9;
      case 'elite_infinity':
        return 10;
      default:
        return 7; // Default subscription type
    }
  }

  /// Handle purchase error
  void _handlePurchaseError(PurchaseDetails purchaseDetails) {
    _purchasePending = false;
    _onPaymentCompleted?.call();

    final errorMessage =
        purchaseDetails.error?.message ?? 'Unknown purchase error';
    
    // Check for specific duplicate product object error
    if (errorMessage.contains('storekit_duplicate_product_object') || 
        errorMessage.contains('pending transaction for the same product')) {
      _onError?.call('Purchase error: There is a pending transaction for this product. Please wait for it to complete or try again later.');
      
      // Try to complete any pending transactions for this product
      _completePendingTransactionsForProduct(purchaseDetails.productID);
    } else {
      _onError?.call('Purchase error: $errorMessage');
    }

    if (purchaseDetails.pendingCompletePurchase) {
      _inAppPurchase.completePurchase(purchaseDetails);
    }
  }

  /// Handle purchase cancellation
  void _handlePurchaseCanceled(PurchaseDetails purchaseDetails) {
    _purchasePending = false;
    _onPaymentCompleted?.call();

    Fluttertoast.showToast(
      msg: "Purchase canceled",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    );

    if (purchaseDetails.pendingCompletePurchase) {
      _inAppPurchase.completePurchase(purchaseDetails);
    }
  }

  /// Complete pending transactions for a specific product to avoid duplicate errors
  void _completePendingTransactionsForProduct(String productId) async {
    try {
      print('DEBUG: Attempting to complete pending transactions for product: $productId');
      
      // Find and complete any pending transactions for this product
      final pendingTransactions = _purchases.where((purchase) => 
        purchase.productID == productId && 
        purchase.pendingCompletePurchase
      ).toList();
      
      for (final transaction in pendingTransactions) {
        print('DEBUG: Completing pending transaction: ${transaction.purchaseID}');
        await _inAppPurchase.completePurchase(transaction);
      }
      
      // Clear the product from timestamps to allow new purchase
      _purchaseTimestamps.remove(productId);
      
      print('DEBUG: Completed ${pendingTransactions.length} pending transactions for $productId');
    } catch (e) {
      print('ERROR: Failed to complete pending transactions for $productId: $e');
    }
  }

  /// Show pending UI
  void _showPendingUI() {
    print('Purchase pending...');
  }

  /// Get current selected product IDs (similar to your _kProductIds)
  List<String> get selectedProductIds => _selectedProductIds;

  /// Restore purchases
  Future<void> restorePurchases({
    VoidCallback? onRestoreStarted,
    VoidCallback? onRestoreCompleted,
    Function(String)? onError,
  }) async {
    if (!_isAvailable) {
      onError?.call('Apple Pay subscriptions not available');
      return;
    }

    try {
      onRestoreStarted?.call();
      await _inAppPurchase.restorePurchases();
      onRestoreCompleted?.call();
    } catch (e) {
      onRestoreCompleted?.call();
      onError?.call('Restore error: $e');
    }
  }

  /// Get subscription status
  Future<Map<String, dynamic>?> getSubscriptionStatus() async {
    try {
      final savedToken = Hive.box(userdata).get(authToken);
      if (savedToken == null) return null;

      final uri = Uri.parse('${ApiHelper.baseUrl}/apple-subscription-status');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $savedToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error getting subscription status: $e');
    }
    return null;
  }

  /// Cancel subscription (redirect to App Store)
  Future<void> cancelSubscription() async {
    if (!Platform.isIOS) return;

    try {
      Fluttertoast.showToast(
        msg: "Opening App Store subscription management...",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );

      _showCancelInstructions();
    } catch (e) {
      print('Error canceling subscription: $e');
    }
  }

  /// Show cancel instructions dialog
  void _showCancelInstructions() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'To cancel your subscription:\n\n'
          '1. Go to Settings on your device\n'
          '2. Tap your name at the top\n'
          '3. Tap Subscriptions\n'
          '4. Find Orbis Elite Verified\n'
          '5. Tap Cancel Subscription',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  /// Handle app lifecycle for purchase restoration
  void handleAppLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingPurchases();
    }
  }

  /// Check for pending purchases
  void _checkPendingPurchases() async {
    try {
      final bool available = await _inAppPurchase.isAvailable();
      if (available) {
        print('Checking for pending purchases...');
        await _checkAndCompletePendingTransactions();
      }
    } catch (e) {
      print('Error checking pending purchases: $e');
    }
  }

  /// Check for and complete any pending transactions to prevent duplicate errors
  Future<void> _checkAndCompletePendingTransactions() async {
    try {
      print('DEBUG: Checking for pending transactions...');
      
      // Get all pending transactions
      final pendingTransactions = _purchases.where((purchase) => 
        purchase.pendingCompletePurchase
      ).toList();
      
      if (pendingTransactions.isNotEmpty) {
        print('DEBUG: Found ${pendingTransactions.length} pending transactions');
        
        for (final transaction in pendingTransactions) {
          print('DEBUG: Completing pending transaction: ${transaction.purchaseID} for product: ${transaction.productID}');
          await _inAppPurchase.completePurchase(transaction);
          
          // Clear from timestamps to allow new purchases
          _purchaseTimestamps.remove(transaction.productID);
        }
        
        print('DEBUG: Completed all pending transactions');
      } else {
        print('DEBUG: No pending transactions found');
      }
    } catch (e) {
      print('ERROR: Failed to check/complete pending transactions: $e');
    }
  }

  /// Handle errors
  void _handleError(String error) {
    print('Apple Pay Subscription Error: $error');
    _onError?.call(error);
  }

  /// Clear processed transactions (useful for testing or when starting fresh)
  void clearProcessedTransactions() {
    _processedTransactions.clear();
    _purchaseTimestamps.clear();
    print('DEBUG: Cleared processed transactions and timestamps');
  }

  /// Reset service for testing or troubleshooting
  void resetService() {
    _subscription?.cancel();
    _subscription = null;
    _processedTransactions.clear();
    _purchaseTimestamps.clear();
    _isInitialized = false;
    _isAvailable = false;
    _purchasePending = false;
    _queryProductError = null;
    print('DEBUG: Apple Pay service reset');
  }
  
  /// Enable debug mode for testing
  void enableDebugMode() {
    _debugMode = true;
    print('DEBUG: Apple Pay debug mode enabled');
  }
  
  /// Disable debug mode
  void disableDebugMode() {
    _debugMode = false;
    print('DEBUG: Apple Pay debug mode disabled');
  }
  
  /// Check if debug mode is enabled
  bool get isDebugMode => _debugMode;

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _processedTransactions.clear();
    _purchaseTimestamps.clear();
    _isInitialized = false;
    print('DEBUG: Apple Pay service disposed');
  }
}
