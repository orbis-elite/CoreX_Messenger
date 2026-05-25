class BadgeModel {
  final String logo;
  final int verificationTypeId;
  final String title;
  final bool isPaymentRequired;
  final bool isGroup;
  final String? cycle;
  final String planPrice;
  final String planDescription;
  final String createdAt;
  final String updatedAt;

  BadgeModel({
    required this.logo,
    required this.verificationTypeId,
    required this.title,
    required this.isPaymentRequired,
    required this.isGroup,
    required this.cycle,
    required this.planPrice,
    required this.planDescription,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      logo: json['logo'] ?? '',
      verificationTypeId: json['verification_type_id'] ?? 0,
      title: json['titile'] ?? '', // Note typo in API
      isPaymentRequired: json['is_payment_required'] ?? false,
      isGroup: json['is_group'] ?? false,
      cycle: json['cycle'] ?? '',
      planPrice: json['plan_price'] ?? '',
      planDescription: json['plan_description'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}
