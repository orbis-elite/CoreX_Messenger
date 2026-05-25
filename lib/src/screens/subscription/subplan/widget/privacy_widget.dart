import 'package:flutter/material.dart';

class PrivacyPolicyText extends StatelessWidget {
  final VoidCallback onPrivacyPolicyTap;

  const PrivacyPolicyText({
    Key? key,
    required this.onPrivacyPolicyTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Information you provide is subject to our ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
        GestureDetector(
          onTap: onPrivacyPolicyTap,
          // Add extra padding to increase tap target
          behavior: HitTestBehavior.opaque,
          child: Padding(
            // Add padding to increase the tappable area
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Text(
              'Privacy Policy',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        Text(
          '.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

// Alternative implementation with InkWell for better tap feedback
class PrivacyPolicyTextWithInkWell extends StatelessWidget {
  final VoidCallback onPrivacyPolicyTap;

  const PrivacyPolicyTextWithInkWell({
    Key? key,
    required this.onPrivacyPolicyTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Information you provide is subject to our ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
        InkWell(
          onTap: onPrivacyPolicyTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Text(
              'Privacy Policy',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        Text(
          '.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

// Usage example:
// PrivacyPolicyText(
//   onPrivacyPolicyTap: () {
//     Navigator.push(
//       context, 
//       MaterialPageRoute(builder: (context) => PpAndTcScreen(isFromPP: true))
//     );
//     // Or with Get: Get.to(() => PpAndTcScreen(isFromPP: true));
//   },
// )