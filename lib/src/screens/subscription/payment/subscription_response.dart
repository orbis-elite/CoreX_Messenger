class SubscriptionPaymentResponse {
  final bool success;
  final String? message;
  final String? recurringId;
  final String? customerId;
  final String? actionUrl;
  final String? errorMessage;

  SubscriptionPaymentResponse({
    required this.success,
    this.message,
    this.recurringId,
    this.customerId,
    this.actionUrl,
    this.errorMessage,
  });
}
