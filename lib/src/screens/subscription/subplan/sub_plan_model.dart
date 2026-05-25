class SubscriptionModel {
  final String planIcon;
  final int subscriptionTypeId;
  final String title;
  final String cycle;
  final String planPrice;
  final String planDescription;
  final bool status;
  final String createdAt;
  final String updatedAt;
  final bool isSubscribed; // User has this plan
  final bool isExpired; // Plan is canceled (NOT date-based expiry)
  final String expireDate; // When the plan benefits actually expire

  SubscriptionModel({
    required this.planIcon,
    required this.subscriptionTypeId,
    required this.title,
    required this.cycle,
    required this.planPrice,
    required this.planDescription,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.isSubscribed,
    required this.isExpired,
    required this.expireDate,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      planIcon: json['plan_icon'] ?? '',
      subscriptionTypeId: json['subscription_type_id'] ?? 0,
      title: json['titile'] ?? '', // Note: API has a typo in 'titile'
      cycle: json['cycle'] ?? '0',
      planPrice: json['plan_price'] ?? '0',
      planDescription: json['plan_description'] ?? '',
      status: json['status'] ?? false,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      isSubscribed: json['subscribed'] ?? false,
      isExpired: json['is_expired'] ??
          false, // This represents cancellation status, not date-based expiry
      expireDate: json['expire_date'] ?? '',
    );
  }

  // Helper methods for easier status checks

  // Is this plan active (subscribed, not canceled, and not date-expired)?
  bool get isActive => isSubscribed && !isExpired && !isDateExpired();

  // Is this plan canceled but still providing benefits?
  bool get isCanceledButActive => isSubscribed && isExpired && !isDateExpired();

  // Is this plan fully expired (past the expiry date)?
  bool isDateExpired() {
    try {
      if (expireDate.isEmpty) return true;

      DateTime expiryDate = DateTime.parse(expireDate);
      DateTime today = DateTime.now();
      DateTime todayWithoutTime = DateTime(today.year, today.month, today.day);

      return todayWithoutTime.isAfter(expiryDate);
    } catch (e) {
      print("Error checking date expiry: $e");
      return true;
    }
  }
}
