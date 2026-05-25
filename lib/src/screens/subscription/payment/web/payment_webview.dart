// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'dart:async';

// class PaymentWebView extends StatefulWidget {
//   final String initialUrl;
//   final String successUrl;
//   final String failureUrl;

//   const PaymentWebView({
//     Key? key,
//     required this.initialUrl,
//     this.successUrl = "corex://subscription-success",
//     this.failureUrl = "corex://subscription-failure",
//   }) : super(key: key);

//   @override
//   State<PaymentWebView> createState() => _PaymentWebViewState();
// }

// class _PaymentWebViewState extends State<PaymentWebView> {
//   late WebViewController _controller;
//   bool _isLoading = true;
//   bool _isCompleted = false;
//   Timer? _navigationTimer;

//   @override
//   void initState() {
//     super.initState();
//     log('webview url: ${widget.initialUrl}');
//     _initWebViewController();
//   }

//   @override
//   void dispose() {
//     _navigationTimer?.cancel();
//     super.dispose();
//   }

//   void _initWebViewController() {
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setBackgroundColor(Colors.white)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onPageStarted: (String url) {
//             if (mounted) {
//               setState(() {
//                 _isLoading = true;
//               });
//             }

//             _checkRedirectionUrl(url);
//           },
//           onPageFinished: (String url) {
//             if (mounted) {
//               setState(() {
//                 _isLoading = false;
//               });
//             }

//             _checkRedirectionUrl(url);
//           },
//           onUrlChange: (UrlChange change) {
//             if (change.url != null) {
//               _checkRedirectionUrl(change.url!);
//             }
//           },
//           onNavigationRequest: (NavigationRequest request) {
//             // Handle custom URL schemes
//             if (request.url.startsWith(widget.successUrl) ||
//                 request.url.startsWith(widget.failureUrl)) {
//               _handleRedirection(request.url);
//               return NavigationDecision.prevent;
//             }
//             return NavigationDecision.navigate;
//           },
//         ),
//       )
//       ..loadRequest(Uri.parse(widget.initialUrl));
//   }

//   void _checkRedirectionUrl(String url) {
//     if (_isCompleted) return;

//     if (url.startsWith(widget.successUrl)) {
//       _handleRedirection(url, isSuccess: true);
//     } else if (url.startsWith(widget.failureUrl)) {
//       _handleRedirection(url, isSuccess: false);
//     }
//   }

//   void _handleRedirection(String url, {bool isSuccess = true}) {
//     if (_isCompleted) return;

//     _isCompleted = true;

//     // Use a delay to ensure the WebView has stabilized before navigation
//     _navigationTimer?.cancel();
//     _navigationTimer = Timer(const Duration(milliseconds: 500), () {
//       if (mounted) {
//         Navigator.of(context).pop(isSuccess);
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         // Prevent back button during payment process
//         return false;
//       },
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Payment'),
//           automaticallyImplyLeading: false,
//           elevation: 0,
//           backgroundColor: Colors.white,
//           foregroundColor: Colors.black,
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.close),
//               onPressed: () {
//                 showDialog(
//                   context: context,
//                   builder: (context) => AlertDialog(
//                     title: const Text('Cancel Payment?'),
//                     content: const Text(
//                         'Are you sure you want to cancel this payment?'),
//                     actions: [
//                       TextButton(
//                         onPressed: () => Navigator.of(context).pop(),
//                         child: const Text('No'),
//                       ),
//                       TextButton(
//                         onPressed: () {
//                           Navigator.of(context).pop();
//                           Navigator.of(context).pop(
//                               false); // Return false to indicate cancellation
//                         },
//                         child: const Text('Yes'),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//         body: SafeArea(
//           child: Stack(
//             children: [
//               WebViewWidget(controller: _controller),
//               if (_isLoading)
//                 const Center(
//                   child: CircularProgressIndicator(),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:corexchat/src/global/global.dart';
import 'package:corexchat/src/screens/subscription/stpper_widget.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebView extends StatefulWidget {
  final String initialUrl;
  final String successUrl;
  final String failureUrl;

  const PaymentWebView({
    Key? key,
    required this.initialUrl,
    required this.successUrl,
    required this.failureUrl,
  }) : super(key: key);

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Handle success and failure redirects
            if (request.url.startsWith(widget.successUrl)) {
              Navigator.pop(context, true); // Return success
              return NavigationDecision.prevent;
            } else if (request.url.startsWith(widget.failureUrl)) {
              Navigator.pop(context, false); // Return failure
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Colors.white,
      //   elevation: 0,
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back, color: Colors.black),
      //     onPressed: () => Navigator.pop(context, false),
      //   ),
      //   title: const Text(
      //     'Payment',
      //     style: TextStyle(
      //       color: Colors.black,
      //       fontWeight: FontWeight.w500,
      //       fontSize: 16,
      //     ),
      //   ),
      // ),
      appBar: AppBar(
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
              onTap: () => Navigator.pop(context, false),
              child: Image.asset(
                "assets/images/arrow-left.png",
                height: 22,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Payment',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Add the stepper widget showing this is step 2
            SubscriptionStepper(currentStep: 2),

            // Payment webview
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Stack(
                    children: [
                      WebViewWidget(controller: _controller),
                      if (_isLoading)
                        Center(
                          child: loader(context),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Add bottom safe area padding
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
