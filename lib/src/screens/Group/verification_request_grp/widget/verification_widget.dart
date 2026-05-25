import 'package:corexchat/app.dart';
import 'package:flutter/material.dart';
import 'package:corexchat/src/global/global.dart';
import 'package:corexchat/src/global/strings.dart';
import 'package:get/get.dart';

class VerificationRequestWidget extends StatefulWidget {
  final String conversationID;
  final String groupName;
  final Function(bool) onRequestSubmitted;
  final bool isAdmin;

  const VerificationRequestWidget({
    Key? key,
    required this.conversationID,
    required this.groupName,
    required this.onRequestSubmitted,
    required this.isAdmin,
  }) : super(key: key);

  @override
  State<VerificationRequestWidget> createState() =>
      _VerificationRequestWidgetState();
}

class _VerificationRequestWidgetState extends State<VerificationRequestWidget> {
  bool isLoading = false;
  bool hasSubmittedRequest = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
          blurRadius: 0.5,
          spreadRadius: 0,
          offset: Offset(0, 0.4),
          color: Color.fromRGBO(239, 239, 239, 1),
        )
      ]),
      child: InkWell(
        onTap: () {
          if (widget.isAdmin) {
            _showVerificationRequestDialog(context);
          } else {
            _showAdminOnlyDialog(context);
          }
        },
        child: Padding(
          padding:
              const EdgeInsets.only(left: 25, top: 10, right: 25, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified, color: chatColor),
                  const SizedBox(width: 10),
                  Text(
                    languageController.textTranslate('Verification Request'),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    hasSubmittedRequest
                        ? languageController.textTranslate('Pending')
                        : languageController.textTranslate('Request'),
                    style: TextStyle(
                      color: hasSubmittedRequest ? Colors.orange : Colors.grey,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: appgrey2,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showAdminOnlyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            languageController.textTranslate('Admin Only Feature'),
          ),
          content: Text(
            languageController.textTranslate(
                'Only group admins can request verification for this group.'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                languageController.textTranslate('OK'),
                style: TextStyle(color: chatownColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showVerificationRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return isLoading
            ? const Center(child: CircularProgressIndicator())
            : hasSubmittedRequest
                ? _buildActiveRequestDialog(context)
                : _buildNewRequestDialog(context);
      },
    );
  }

  Widget _buildActiveRequestDialog(BuildContext context) {
    return AlertDialog(
      title: Text(
        languageController.textTranslate('Active Verification Request'),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hourglass_empty, color: Colors.orange, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  languageController.textTranslate(
                      'Your verification request is pending review.'),
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRequestInfoRow(languageController.textTranslate('Group Name:'),
              widget.groupName),
          _buildRequestInfoRow(languageController.textTranslate('Status:'),
              languageController.textTranslate('Pending')),
          const SizedBox(height: 16),
          Text(
            languageController.textTranslate(
                'We\'re reviewing your request. This process usually takes 3-5 business days.'),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            languageController.textTranslate('Close'),
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  // Widget _buildNewRequestDialog(BuildContext context) {
  //   return AlertDialog(
  //     title: Text(
  //       languageController.textTranslate('Request Verification'),
  //     ),
  //     content: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           languageController
  //               .textTranslate('Request a verification badge for your group'),
  //           style: const TextStyle(fontSize: 14),
  //         ),
  //         const SizedBox(height: 16),
  //         Container(
  //           padding: const EdgeInsets.all(12),
  //           decoration: BoxDecoration(
  //             color: Colors.blue.withOpacity(0.1),
  //             borderRadius: BorderRadius.circular(8),
  //             border: Border.all(color: Colors.blue.shade200),
  //           ),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Row(
  //                 children: [
  //                   Icon(Icons.info_outline, color: Colors.blue, size: 20),
  //                   const SizedBox(width: 8),
  //                   Expanded(
  //                     child: Text(
  //                       languageController
  //                           .textTranslate('Verification Benefits'),
  //                       style: const TextStyle(
  //                         fontWeight: FontWeight.bold,
  //                         color: Colors.blue,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 8),
  //               Text(
  //                 '• ' +
  //                     languageController.textTranslate('Trust and credibility'),
  //                 style: const TextStyle(fontSize: 12),
  //               ),
  //               const SizedBox(height: 4),
  //               Text(
  //                 '• ' + languageController.textTranslate('Priority support'),
  //                 style: const TextStyle(fontSize: 12),
  //               ),
  //               const SizedBox(height: 4),
  //               Text(
  //                 '• ' +
  //                     languageController.textTranslate('Enhanced visibility'),
  //                 style: const TextStyle(fontSize: 12),
  //               ),
  //             ],
  //           ),
  //         ),
  //         const SizedBox(height: 16),
  //         Text(
  //           languageController.textTranslate(
  //               'Note: Verification requests are reviewed by our team. We\'ll notify you once a decision has been made.'),
  //           style: TextStyle(
  //             fontSize: 12,
  //             color: Colors.grey.shade600,
  //             fontStyle: FontStyle.italic,
  //           ),
  //         ),
  //       ],
  //     ),
  //     actions: [
  //       TextButton(
  //         onPressed: () => Navigator.pop(context),
  //         child: Text(
  //           languageController.textTranslate('Cancel'),
  //           style: const TextStyle(color: Colors.grey),
  //         ),
  //       ),
  //       ElevatedButton(
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: chatownColor,
  //         ),
  //         onPressed: () async {
  //           setState(() {
  //             isLoading = true;
  //           });

  //           // Call the API via callback
  //           final success = await widget.onRequestSubmitted(true);

  //           setState(() {
  //             isLoading = false;
  //             if (success) {
  //               hasSubmittedRequest = true;
  //             }
  //           });

  //           Navigator.pop(context);
  //         },
  //         child: Text(
  //           languageController.textTranslate('Submit Request'),
  //           style: const TextStyle(color: Colors.white),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildNewRequestDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: chatownColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.verified,
                    color: chatownColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    languageController.textTranslate('Request Verification'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Description text
            Text(
              languageController
                  .textTranslate('Request a verification badge for your group'),
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),

            // Benefits container with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    chatownColor.withOpacity(0.05),
                    Colors.blue.withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: chatownColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.stars_rounded, color: chatownColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        languageController
                            .textTranslate('Verification Benefits'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: chatownColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitItem(
                    Icons.verified_user_outlined,
                    languageController.textTranslate('Trust and credibility'),
                  ),
                  const SizedBox(height: 8),
                  _buildBenefitItem(
                    Icons.support_agent,
                    languageController.textTranslate('Priority support'),
                  ),
                  const SizedBox(height: 8),
                  _buildBenefitItem(
                    Icons.visibility,
                    languageController.textTranslate('Enhanced visibility'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Note with icon
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      languageController.textTranslate(
                          'Note: Verification requests are reviewed by our team. We\'ll notify you once a decision has been made.'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons with loading state
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  child: Text(
                    languageController.textTranslate('Cancel'),
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: chatownColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() {
                            isLoading = true;
                          });
                          // Call the API via callback
                          final success = await widget.onRequestSubmitted(true);
                          setState(() {
                            isLoading = false;
                            if (success) {
                              hasSubmittedRequest = true;
                            }
                          });
                          Navigator.pop(context);
                        },
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          languageController.textTranslate('Submit Request'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// Helper method for benefit items
  Widget _buildBenefitItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: chatownColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: label.contains('Status') && value == 'Pending'
                    ? Colors.orange
                    : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
