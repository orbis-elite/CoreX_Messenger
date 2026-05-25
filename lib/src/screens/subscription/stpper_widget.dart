import 'package:flutter/material.dart';

class SubscriptionStepper extends StatelessWidget {
  final int currentStep;

  const SubscriptionStepper({
    Key? key,
    required this.currentStep,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Step 1 indicator
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: currentStep >= 1 ? Colors.blue : Colors.grey.shade300,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(2),
                  bottomLeft: Radius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Step 2 indicator
          Expanded(
            child: Container(
              height: 4,
              color: currentStep >= 2 ? Colors.blue : Colors.grey.shade300,
            ),
          ),
          const SizedBox(width: 4),
          // Step 3 indicator
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: currentStep >= 3 ? Colors.blue : Colors.grey.shade300,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(2),
                  bottomRight: Radius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
