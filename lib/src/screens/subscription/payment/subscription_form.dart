import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:corexchat/src/global/global.dart';

class SubscriptionFormData {
  final String userName;
  final String phoneNumber;
  final String email;

  SubscriptionFormData({
    required this.userName,
    required this.phoneNumber,
    required this.email,
  });
}

class SubscriptionForm extends StatefulWidget {
  final Function(SubscriptionFormData) onSubmit;
  final VoidCallback onCancel;

  const SubscriptionForm({
    Key? key,
    required this.onSubmit,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<SubscriptionForm> createState() => _SubscriptionFormState();
}

class _SubscriptionFormState extends State<SubscriptionForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _userNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  bool _isLoading = false;
  bool _isEmailConfirmed = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final userBox = Hive.box('userdata');

    // Pre-fill with data from Hive using the correct key names
    final firstName = userBox.get('firstName') ?? '';
    final lastName = userBox.get('lastName') ?? '';
    final fullName = '$firstName ${lastName}'.trim();
    final userName =
        fullName.isNotEmpty ? fullName : (userBox.get('userName') ?? '');

    final userMobile = userBox.get('userMobile') ?? '';
    final userCountryCode = userBox.get('userCountryCode') ?? '';

    // Try multiple ways to get phone number
    String combinedPhone = '';
    if (userCountryCode.isNotEmpty && userMobile.isNotEmpty) {
      combinedPhone = '$userCountryCode$userMobile';
    } else if (userMobile.isNotEmpty) {
      combinedPhone = userMobile;
    } else {
      // Try alternative key names
      final mobile = userBox.get('mobile') ?? userBox.get('phone') ?? '';
      if (mobile.isNotEmpty) {
        combinedPhone = mobile;
      }
    }

    // Check for previously confirmed email
    final confirmedEmail = userBox.get('confirmed_subscription_email');
    final isEmailConfirmed =
        userBox.get('is_subscription_email_confirmed', defaultValue: false);

    _userNameController = TextEditingController(text: userName);
    _phoneController = TextEditingController(text: combinedPhone);
    _emailController = TextEditingController(text: confirmedEmail ?? '');

    // Restore email confirmation state
    _isEmailConfirmed =
        isEmailConfirmed && confirmedEmail != null && confirmedEmail.isNotEmpty;
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      // If email is not confirmed yet, show confirmation dialog
      if (!_isEmailConfirmed && _emailController.text.trim().isNotEmpty) {
        _showEmailConfirmationDialog();
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final formData = SubscriptionFormData(
        userName: _userNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
      );

      widget.onSubmit(formData);
    }
  }

  void _showEmailConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.email_outlined,
                color: chatownColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Confirm Email',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please confirm your email address:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundgrey,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: chatownColor.withOpacity(0.6)),
                ),
                child: Text(
                  _emailController.text.trim(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: chatownColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Once confirmed, you cannot change this email address.',
                style: TextStyle(
                  fontSize: 14,
                  color: appgrey2,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Edit Email',
                style: TextStyle(
                  color: appgrey2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [
                    chatownColor,
                    secondaryColor,
                  ],
                ),
              ),
              child: TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();

                  // Save email and confirmation state to Hive
                  final userBox = Hive.box('userdata');
                  await userBox.put('confirmed_subscription_email',
                      _emailController.text.trim());
                  await userBox.put('is_subscription_email_confirmed', true);

                  setState(() {
                    _isEmailConfirmed = true;
                  });
                },
                child: const Text(
                  'Confirm Email',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = screenHeight - keyboardHeight;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(keyboardHeight > 0 ? 10 : 20),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width > 600
              ? 400
              : MediaQuery.of(context).size.width * 0.9,
          maxHeight:
              keyboardHeight > 0 ? availableHeight * 0.9 : screenHeight * 0.85,
        ),
        decoration: BoxDecoration(
          color: appColorWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: blurColor.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    chatownColor,
                    secondaryColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.payment,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Payment Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Verify your information for secure payment',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (keyboardHeight > 0)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Scroll to see all fields',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),

            // Form content - Scrollable with visible scrollbar
            Flexible(
              child: Scrollbar(
                thumbVisibility: true,
                trackVisibility:
                    keyboardHeight > 0, // Show track when keyboard is visible
                thickness: keyboardHeight > 0 ? 8 : 6,
                radius: const Radius.circular(4),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  physics: const BouncingScrollPhysics(), // Better scroll feel
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username Field (Read-only)
                        _buildReadOnlyField(
                          label: 'Username',
                          value: _userNameController.text,
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 16),

                        // Phone Number Field (Read-only)
                        _buildReadOnlyField(
                          label: 'Phone Number',
                          value: _phoneController.text,
                          icon: Icons.phone,
                        ),
                        const SizedBox(height: 16),

                        // Email Field (Conditional Read-only)
                        _isEmailConfirmed
                            ? _buildReadOnlyField(
                                label: 'Email Address',
                                value: _emailController.text,
                                icon: Icons.email,
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Email Address *',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      hintText: 'Enter your email address',
                                      prefixIcon: Icon(
                                        Icons.email,
                                        color: chatownColor,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: appgrey),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: appgrey),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: chatownColor,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: backgroundgrey,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Email is required';
                                      }
                                      if (!RegExp(
                                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                          .hasMatch(value.trim())) {
                                        return 'Please enter a valid email address';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                        const SizedBox(height: 24),

                        // Buttons - Responsive layout
                        LayoutBuilder(
                          builder: (context, constraints) {
                            bool isWideScreen = constraints.maxWidth > 300;

                            if (isWideScreen) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed:
                                          _isLoading ? null : widget.onCancel,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        side: BorderSide(color: appgrey),
                                      ),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: LinearGradient(
                                          colors: [
                                            chatownColor,
                                            secondaryColor,
                                          ],
                                        ),
                                      ),
                                      child: ElevatedButton(
                                        onPressed:
                                            _isLoading ? null : _handleSubmit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                _isEmailConfirmed
                                                    ? 'Proceed to Payment'
                                                    : 'Continue Payment',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              // Stack buttons vertically on narrow screens
                              return Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: LinearGradient(
                                          colors: [
                                            chatownColor,
                                            secondaryColor,
                                          ],
                                        ),
                                      ),
                                      child: ElevatedButton(
                                        onPressed:
                                            _isLoading ? null : _handleSubmit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                _isEmailConfirmed
                                                    ? 'Proceed to Payment'
                                                    : 'Continue Payment',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed:
                                          _isLoading ? null : widget.onCancel,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        side: BorderSide(color: appgrey),
                                      ),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                        // Add responsive bottom padding
                        SizedBox(
                            height: MediaQuery.of(context).viewInsets.bottom > 0
                                ? 20
                                : 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundgrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: appgrey),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: appIconColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value.isEmpty ? 'Not set' : value,
                  style: TextStyle(
                    fontSize: 16,
                    color: value.isEmpty ? appgrey2 : chatColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Icon(
                Icons.lock,
                color: appgrey2,
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
