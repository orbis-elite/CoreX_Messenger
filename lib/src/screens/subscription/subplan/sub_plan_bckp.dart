// import 'dart:convert';
// import 'dart:io';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:corexchat/Models/user_profile_model.dart';
// import 'package:corexchat/src/global/api_helper.dart';
// import 'package:corexchat/src/global/strings.dart';
// import 'package:corexchat/src/screens/apple_pay/apple_service.dart';
// import 'package:corexchat/src/screens/subscription/badge_model.dart';
// import 'package:corexchat/src/screens/subscription/stpper_widget.dart';
// import 'package:corexchat/src/screens/user/pp_and_tc_screen.dart';
// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:corexchat/src/global/global.dart';
// import 'package:corexchat/src/screens/layout/bottombar.dart';
// import 'package:corexchat/src/screens/subscription/payment/services/payment_service.dart';
// import 'package:corexchat/src/screens/subscription/subplan/sub_plan_model.dart';
// import 'package:corexchat/src/screens/subscription/subplan/services/sub_service.dart';
// import 'package:flutter/services.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:get/get.dart';
// import 'package:get/get_core/src/get_main.dart';
// import 'package:hive/hive.dart';
// import 'package:http/http.dart' as http;

// class SubscriptionScreen extends StatefulWidget {
//   const SubscriptionScreen({Key? key}) : super(key: key);

//   @override
//   State<SubscriptionScreen> createState() => _SubscriptionScreenState();
// }

// class _SubscriptionScreenState extends State<SubscriptionScreen> {
//   List<SubscriptionModel> subscriptionPlans = [];
//   bool isLoading = true;
//   bool isProcessingPayment = false;
//   String errorMessage = '';
//   int? selectedPlanIndex = 0;
//   bool hasActivePlan = false;
//   bool hasCancelled = false;
//   int? activePlanIndex;

//   // Current step in the subscription flow
//   int currentStep = 1;

//   BadgeModel? purchasedBadge;
//   String cheapestPlanPrice = 'IDR1';
//   bool isInitializing = true;

//   //apple pay
//   // Add these new variables for Apple Pay
//   late ApplePaySubscriptionService _applePayService;
//   bool _isApplePayAvailable = false;
//   bool _showPaymentOptions = false;
//   String? _selectedPaymentMethod; // 'xendit' or 'apple_pay'

//   @override
//   void initState() {
//     super.initState();
//     _initializeApplePay();
//     _initializeData();
//   }

//   Future<void> _initializeApplePay() async {
//     _applePayService = ApplePaySubscriptionService();
//     if (Platform.isIOS) {
//       _isApplePayAvailable = await _applePayService.initialize();
//       if (mounted) {
//         setState(() {});
//       }
//     }
//   }

//   Future<void> _initializeData() async {
//     print("DEBUG: _initializeData started");

//     setState(() {
//       isInitializing = true;
//       // Initialize hasCancelled to false by default
//       hasCancelled = false;
//     });

//     try {
//       // Load badge data first
//       purchasedBadge = await SubscriptionService.getPurchasedBadge();
//       print("DEBUG: Purchased badge loaded: ${purchasedBadge != null}");

//       // Get cheapest plan price
//       cheapestPlanPrice = await SubscriptionService.getCheapestPlanPrice();
//       print("DEBUG: Cheapest plan price: $cheapestPlanPrice");

//       // Then fetch subscription plans - this will set hasCancelled if needed
//       await _fetchSubscriptionPlans();
//       print(
//           "DEBUG: After _fetchSubscriptionPlans: hasActivePlan=$hasActivePlan, hasCancelled=$hasCancelled");
//     } catch (e) {
//       print('ERROR in initialization: $e');
//       setState(() {
//         errorMessage = 'Failed to load subscription data. Please try again.';
//       });
//     } finally {
//       setState(() {
//         isInitializing = false;
//         // Print final state
//         print(
//             "DEBUG: _initializeData complete: hasActivePlan=$hasActivePlan, hasCancelled=$hasCancelled, currentStep=$currentStep");
//       });
//     }
//   }

//   Future<void> _fetchSubscriptionPlans() async {
//     try {
//       setState(() {
//         isLoading = true;
//         errorMessage = '';
//       });

//       final plans = await SubscriptionService.fetchSubscriptionPlans();

//       // Variables to track plan status
//       int? activeIndex;
//       bool foundCancelledPlan = false;

//       // Debug the received plans
//       print("DEBUG: Received ${plans.length} subscription plans");

//       // First pass: Check if there's any subscribed plan with a future expiry date
//       for (int i = 0; i < plans.length; i++) {
//         // If the plan is subscribed and the expiry date is in the future
//         if (plans[i].isSubscribed &&
//             !isSubscriptionExpired(plans[i].expireDate)) {
//           print(
//               "DEBUG: Found valid subscription at index $i (${plans[i].title}), expire_date is in the future");

//           // This plan is active because expire_date is in the future
//           activeIndex = i;

//           // Check if it's canceled (is_expired=true) or regular active (is_expired=false)
//           if (plans[i].isExpired) {
//             print(
//                 "DEBUG: This plan is canceled but still valid until expire_date");
//             foundCancelledPlan = true;
//           } else {
//             print("DEBUG: This is a regular active plan");
//           }

//           break;
//         }
//       }

//       // Second pass: If no active plan with future expiry date, check for canceled and expired plans
//       if (activeIndex == null) {
//         for (int i = 0; i < plans.length; i++) {
//           if (plans[i].isSubscribed && plans[i].isExpired) {
//             print(
//                 "DEBUG: Found canceled and expired subscription at index $i (${plans[i].title})");
//             foundCancelledPlan = true;
//             break;
//           }
//         }
//       }

//       setState(() {
//         subscriptionPlans = plans;
//         isLoading = false;
//         hasCancelled = foundCancelledPlan;

//         // If there's a plan with future expiry date, show it as active
//         if (activeIndex != null) {
//           activePlanIndex = activeIndex;
//           hasActivePlan = true;
//           selectedPlanIndex = null;
//           currentStep = 3;

//           print(
//               "DEBUG: Setting hasActivePlan=true because a plan with future expire_date exists");
//           if (plans[activeIndex].isExpired) {
//             print(
//                 "DEBUG: This active plan is marked as canceled in the backend");
//           }
//         } else {
//           // No active plan (all are either not subscribed or expired)
//           hasActivePlan = false;
//           activePlanIndex = null;
//           selectedPlanIndex = 0; // Default select first plan
//           currentStep = 1;
//           print(
//               "DEBUG: No active plan with future expire_date - hasActivePlan=false");
//         }
//       });
//     } catch (e) {
//       print("ERROR in _fetchSubscriptionPlans: $e");
//       setState(() {
//         errorMessage = 'Failed to load subscription plans. Please try again.';
//         isLoading = false;
//       });
//     }
//   }

//   void _debugSubscriptionPlans() {
//     print("DEBUG: Subscription Plans Data");
//     print("-------------------------------");
//     print("Total Plans: ${subscriptionPlans.length}");
//     print("hasActivePlan: $hasActivePlan");
//     print("hasCancelled: $hasCancelled");
//     print("activePlanIndex: $activePlanIndex");
//     print("selectedPlanIndex: $selectedPlanIndex");

//     for (int i = 0; i < subscriptionPlans.length; i++) {
//       final plan = subscriptionPlans[i];
//       print("Plan #$i: ${plan.title}");
//       print("  - subscribed: ${plan.isSubscribed}");
//       print("  - is_expired (canceled): ${plan.isExpired}");
//       print("  - expire_date: ${plan.expireDate}");
//       print("  - date expired: ${isSubscriptionExpired(plan.expireDate)}");

//       // Check if this plan should be considered canceled
//       if (plan.isSubscribed && plan.isExpired) {
//         print("  >>> This plan is CANCELED <<<");
//       }
//       // Check if this plan should be considered active
//       if (plan.isSubscribed &&
//           !plan.isExpired &&
//           !isSubscriptionExpired(plan.expireDate)) {
//         print("  >>> This plan is ACTIVE <<<");
//       }
//       // Check if this plan is date-expired but not canceled
//       if (plan.isSubscribed &&
//           !plan.isExpired &&
//           isSubscriptionExpired(plan.expireDate)) {
//         print("  >>> This plan is DATE EXPIRED <<<");
//       }
//     }
//     print("-------------------------------");
//   }

//   // Method to go to next step
//   void _nextStep() {
//     setState(() {
//       currentStep++;
//     });
//   }

//   // Method to go to previous step
//   void _previousStep() {
//     setState(() {
//       if (currentStep > 1) {
//         currentStep--;
//       }
//     });
//   }

//   bool isSubscriptionExpired(String expiryDateString) {
//     try {
//       // First check if the string is empty or invalid
//       if (expiryDateString.isEmpty) {
//         return true; // Consider empty date as expired
//       }

//       // Parse the expiry date
//       DateTime expiryDate = DateTime.parse(expiryDateString);

//       // Get today's date (without time)
//       DateTime today = DateTime.now();
//       DateTime todayWithoutTime = DateTime(today.year, today.month, today.day);

//       // Compare dates
//       return todayWithoutTime.isAfter(expiryDate);
//     } catch (e) {
//       print("Error parsing expiry date: $e");
//       return true; // Default to expired if there's a parsing error
//     }
//   }

//   String formatExpiryDate(String dateString) {
//     try {
//       final DateTime date = DateTime.parse(dateString);
//       final List<String> months = [
//         'January',
//         'February',
//         'March',
//         'April',
//         'May',
//         'June',
//         'July',
//         'August',
//         'September',
//         'October',
//         'November',
//         'December'
//       ];
//       return '${date.day} ${months[date.month - 1]}, ${date.year}';
//     } catch (e) {
//       print("Error formatting date: $e");
//       return dateString; // Return original string if parsing fails
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Determine if we have a canceled but still active plan
//     bool hasCanceledActivePlan = false;

//     if (activePlanIndex != null &&
//         activePlanIndex! < subscriptionPlans.length) {
//       SubscriptionModel activePlan = subscriptionPlans[activePlanIndex!];
//       hasCanceledActivePlan =
//           activePlan.isExpired && !isSubscriptionExpired(activePlan.expireDate);
//     }

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               _buildHeader(context),
//               // Add the stepper widget right below the header
//               SubscriptionStepper(currentStep: hasActivePlan ? 3 : currentStep),

//               Expanded(
//                 child: isLoading
//                     ? Center(child: loader(context))
//                     : errorMessage.isNotEmpty
//                         ? _buildErrorView()
//                         : _buildContent(),
//               ),

//               // Bottom button logic
//               if (!hasActivePlan)
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 24.0, vertical: 16.0),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.05),
//                         spreadRadius: 1,
//                         blurRadius: 10,
//                         offset: const Offset(0, -3),
//                       ),
//                     ],
//                   ),
//                   child: _buildBottomButton(),
//                 ),

//               // For active plans, show either cancel button or resubscribe button
//               if (hasActivePlan && !hasCanceledActivePlan)
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 24.0, vertical: 16.0),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.05),
//                         spreadRadius: 1,
//                         blurRadius: 10,
//                         offset: const Offset(0, -3),
//                       ),
//                     ],
//                   ),
//                   child: hasCanceledActivePlan
//                       ? _buildResubscribeButton() // For canceled but active plans
//                       : _buildCancelButton(), // For regular active plans
//                 ),
//             ],
//           ),
//           // Full-screen loading overlay for payment processing
//           if (isProcessingPayment)
//             Container(
//               color: Colors.black.withOpacity(0.3),
//               child: Center(
//                 child: loader(context),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildResubscribeButton() {
//     return Container(
//       width: double.infinity,
//       height: 50,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(25),
//         gradient: LinearGradient(
//           colors: [Colors.blue, Colors.blue.shade700],
//           begin: Alignment.centerLeft,
//           end: Alignment.centerRight,
//         ),
//       ),
//       child: TextButton(
//         onPressed: () {
//           // Navigate to plan selection screen
//           setState(() {
//             hasActivePlan =
//                 false; // Temporarily set to false to show plan selection
//             selectedPlanIndex = 0;
//             currentStep = 2; // Go directly to plan selection
//           });
//         },
//         child: const Text(
//           'Subscribe Again',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStepContent() {
//     switch (currentStep) {
//       case 1:
//         return _buildStep1Content();
//       case 2:
//         return _buildStep2Content();
//       default:
//         return _buildStep1Content();
//     }
//   }

//   Widget _buildCancelledContent() {
//     return Scrollbar(
//       thickness: 6,
//       radius: const Radius.circular(10),
//       thumbVisibility: true,
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 20),
//                 // Show the cancelled plan notification
//                 _buildCanceledPlanNotification(),
//                 const SizedBox(height: 24),

//                 // Continue with regular content
//                 Text(
//                   'Starting at just ${cheapestPlanPrice}/month',
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     height: 1.2,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 30),

//                 // Show user profile
//                 _buildUserProfile(),

//                 const SizedBox(height: 30),

//                 // Show benefits
//                 Align(
//                   alignment: Alignment.centerLeft,
//                   child: Column(
//                     children: [
//                       _buildBenefitsList(),
//                       _buildEligibilitySection()
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 80),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildUserProfile() {
//     return Column(
//       children: [
//         // User profile picture with badge
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Stack(
//               children: [
//                 // Profile picture
//                 Container(
//                   height: 90,
//                   width: 90,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(45),
//                     border: Border.all(color: Colors.white, width: 3),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.15),
//                         blurRadius: 10,
//                         spreadRadius: 0,
//                         offset: const Offset(0, 3),
//                       ),
//                     ],
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(45),
//                     child: Hive.box(userdata).get(userImage) != null &&
//                             Hive.box(userdata)
//                                 .get(userImage)
//                                 .toString()
//                                 .isNotEmpty
//                         ? CachedNetworkImage(
//                             imageUrl: Hive.box(userdata).get(userImage),
//                             fit: BoxFit.cover,
//                             placeholder: (context, url) => loader(context),
//                             errorWidget: (context, url, error) => Image.asset(
//                               "assets/images/user_placeholder.png",
//                               fit: BoxFit.cover,
//                             ),
//                           )
//                         : Image.asset(
//                             "assets/images/user_placeholder.png",
//                             fit: BoxFit.cover,
//                           ),
//                   ),
//                 ),

//                 // Badge
//                 Positioned(
//                     right: 0,
//                     bottom: 0,
//                     child: Image.asset(
//                       "assets/icons/Nobg_qr.png",
//                       height: 24,
//                       width: 24,
//                     ))
//               ],
//             ),
//           ],
//         ),

//         const SizedBox(height: 16),

//         // Username with badge
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               Hive.box(userdata).get(userName) ?? "User",
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 20,
//                 letterSpacing: 0.2,
//               ),
//             ),
//             SizedBox(width: 5),
//             purchasedBadge != null && purchasedBadge!.logo.isNotEmpty
//                 ? Container(
//                     width: 24,
//                     height: 24,
//                     child: CachedNetworkImage(
//                       imageUrl: purchasedBadge!.logo,
//                       fit: BoxFit.contain,
//                       placeholder: (context, url) => const SizedBox(),
//                       errorWidget: (context, url, error) => Container(
//                         decoration: BoxDecoration(
//                           color: Colors.blue,
//                           shape: BoxShape.circle,
//                           border: Border.all(color: Colors.white, width: 2),
//                         ),
//                         padding: const EdgeInsets.all(3),
//                         child: const Icon(
//                           Icons.check,
//                           color: Colors.white,
//                           size: 12,
//                         ),
//                       ),
//                     ),
//                   )
//                 : SizedBox()
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildCancelButton() {
//     return Container(
//       width: double.infinity,
//       height: 50,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(25),
//         color: Colors.red.shade50,
//         border: Border.all(color: Colors.red.shade300),
//       ),
//       child: TextButton(
//         onPressed: _showCancellationConfirmDialog,
//         child: Text(
//           'Cancel Subscription',
//           style: TextStyle(
//             color: Colors.red.shade700,
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }

//   void _showCancellationConfirmDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           backgroundColor: appColorWhite,
//           title: const Text('Cancel Subscription'),
//           content: const Text(
//             'Are you sure you want to cancel your subscription? Your verified badge and premium benefits will be removed.',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close dialog
//               },
//               child: const Text('No, Keep It'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close dialog
//                 cancelSubscription(); // Call the API
//               },
//               style: TextButton.styleFrom(
//                 foregroundColor: Colors.red,
//               ),
//               child: const Text('Yes, Cancel'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildErrorView() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.error_outline, size: 48, color: Colors.red),
//           const SizedBox(height: 16),
//           Text(
//             errorMessage,
//             textAlign: TextAlign.center,
//             style: const TextStyle(fontSize: 16),
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton(
//             onPressed: _fetchSubscriptionPlans,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue.shade50,
//               foregroundColor: Colors.blue,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//             ),
//             child: const Text('Try Again'),
//           ),
//           const SizedBox(height: 80),
//         ],
//       ),
//     );
//   }

//   Widget _buildContent() {
//     print(
//         "DEBUG: _buildContent() called with hasActivePlan=$hasActivePlan, hasCancelled=$hasCancelled, currentStep=$currentStep");

//     // CASE 1: User has an active plan (including canceled but still valid plans)
//     if (hasActivePlan) {
//       // If we have an active plan index and it's valid
//       if (activePlanIndex != null &&
//           activePlanIndex! < subscriptionPlans.length) {
//         final activePlan = subscriptionPlans[activePlanIndex!];

//         // Check if this is a canceled but still active plan
//         if (activePlan.isExpired &&
//             !isSubscriptionExpired(activePlan.expireDate)) {
//           print("DEBUG: Showing active but canceled plan");
//         } else {
//           print("DEBUG: Showing fully active plan");
//         }
//       }

//       return _buildActivePlanContent();
//     }

//     // CASE 2: User has a canceled and expired plan - show step content with cancel notice
//     if (hasCancelled) {
//       print("DEBUG: User has a canceled and expired plan");
//       return _buildCancelledContent();
//     }

//     // CASE 3: User has no subscription at all - show regular step content
//     print("DEBUG: Showing regular step content for step $currentStep");
//     return _buildStepContent();
//   }

//   Widget _wrapWithCanceledNotification(Widget content) {
//     // Find the canceled plan
//     SubscriptionModel? canceledPlan;
//     for (var plan in subscriptionPlans) {
//       if (plan.isSubscribed && plan.isExpired) {
//         canceledPlan = plan;
//         break;
//       }
//     }

//     if (canceledPlan == null) {
//       print("DEBUG: No canceled plan found despite hasCancelled=true");
//       return content;
//     }

//     print("DEBUG: Found canceled plan: ${canceledPlan.title}");

//     // Create a column with the notification at the top and the content below
//     return Scrollbar(
//       thickness: 6,
//       radius: const Radius.circular(10),
//       thumbVisibility: true,
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 20),
//                 _buildExplicitCanceledPlanNotification(canceledPlan),
//                 const SizedBox(height: 16),
//                 if (content is Scrollbar)
//                   // Extract the content from nested Scrollbar
//                   ..._extractContentFromScrollbar(content)
//                 else
//                   content,
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   List<Widget> _extractContentFromScrollbar(Scrollbar scrollbar) {
//     // This is a simplification - in real code you'd need more robust handling
//     // Assuming the Scrollbar contains a Padding with a SingleChildScrollView with a Padding with a Column
//     try {
//       if (scrollbar.child is Padding &&
//           (scrollbar.child as Padding).child is SingleChildScrollView &&
//           ((scrollbar.child as Padding).child as SingleChildScrollView).child
//               is Padding &&
//           (((scrollbar.child as Padding).child as SingleChildScrollView).child
//                   as Padding)
//               .child is Column) {
//         final column =
//             (((scrollbar.child as Padding).child as SingleChildScrollView).child
//                     as Padding)
//                 .child as Column;
//         return column.children;
//       }
//     } catch (e) {
//       print("DEBUG: Error extracting content from Scrollbar: $e");
//     }

//     // Fallback case
//     return [scrollbar];
//   }

// // Explicit widget for canceled plan notification
//   Widget _buildExplicitCanceledPlanNotification(
//       SubscriptionModel canceledPlan) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.orange.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.orange.shade300),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.cancel_outlined, color: Colors.orange.shade700),
//               const SizedBox(width: 8),
//               const Text(
//                 'Subscription Cancelled',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                   color: Colors.black,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Your ${canceledPlan.title} subscription has been cancelled.',
//             style: const TextStyle(
//               fontSize: 14,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'Your verified badge and premium features are no longer active.',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey.shade700,
//             ),
//           ),
//           const SizedBox(height: 12),
//           ElevatedButton(
//             onPressed: () {
//               setState(() {
//                 hasActivePlan = false;
//                 activePlanIndex = null;
//                 selectedPlanIndex = 0;
//                 currentStep = 2; // Go directly to plan selection
//               });
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.orange.shade600,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//             ),
//             child: const Text(
//               'Subscribe Again',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActivePlanContent() {
//     return Scrollbar(
//       thickness: 6,
//       radius: const Radius.circular(10),
//       thumbVisibility: true,
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 20),
//                 _buildTitle(),
//                 const SizedBox(height: 16),
//                 _buildActivePlanInfo(),
//                 const SizedBox(height: 24),
//                 _buildActiveSubscriptionDetails(),
//                 const SizedBox(height: 24),
//                 _buildActivePlanOnly(),
//                 const SizedBox(height: 80),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStep1Content() {
//     print("DEBUG: _buildStep1Content called with hasCancelled=$hasCancelled");

//     return Scrollbar(
//       thickness: 6,
//       radius: const Radius.circular(10),
//       thumbVisibility: true,
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 const SizedBox(height: 20),

//                 // Always check for canceled plan first
//                 if (hasCancelled) _buildCanceledPlanNotification(),

//                 // // Then check for expired plan (which is different from canceled)
//                 // if (!hasCancelled) _buildExpiredPlanNotification(),

//                 Text(
//                   'Starting at just ${cheapestPlanPrice}/month',
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     height: 1.2,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 30),

//                 // Improved PROFILE SECTION with better spacing and alignment
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     // User profile picture with badge
//                     Stack(
//                       children: [
//                         // Profile picture
//                         Container(
//                           height: 90,
//                           width: 90,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(45),
//                             border: Border.all(color: Colors.white, width: 3),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.15),
//                                 blurRadius: 10,
//                                 spreadRadius: 0,
//                                 offset: const Offset(0, 3),
//                               ),
//                             ],
//                           ),
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.circular(45),
//                             child: Hive.box(userdata).get(userImage) != null &&
//                                     Hive.box(userdata)
//                                         .get(userImage)
//                                         .toString()
//                                         .isNotEmpty
//                                 ? CachedNetworkImage(
//                                     imageUrl: Hive.box(userdata).get(userImage),
//                                     fit: BoxFit.cover,
//                                     placeholder: (context, url) =>
//                                         loader(context),
//                                     errorWidget: (context, url, error) =>
//                                         Image.asset(
//                                       "assets/images/user_placeholder.png",
//                                       fit: BoxFit.cover,
//                                     ),
//                                   )
//                                 : Image.asset(
//                                     "assets/images/user_placeholder.png",
//                                     fit: BoxFit.cover,
//                                   ),
//                           ),
//                         ),

//                         // Badge - positioned without adding a background since badge has its own background
//                         Positioned(
//                             right: 0,
//                             bottom: 0,
//                             child: Image.asset(
//                               "assets/icons/Nobg_qr.png",
//                               height: 24,
//                               width: 24,
//                             ))
//                       ],
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 16),

//                 // Username with better spacing and shadow effect
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       Hive.box(userdata).get(userName) ?? "User",
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 20,
//                         letterSpacing: 0.2,
//                       ),
//                     ),
//                     SizedBox(
//                       width: 05,
//                     ),
//                     purchasedBadge != null && purchasedBadge!.logo.isNotEmpty
//                         ? Container(
//                             width: 24,
//                             height: 24,
//                             child: CachedNetworkImage(
//                               imageUrl: purchasedBadge!.logo,
//                               fit: BoxFit.contain,
//                               placeholder: (context, url) => const SizedBox(),
//                               errorWidget: (context, url, error) => Container(
//                                 decoration: BoxDecoration(
//                                   color: Colors.blue,
//                                   shape: BoxShape.circle,
//                                   border:
//                                       Border.all(color: Colors.white, width: 2),
//                                 ),
//                                 padding: const EdgeInsets.all(3),
//                                 child: const Icon(
//                                   Icons.check,
//                                   color: Colors.white,
//                                   size: 12,
//                                 ),
//                               ),
//                             ),
//                           )
//                         : SizedBox()
//                   ],
//                 ),

//                 const SizedBox(height: 30),

//                 // Align benefits list to start from left
//                 Align(
//                   alignment: Alignment.centerLeft,
//                   child: Column(
//                     children: [
//                       _buildBenefitsList(),
//                       _buildEligibilitySection()
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 80),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCanceledPlanNotification() {
//     // Find the canceled plan (subscribed=true, is_expired=true)
//     SubscriptionModel? canceledPlan;
//     for (var plan in subscriptionPlans) {
//       if (plan.isSubscribed && plan.isExpired) {
//         canceledPlan = plan;
//         break;
//       }
//     }

//     if (canceledPlan == null) {
//       print("DEBUG: No canceled plan found despite hasCancelled=true");
//       return const SizedBox.shrink();
//     }

//     print(
//         "DEBUG: Showing canceled plan notification for ${canceledPlan.title}");

//     return Container(
//       margin: const EdgeInsets.only(bottom: 24),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.orange.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.orange.shade300),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.cancel_outlined, color: Colors.orange.shade700),
//               const SizedBox(width: 8),
//               const Text(
//                 'Subscription Cancelled',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                   color: Colors.black,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Your ${canceledPlan.title} subscription has been cancelled.',
//             style: const TextStyle(
//               fontSize: 14,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'Your verified badge and premium features are no longer active.',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey.shade700,
//             ),
//           ),
//           const SizedBox(height: 12),
//           ElevatedButton(
//             onPressed: () {
//               setState(() {
//                 hasActivePlan = false;
//                 activePlanIndex = null;
//                 selectedPlanIndex = 0;
//                 currentStep = 2; // Go directly to plan selection
//               });
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.orange.shade600,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//             ),
//             child: const Text(
//               'Subscribe Again',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildExpiredPlanNotification() {
//     // Find the most recently expired plan
//     SubscriptionModel? expiredPlan;
//     for (var plan in subscriptionPlans) {
//       if (plan.isSubscribed && isSubscriptionExpired(plan.expireDate)) {
//         expiredPlan = plan;
//         break;
//       }
//     }

//     if (expiredPlan == null) {
//       return const SizedBox.shrink();
//     }

//     return Container(
//       margin: const EdgeInsets.only(bottom: 24),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.red.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.red.shade300),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
//               const SizedBox(width: 8),
//               Text(
//                 hasCancelled
//                     ? 'Subscription Cancelled'
//                     : 'Subscription Expired',
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                   color: Colors.black,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             hasCancelled
//                 ? 'Your ${expiredPlan.title} subscription was cancelled and expired on ${formatExpiryDate(expiredPlan.expireDate)}.'
//                 : 'Your ${expiredPlan.title} subscription expired on ${formatExpiryDate(expiredPlan.expireDate)}.',
//             style: const TextStyle(
//               fontSize: 14,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'Your verified badge and premium features are no longer active.',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey.shade700,
//             ),
//           ),
//           const SizedBox(height: 12),
//           ElevatedButton(
//             onPressed: () {
//               setState(() {
//                 hasActivePlan = false;
//                 activePlanIndex = null;
//                 selectedPlanIndex = 0;
//                 currentStep = 2; // Go directly to plan selection
//               });
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red.shade600,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//             ),
//             child: Text(
//               hasCancelled ? 'Subscribe Again' : 'Renew Subscription',
//               style: const TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEligibilitySection() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SizedBox(height: 20),

//           // Age requirement text
//           RichText(
//             text: TextSpan(
//               style: TextStyle(
//                 fontSize: 13,
//                 color: Colors.grey.shade700,
//               ),
//               children: const [
//                 TextSpan(
//                   text:
//                       'Orbis Elite Verified is not available for people younger than 21 years of age. ',
//                 ),
//                 TextSpan(
//                   text: 'See all Orbis Elite Verified eligibility requirements',
//                   style: TextStyle(
//                     color: Colors.blue,
//                     decoration: TextDecoration.underline,
//                   ),
//                 ),
//                 TextSpan(text: '.'),
//               ],
//             ),
//           ),

//           const SizedBox(height: 10),

//           // Privacy Policy text
//           RichText(
//             text: TextSpan(
//               style: TextStyle(
//                 fontSize: 13,
//                 color: Colors.grey.shade700,
//               ),
//               children: [
//                 const TextSpan(
//                     text: 'Information you provide is subject to our '),
//                 TextSpan(
//                   text: 'Privacy Policy',
//                   style: const TextStyle(
//                     color: Colors.blue,
//                     decoration: TextDecoration.underline,
//                   ),
//                   recognizer: TapGestureRecognizer()
//                     ..onTap = () {
//                       // Navigate to privacy policy
//                       Get.to(() => PpAndTcScreen(isFromPP: true));
//                     },
//                 ),
//                 const TextSpan(text: '.'),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStep2Content() {
//     return Scrollbar(
//       thickness: 6,
//       radius: const Radius.circular(10),
//       thumbVisibility: true,
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 20),
//                 Text(
//                   'Our Plan',
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),

//                 const SizedBox(height: 24),

//                 Center(
//                   child: Column(
//                     children: [
//                       // User profile with CoreX logo and badge
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           // User profile picture with badge
//                           Stack(
//                             children: [
//                               // Profile picture
//                               Container(
//                                 height: 90,
//                                 width: 90,
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(45),
//                                   border:
//                                       Border.all(color: Colors.white, width: 3),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.black.withOpacity(0.15),
//                                       blurRadius: 10,
//                                       spreadRadius: 0,
//                                       offset: const Offset(0, 3),
//                                     ),
//                                   ],
//                                 ),
//                                 child: ClipRRect(
//                                   borderRadius: BorderRadius.circular(45),
//                                   child: Hive.box(userdata).get(userImage) !=
//                                               null &&
//                                           Hive.box(userdata)
//                                               .get(userImage)
//                                               .toString()
//                                               .isNotEmpty
//                                       ? CachedNetworkImage(
//                                           imageUrl:
//                                               Hive.box(userdata).get(userImage),
//                                           fit: BoxFit.cover,
//                                           placeholder: (context, url) =>
//                                               loader(context),
//                                           errorWidget: (context, url, error) =>
//                                               Image.asset(
//                                             "assets/images/user_placeholder.png",
//                                             fit: BoxFit.cover,
//                                           ),
//                                         )
//                                       : Image.asset(
//                                           "assets/images/user_placeholder.png",
//                                           fit: BoxFit.cover,
//                                         ),
//                                 ),
//                               ),

//                               // Badge - positioned without adding a background since badge has its own background
//                               Positioned(
//                                   right: 0,
//                                   bottom: 0,
//                                   child: Image.asset(
//                                     "assets/icons/Nobg_qr.png",
//                                     height: 24,
//                                     width: 24,
//                                   ))
//                             ],
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 16),
//                       // Username with better spacing and shadow effect
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             Hive.box(userdata).get(userName) ?? "User",
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 20,
//                               letterSpacing: 0.2,
//                             ),
//                           ),
//                           SizedBox(
//                             width: 05,
//                           ),
//                           purchasedBadge != null &&
//                                   purchasedBadge!.logo.isNotEmpty
//                               ? Container(
//                                   width: 24,
//                                   height: 24,
//                                   child: CachedNetworkImage(
//                                     imageUrl: purchasedBadge!.logo,
//                                     fit: BoxFit.contain,
//                                     placeholder: (context, url) =>
//                                         const SizedBox(),
//                                     errorWidget: (context, url, error) =>
//                                         Container(
//                                       decoration: BoxDecoration(
//                                         color: Colors.blue,
//                                         shape: BoxShape.circle,
//                                         border: Border.all(
//                                             color: Colors.white, width: 2),
//                                       ),
//                                       padding: const EdgeInsets.all(3),
//                                       child: const Icon(
//                                         Icons.check,
//                                         color: Colors.white,
//                                         size: 12,
//                                       ),
//                                     ),
//                                   ),
//                                 )
//                               : SizedBox()
//                         ],
//                       ),

//                       // Orbis Elite Verified Nexus text
//                       Container(
//                         margin: const EdgeInsets.only(top: 4),
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 12, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: Colors.blue.withOpacity(0.08),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: const Text(
//                           "Orbis Elite Verified Nexus",
//                           style: TextStyle(
//                             color: Colors.blue,
//                             fontSize: 13,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 30),

//                 // Subscription plans
//                 _buildSubscriptionPlans(),
//                 const SizedBox(height: 80),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildActiveSubscriptionDetails() {
//     if (activePlanIndex == null ||
//         activePlanIndex! >= subscriptionPlans.length) {
//       return const SizedBox.shrink();
//     }

//     final perks = [
//       'Your verified badge is active',
//       'Increased account protection enabled',
//       'Enhanced support available',
//     ];

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Your Premium Benefits',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 16),
//         ...perks.map((text) {
//           return Padding(
//             padding: const EdgeInsets.symmetric(vertical: 6.0),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   width: 20,
//                   height: 20,
//                   child: Center(
//                     child: Icon(
//                       Icons.check_circle,
//                       color: Colors.green.shade700,
//                       size: 18,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     text,
//                     style: const TextStyle(
//                       fontSize: 17,
//                       fontWeight: FontWeight.w500,
//                       height: 1.4,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }).toList(),
//       ],
//     );
//   }

//   Widget _buildActivePlanOnly() {
//     if (activePlanIndex == null ||
//         activePlanIndex! >= subscriptionPlans.length) {
//       return const SizedBox.shrink();
//     }

//     final activePlan = subscriptionPlans[activePlanIndex!];

//     // Check if this is a canceled plan with future expiry date
//     final bool isCanceledButActive =
//         activePlan.isExpired && !isSubscriptionExpired(activePlan.expireDate);

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Your Current Plan',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 16),
//         _buildSubscriptionPlanCard(
//           plan: activePlan,
//           isSelected: false,
//           isActive: true,
//           onTap: () {}, // No action needed for active plan
//         ),

//         // Expiry date row
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
//           child: Row(
//             children: [
//               Icon(
//                   isCanceledButActive ? Icons.hourglass_top : Icons.access_time,
//                   size: 16,
//                   color: isCanceledButActive
//                       ? Colors.orange.shade700
//                       : Colors.grey.shade700),
//               const SizedBox(width: 6),
//               Text(
//                 isCanceledButActive
//                     ? 'Service ends on: ${formatExpiryDate(activePlan.expireDate)}'
//                     : 'Expires on: ${formatExpiryDate(activePlan.expireDate)}',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: isCanceledButActive
//                       ? Colors.orange.shade800
//                       : Colors.grey.shade800,
//                   fontWeight:
//                       isCanceledButActive ? FontWeight.w500 : FontWeight.normal,
//                 ),
//               ),
//             ],
//           ),
//         ),

//         // If plan is canceled but still active, show renewal options
//         // if (isCanceledButActive)
//         //   Padding(
//         //     padding: const EdgeInsets.only(top: 8.0, left: 4.0, right: 4.0),
//         //     child: Row(
//         //       children: [
//         //         Icon(Icons.autorenew, size: 16, color: Colors.blue.shade700),
//         //         const SizedBox(width: 6),
//         //         Flexible(
//         //           child: Text(
//         //             'Tap "Subscribe Again" to renew your subscription',
//         //             style: TextStyle(
//         //               fontSize: 14,
//         //               color: Colors.blue.shade800,
//         //               fontWeight: FontWeight.w500,
//         //             ),
//         //           ),
//         //         ),
//         //       ],
//         //     ),
//         //   ),
//       ],
//     );
//   }

//   Widget _buildActivePlanInfo() {
//     if (activePlanIndex == null ||
//         activePlanIndex! >= subscriptionPlans.length) {
//       return const SizedBox.shrink();
//     }

//     final activePlan = subscriptionPlans[activePlanIndex!];
//     final formattedExpiryDate = formatExpiryDate(activePlan.expireDate);

//     // Check if this is a canceled plan with future expiry date
//     final bool isCanceledButActive =
//         activePlan.isExpired && !isSubscriptionExpired(activePlan.expireDate);

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color:
//             isCanceledButActive ? Colors.orange.shade50 : Colors.green.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//             color: isCanceledButActive
//                 ? Colors.orange.shade300
//                 : Colors.green.shade300),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   Icon(
//                       isCanceledButActive
//                           ? Icons.info_outline
//                           : Icons.check_circle,
//                       color: isCanceledButActive
//                           ? Colors.orange.shade700
//                           : Colors.green.shade700),
//                   const SizedBox(width: 8),
//                   Text(
//                     isCanceledButActive
//                         ? 'Canceled Subscription'
//                         : 'Active Subscription',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                       color: Colors.black,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             isCanceledButActive
//                 ? 'Your ${activePlan.title} subscription has been canceled.'
//                 : 'You are currently subscribed to the ${activePlan.title} plan.',
//             style: const TextStyle(
//               fontSize: 14,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             isCanceledButActive
//                 ? 'Your premium features will remain active until the expiry date.'
//                 : 'Your verified badge is active and all premium features are unlocked.',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey.shade700,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               Icon(Icons.event_available,
//                   color: isCanceledButActive
//                       ? Colors.orange.shade700
//                       : Colors.blue.shade700,
//                   size: 16),
//               const SizedBox(width: 4),
//               Text(
//                 isCanceledButActive
//                     ? 'Access until: $formattedExpiryDate'
//                     : 'Valid until: $formattedExpiryDate',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                   color: isCanceledButActive
//                       ? Colors.orange.shade800
//                       : Colors.blue.shade800,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeader(BuildContext context) {
//     return AppBar(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(0),
//         side: BorderSide(color: Colors.grey.shade200),
//       ),
//       surfaceTintColor: Colors.white,
//       backgroundColor: Colors.white,
//       scrolledUnderElevation: 0,
//       elevation: 0,
//       automaticallyImplyLeading: false,
//       title: Row(
//         children: [
//           InkWell(
//             onTap: () {
//               if (currentStep > 1 && !hasActivePlan) {
//                 _previousStep();
//               } else {
//                 Navigator.of(context).pop();
//               }
//             },
//             child: Image.asset(
//               "assets/images/arrow-left.png",
//               height: 22,
//               color: Colors.black,
//             ),
//           ),
//           const SizedBox(width: 10),
//           const Text(
//             'Orbis Elite Verified',
//             style: TextStyle(
//               color: Colors.black,
//               fontWeight: FontWeight.w500,
//               fontSize: 16,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTitle() {
//     return Text(
//       hasActivePlan ? 'Our Subscription' : 'Select Your Plan',
//       style: const TextStyle(
//         fontSize: 24,
//         fontWeight: FontWeight.bold,
//         height: 1.2,
//       ),
//     );
//   }

//   Widget _buildBenefitsList() {
//     final benefits = [
//       {
//         'title': 'A verified badge',
//         'description':
//             'Your audience can trust that you\'re a real person sharing your real stories.'
//       },
//       {
//         'title': 'Increased account protection',
//         'description':
//             'Worry less about impersonation with proactive identity monitoring.'
//       },
//       {
//         'title': 'Enhanced support',
//         'description':
//             'Contact a help agent via email or chat. Support is currently available in 15 languages.'
//       },
//       {
//         'title': 'Upgraded profile features',
//         'description': 'Add a banner or cover image to your profile.'
//       },
//       {
//         'title': 'Get exclusive stickers or gifs',
//         'description':
//             'Express yourself with stickers or gifs only available to Orbis Elite subscribers.'
//       },
//     ];

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: benefits.map((benefit) {
//         return Padding(
//           padding: const EdgeInsets.symmetric(vertical: 10.0),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: 24,
//                 height: 24,
//                 child: Center(
//                   child: Image.asset(
//                     'assets/icons/checkmark_sub.png',
//                     width: 18,
//                     height: 18,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       benefit['title']!,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     benefit['title'] == 'Enhanced support'
//                         ? _buildEnhancedSupportText(benefit['description']!)
//                         : Text(
//                             benefit['description']!,
//                             style: const TextStyle(
//                               fontSize: 14,
//                               color: Colors.black87,
//                               height: 1.4,
//                             ),
//                           ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildEnhancedSupportText(String text) {
//     // Find the index of "15 languages" in the text
//     const String blueHighlight = "15 languages";
//     final int index = text.indexOf(blueHighlight);

//     if (index == -1) {
//       return Text(
//         text,
//         style: const TextStyle(
//           fontSize: 14,
//           color: Colors.black87,
//           height: 1.4,
//         ),
//       );
//     }

//     return RichText(
//       text: TextSpan(
//         style: const TextStyle(
//           fontSize: 14,
//           color: Colors.black87,
//           height: 1.4,
//         ),
//         children: [
//           TextSpan(text: text.substring(0, index)),
//           TextSpan(
//             text: blueHighlight,
//             style: const TextStyle(
//               fontSize: 14,
//               color: Colors.blue,
//               fontWeight: FontWeight.w500,
//               height: 1.4,
//             ),
//           ),
//           TextSpan(text: text.substring(index + blueHighlight.length)),
//         ],
//       ),
//     );
//   }

//   Widget _buildSubscriptionPlans() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Build subscription plan cards using the existing data models
//         ...List.generate(
//           subscriptionPlans.length,
//           (index) => Column(
//             children: [
//               _buildSubscriptionPlanCard(
//                 plan: subscriptionPlans[index],
//                 isSelected: selectedPlanIndex == index,
//                 isActive: hasActivePlan && activePlanIndex == index,
//                 onTap: () {
//                   setState(() {
//                     selectedPlanIndex = index;
//                   });
//                 },
//               ),
//               const SizedBox(height: 16),
//             ],
//           ),
//         ),
//         const SizedBox(height: 24),
//         // Terms of service text
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: RichText(
//             text: TextSpan(
//               style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
//               children: [
//                 const TextSpan(text: 'By continuing, you agree the '),
//                 TextSpan(
//                     text: 'Privacy Policy',
//                     style: TextStyle(
//                       color: Colors.blue.shade600,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     recognizer: TapGestureRecognizer()
//                       ..onTap = () {
//                         Get.to(PpAndTcScreen(
//                           isFromPP: true,
//                         ));
//                       }),
//                 const TextSpan(
//                   text:
//                       ' apply to your Orbis Elite Verified subscription. Cancel 24 hours before your next payment date to avoid charges. ',
//                 ),
//                 TextSpan(
//                     text: 'Terms of Service',
//                     style: TextStyle(
//                       color: Colors.blue.shade600,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     recognizer: TapGestureRecognizer()
//                       ..onTap = () {
//                         Get.to(PpAndTcScreen(
//                           isFromPP: false,
//                         ));
//                       }),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSubscriptionPlanCard({
//     required SubscriptionModel plan,
//     required bool isSelected,
//     required bool isActive,
//     required VoidCallback onTap,
//   }) {
//     // Calculate price per month for display
//     double planPrice = double.tryParse(plan.planPrice) ?? 0;
//     int cycle = int.tryParse(plan.cycle) ?? 1;
//     double pricePerMonth = cycle > 0 ? planPrice / cycle : planPrice;

//     return GestureDetector(
//       onTap: onTap,
//       child: Stack(
//         children: [
//           // Main Container
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               border: Border.all(
//                 color: isActive
//                     ? Colors.green
//                     : (isSelected ? Colors.blue : Colors.grey.shade300),
//                 width: isActive || isSelected ? 2 : 1,
//               ),
//               borderRadius: BorderRadius.circular(12),
//               color: isActive ? Colors.green.shade50 : Colors.white,
//             ),
//             child: Column(
//               children: [
//                 Row(
//                   children: [
//                     Container(
//                       width: 70,
//                       height: 70,
//                       decoration: BoxDecoration(
//                         color: isActive ? Colors.green : Colors.blue,
//                         shape: BoxShape.circle,
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(10.0),
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(20),
//                           child: CachedNetworkImage(
//                             imageUrl: plan.planIcon,
//                             placeholder: (context, url) => loader(context),
//                             errorWidget: (context, url, error) => Center(
//                               child: Image.asset(
//                                 'assets/icons/diamond.png',
//                                 width: 22,
//                                 height: 22,
//                                 color: Colors.white,
//                               ),
//                             ),
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     // Use Expanded here to allow text to take available space
//                     Expanded(
//                       flex: 3,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             plan.title,
//                             style: const TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold,
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           const SizedBox(height: 5),
//                           // Regular price per month - no promotional text
//                           Text(
//                             'IDR ${pricePerMonth.toStringAsFixed(0)} per month',
//                             style: TextStyle(
//                               fontSize: 10,
//                               color: Colors.grey.shade600,
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           Text(
//                             plan.planDescription ?? '',
//                             style: TextStyle(
//                               fontSize: 10,
//                               color: Colors.grey,
//                             ),
//                             maxLines: 4,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           if (isActive)
//                             Container(
//                               margin: const EdgeInsets.only(top: 5),
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 8, vertical: 4),
//                               decoration: BoxDecoration(
//                                 color: Colors.green,
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: const Text(
//                                 'Active',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                     // Expanded(
//                     //   flex: 2,
//                     //   child: Text(
//                     //     'IDR ${plan.planPrice}',
//                     //     style: TextStyle(
//                     //       fontSize: 12,
//                     //       fontWeight: FontWeight.bold,
//                     //       color: isActive ? Colors.green : Colors.blue,
//                     //     ),
//                     //     textAlign: TextAlign.end,
//                     //     maxLines: 1,
//                     //     overflow: TextOverflow.ellipsis,
//                     //   ),
//                     Expanded(
//                       flex: 2,
//                       child: Text(
//                         formatToIDR(plan.planPrice),
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
//                           color: isActive ? Colors.green : Colors.blue,
//                         ),
//                         textAlign: TextAlign.end,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // Month label in top right corner
//           Positioned(
//             top: 0,
//             right: 0,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 color: isActive ? Colors.green : Colors.blue,
//                 borderRadius: const BorderRadius.only(
//                   topRight: Radius.circular(11),
//                   bottomLeft: Radius.circular(11),
//                 ),
//               ),
//               child: Text(
//                 '${cycle} ${cycle == 1 ? 'Month' : 'Months'}',
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String formatToIDR(String price) {
//     try {
//       double parsed = double.tryParse(price) ?? 0;
//       int rounded = parsed.toInt();
//       String formatted = rounded.toString();

//       if (rounded >= 1000) {
//         formatted = formatted.replaceAllMapped(
//           RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
//           (Match m) => '${m[1]}.',
//         );
//       }

//       return 'IDR $formatted';
//     } catch (e) {
//       return 'IDR 0';
//     }
//   }

//   Widget _buildBottomButton() {
//     // Show different button based on current step
//     if (currentStep == 1) {
//       return Container(
//         width: double.infinity,
//         height: 50,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(25),
//           gradient: LinearGradient(
//             colors: [
//               secondaryColor,
//               chatownColor,
//             ],
//             begin: Alignment.centerLeft,
//             end: Alignment.centerRight,
//           ),
//         ),
//         child: TextButton(
//           onPressed: _nextStep,
//           child: const Text(
//             'Unlock benefits',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       );
//     } else {
//       // return Container(
//       //   width: double.infinity,
//       //   height: 50,
//       //   decoration: BoxDecoration(
//       //     borderRadius: BorderRadius.circular(25),
//       //     color: Colors.blue,
//       //   ),
//       //   child: TextButton(
//       //     onPressed: selectedPlanIndex != null
//       //         ? () => _handleSubscriptionPurchase()
//       //         : () {
//       //             Fluttertoast.showToast(msg: "Please Select plan to continue");
//       //           },
//       //     child: const Text(
//       //       'Continue',
//       //       style: TextStyle(
//       //         color: Colors.white,
//       //         fontSize: 16,
//       //         fontWeight: FontWeight.bold,
//       //       ),
//       //     ),
//       //   ),
//       // );
//       return Container(
//         width: double.infinity,
//         height: 50,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(25),
//           gradient: LinearGradient(
//             colors: [Colors.blue, Colors.blue.shade700],
//             begin: Alignment.centerLeft,
//             end: Alignment.centerRight,
//           ),
//         ),
//         child: TextButton(
//           onPressed: () {
//             if (selectedPlanIndex != null) {
//               _handleSubscriptionPurchase();
//             } else {
//               // More user-friendly error handling
//               Fluttertoast.showToast(
//                   msg: "Please select a subscription plan to continue",
//                   toastLength: Toast.LENGTH_SHORT,
//                   gravity: ToastGravity.BOTTOM,
//                   backgroundColor: Colors.red.shade800,
//                   textColor: Colors.white,
//                   fontSize: 16.0);

//               // Optional: Add subtle visual feedback
//               HapticFeedback.lightImpact();
//             }
//           },
//           child: const Text(
//             'Continue',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       );
//     }
//   }

//   void _handleSubscriptionPurchase() async {
//     if (selectedPlanIndex == null ||
//         selectedPlanIndex! >= subscriptionPlans.length) {
//       return;
//     }

//     // Get the selected plan
//     final selectedPlan = subscriptionPlans[selectedPlanIndex!];

//     // Convert plan price to double
//     double planPrice = double.tryParse(selectedPlan.planPrice) ?? 0;

//     // Get duration in months from the cycle field
//     int durationInMonths = int.tryParse(selectedPlan.cycle) ?? 1;

//     // Get subscription type ID
//     int subscriptionTypeId = selectedPlan.subscriptionTypeId;

//     String planCycle = selectedPlan.cycle ?? '0';

//     // Process payment using the PaymentService
//     final success = await PaymentService.processPayment(
//       cycle: planCycle,
//       amount: planPrice,
//       durationInMonths: durationInMonths,
//       subscriptionTypeId: subscriptionTypeId,
//       context: context,
//       onPaymentStarted: () {
//         setState(() {
//           isProcessingPayment = true;
//         });
//       },
//       onPaymentCompleted: () {
//         setState(() {
//           isProcessingPayment = false;
//         });
//       },
//       onError: (errorMsg) {
//         setState(() {
//           isProcessingPayment = false;
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(errorMsg),
//             backgroundColor: Colors.red,
//           ),
//         );
//       },
//     );

//     // If payment was successful, show success dialog
//     if (success) {
//       // Navigate to badge verification screen after successful payment
//       _showPaymentSuccessAndNavigate();
//     }
//   }

//   void _showPaymentSuccessAndNavigate() {
//     PaymentService.showPaymentSuccessDialog(
//       context,
//     );
//   }

//   bool isCancellingSubscription = false;
//   String _fcmtoken = '';
//   late UserProfileModel userProfileModel;
//   final apiHelper = ApiHelper();

// // Add this method to get the FCM token
//   Future<void> _getToken() async {
//     _fcmtoken = Hive.box(userdata).get(authToken) ?? '';
//   }

// // Add this method to handle keyboard closing
//   void closeKeyboard() {
//     FocusScope.of(context).unfocus();
//   }

//   Future<void> cancelSubscription() async {
//     setState(() {
//       isCancellingSubscription = true;
//     });

//     try {
//       await _getToken();
//       closeKeyboard();

//       var uri = Uri.parse(apiHelper.userCreateProfile);
//       var request = http.MultipartRequest("POST", uri);

//       Map<String, String> headers = {
//         "Accept": "application/json",
//         'Authorization': 'Bearer ${Hive.box(userdata).get(authToken)}'
//       };

//       request.headers.addAll(headers);

//       // Add the cancel_badge field to cancel the subscription
//       request.fields['cancle_badge'] = 'true';

//       print(request.fields);
//       var response = await request.send();
//       String responseData =
//           await response.stream.transform(utf8.decoder).join();
//       var userData = json.decode(responseData);
//       userProfileModel = UserProfileModel.fromJson(userData);

//       print(responseData);
//       if (userProfileModel.success == true) {
//         await Hive.box(userdata)
//             .put(userBio, userProfileModel.resData!.bio.toString());

//         // Show success message
//         Fluttertoast.showToast(
//           msg: "Subscription cancelled successfully",
//           toastLength: Toast.LENGTH_LONG,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.green,
//           textColor: Colors.white,
//         );

//         // Important: Just refresh subscription plans and let the logic in _fetchSubscriptionPlans
//         // determine whether to show the plan as active based on the expire_date
//         await _fetchSubscriptionPlans();

//         setState(() {
//           isCancellingSubscription = false;
//           // Don't set these directly - let _fetchSubscriptionPlans set them
//           // hasActivePlan = false;
//           // activePlanIndex = null;
//           // currentStep = 1;
//         });
//       } else {
//         Fluttertoast.showToast(
//           msg: "Failed to cancel subscription. Please try again.",
//           toastLength: Toast.LENGTH_LONG,
//           backgroundColor: Colors.red,
//         );

//         setState(() {
//           isCancellingSubscription = false;
//         });
//       }
//     } catch (e) {
//       print("Error cancelling subscription: $e");
//       Fluttertoast.showToast(
//         msg: "An error occurred. Please try again.",
//         toastLength: Toast.LENGTH_LONG,
//         backgroundColor: Colors.red,
//       );

//       setState(() {
//         isCancellingSubscription = false;
//       });
//     }
//   }
// }
