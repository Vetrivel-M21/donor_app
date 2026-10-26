import 'package:decimal/decimal.dart';

// ─── Dashboard Models ────────────────────────────────────────────────────────

class PublicDashboard {
  const PublicDashboard({
    required this.trustName,
    required this.tagline,
    required this.taxExemption,
    required this.activeSchemes,
    required this.totalDonors,
    required this.totalDonations,
    required this.annadhanamDaily,
    required this.categories,
    required this.upcomingOccasions,
  });

  final String trustName;
  final String tagline;
  final String taxExemption;
  final int activeSchemes;
  final int totalDonors;
  final int totalDonations;
  final String annadhanamDaily;
  final List<DonationCategory> categories;
  final List<UpcomingOccasion> upcomingOccasions;

  factory PublicDashboard.fromJson(dynamic json) {
    final m = json as Map<String, dynamic>;
    return PublicDashboard(
      trustName: m['trust_name'] as String? ?? 'Nesakkaram Trust',
      tagline: m['tagline'] as String? ?? 'Selfless Service & Annadhanam for All',
      taxExemption: m['tax_exemption'] as String? ?? 'Official Trust Receipt Issued',
      activeSchemes: (m['active_schemes'] as num?)?.toInt() ?? 0,
      totalDonors: (m['total_donors'] as num?)?.toInt() ?? 0,
      totalDonations: (m['total_donations'] as num?)?.toInt() ?? 0,
      annadhanamDaily: m['annadhanam_daily'] as String? ?? 'Over 500+ healthy meals served daily to needy pilgrims and devotees',
      categories: (m['categories'] as List? ?? [])
          .map((e) => DonationCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      upcomingOccasions: (m['upcoming_occasions'] as List? ?? [])
          .map((e) => UpcomingOccasion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DonationCategory {
  const DonationCategory({
    required this.key,
    required this.title,
    required this.icon,
    required this.description,
  });

  final String key;
  final String title;
  final String icon;
  final String description;

  factory DonationCategory.fromJson(Map<String, dynamic> m) {
    return DonationCategory(
      key: m['key'] as String? ?? '',
      title: m['title'] as String? ?? '',
      icon: m['icon'] as String? ?? '',
      description: m['description'] as String? ?? '',
    );
  }
}

class UpcomingOccasion {
  const UpcomingOccasion({
    required this.title,
    required this.description,
    required this.date,
  });

  final String title;
  final String description;
  final String date;

  factory UpcomingOccasion.fromJson(Map<String, dynamic> m) {
    return UpcomingOccasion(
      title: m['title'] as String? ?? '',
      description: m['description'] as String? ?? '',
      date: m['date'] as String? ?? '',
    );
  }
}

// ─── Scheme Model ────────────────────────────────────────────────────────────

class PublicScheme {
  const PublicScheme({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.mealType,
    required this.foodType,
    required this.defaultAmount,
  });

  final int id;
  final String name;
  final String description;
  final String category; // FOOD, MEDICINE, EDUCATION, GENERAL, OTHER
  final String mealType; // BREAKFAST, LUNCH, DINNER, FULL_DAY, NA
  final String foodType; // VEG, NON_VEG, NA
  final Decimal defaultAmount;

  factory PublicScheme.fromJson(Map<String, dynamic> m) {
    return PublicScheme(
      id: (m['id'] as num?)?.toInt() ?? 0,
      name: m['name'] as String? ?? '',
      description: m['description'] as String? ?? '',
      category: m['category'] as String? ?? 'FOOD',
      mealType: m['meal_type'] as String? ?? '',
      foodType: m['food_type'] as String? ?? '',
      defaultAmount: Decimal.tryParse((m['default_amount'] ?? '0').toString()) ?? Decimal.zero,
    );
  }

  String get displayName {
    final tags = <String>[];
    if (mealType.isNotEmpty && mealType != 'NA') tags.add(_formatLabel(mealType));
    if (foodType.isNotEmpty && foodType != 'NA') tags.add(_formatLabel(foodType));
    final tagStr = tags.isNotEmpty ? ' (${tags.join(' • ')})' : '';
    return '$name$tagStr';
  }

  static String _formatLabel(String s) {
    if (s.isEmpty) return '';
    return s.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }
}

// ─── Trust Home Item Model ───────────────────────────────────────────────────

class TrustHomeItem {
  const TrustHomeItem({
    required this.id,
    required this.homeKey,
    required this.homeName,
    required this.homeNameTamil,
    required this.upiId,
    required this.qrCodePath,
    this.logoPath = '',
    required this.description,
    this.isActive = true,
  });

  final int id;
  final String homeKey; // OLD_AGE_HOME, CHILDREN_HOME, ADOPTION_HOME
  final String homeName;
  final String homeNameTamil;
  final String upiId;
  final String qrCodePath;
  final String logoPath;
  final String description;
  final bool isActive;

  factory TrustHomeItem.fromJson(Map<String, dynamic> m) {
    return TrustHomeItem(
      id: (m['id'] as num?)?.toInt() ?? 0,
      homeKey: m['home_key'] as String? ?? '',
      homeName: m['home_name'] as String? ?? '',
      homeNameTamil: m['home_name_tamil'] as String? ?? '',
      upiId: m['upi_id'] as String? ?? '',
      qrCodePath: m['qr_code_path'] as String? ?? '',
      logoPath: m['logo_path'] as String? ?? '',
      description: m['description'] as String? ?? '',
      isActive: m['is_active'] as bool? ?? true,
    );
  }
}

// ─── App Donation Bank/UPI Config ─────────────────────────────────────────────

class AppDonationConfig {
  const AppDonationConfig({
    required this.bankName,
    required this.accountName,
    required this.accountNumberMasked,
    required this.ifscCode,
    required this.branch,
    required this.upiId,
    required this.qrCodePath,
    this.razorpayKeyId = '',
    this.cashfreeAppId = '',
    this.cashfreeEnv = 'PROD',
    this.homes = const [],
  });

  final String bankName;
  final String accountName;
  final String accountNumberMasked;
  final String ifscCode;
  final String branch;
  final String upiId;
  final String qrCodePath;
  final String razorpayKeyId;
  final String cashfreeAppId;
  final String cashfreeEnv;
  final List<TrustHomeItem> homes;

  static const List<TrustHomeItem> defaultHomes = [
    TrustHomeItem(
      id: 1,
      homeKey: 'OLD_AGE_HOME',
      homeName: 'Old Age Home',
      homeNameTamil: 'முதியோர்கள் இல்லம்',
      upiId: '',
      qrCodePath: '',
      description: 'Support elderly residents with nutritious food, healthcare, and dignified shelter.',
    ),
    TrustHomeItem(
      id: 2,
      homeKey: 'CHILDREN_HOME',
      homeName: 'Children Home',
      homeNameTamil: 'குழந்தைகள் இல்லம்',
      upiId: '',
      qrCodePath: '',
      description: 'Empower underprivileged children with education, nutritious meals, and loving care.',
    ),
    TrustHomeItem(
      id: 3,
      homeKey: 'ADOPTION_HOME',
      homeName: 'Children Adoption Home',
      homeNameTamil: 'சிறப்பு தத்தெடுத்தல் மையம்',
      upiId: '',
      qrCodePath: '',
      description: 'Specialised adoption center offering safety, medical care, and family placement for infants & children.',
    ),
  ];

  List<TrustHomeItem> get activeHomes => homes.isNotEmpty ? homes : defaultHomes;

  TrustHomeItem getHome(String key) {
    return activeHomes.firstWhere(
      (h) => h.homeKey == key,
      orElse: () => activeHomes.first,
    );
  }

  factory AppDonationConfig.fromJson(dynamic json) {
    final m = json as Map<String, dynamic>;
    final rawHomes = (m['homes'] as List? ?? [])
        .map((e) => TrustHomeItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return AppDonationConfig(
      bankName: m['bank_name'] as String? ?? '',
      accountName: m['account_name'] as String? ?? 'Nesakkaram Trust Account',
      accountNumberMasked: m['account_number_masked'] as String? ?? '',
      ifscCode: m['ifsc_code'] as String? ?? '',
      branch: m['branch'] as String? ?? '',
      upiId: m['upi_id'] as String? ?? '',
      qrCodePath: m['qr_code_path'] as String? ?? '',
      razorpayKeyId: m['razorpay_key_id'] as String? ?? '',
      cashfreeAppId: m['cashfree_app_id'] as String? ?? '',
      cashfreeEnv: m['cashfree_env'] as String? ?? 'PROD',
      homes: rawHomes.isNotEmpty ? rawHomes : defaultHomes,
    );
  }
}

// ─── Create Donation Request ──────────────────────────────────────────────────

class CreateDonationRequest {
  const CreateDonationRequest({
    required this.fullName,
    required this.phone,
    this.email = '',
    this.panNumber = '',
    this.addressLine = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.trustHome = 'OLD_AGE_HOME',
    required this.amount,
    required this.category,
    this.reason = '',
    this.schemeId,
    this.eventType,
    this.eventPersonName,
    this.eventDate,
    this.relationshipToDonor,
    this.paymentGatewayOrderId = '',
    this.paymentGatewayPaymentId = '',
    this.upiReferenceNumber = '',
    this.attachmentPath = '',
  });

  final String fullName;
  final String phone;
  final String email;
  final String panNumber;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;
  final String trustHome;
  final Decimal amount;
  final String category;
  final String reason;
  final int? schemeId;
  final String? eventType;
  final String? eventPersonName;
  final String? eventDate;
  final String? relationshipToDonor;
  final String paymentGatewayOrderId;
  final String paymentGatewayPaymentId;
  final String upiReferenceNumber;
  final String attachmentPath;

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'phone': phone,
        'email': email,
        'pan_number': panNumber,
        'address_line': addressLine,
        'city': city,
        'state': state,
        'pincode': pincode,
        'trust_home': trustHome,
        'amount': amount.toString(),
        'category': category,
        'reason': reason,
        if (schemeId != null) 'scheme_id': schemeId,
        if (eventType != null && eventType!.isNotEmpty) 'event_type': eventType,
        if (eventPersonName != null && eventPersonName!.isNotEmpty) 'event_person_name': eventPersonName,
        if (eventDate != null && eventDate!.isNotEmpty) 'event_date': eventDate,
        if (relationshipToDonor != null && relationshipToDonor!.isNotEmpty) 'relationship_to_donor': relationshipToDonor,
        'payment_gateway_order_id': paymentGatewayOrderId,
        'payment_gateway_payment_id': paymentGatewayPaymentId,
        'upi_reference_number': upiReferenceNumber,
        if (attachmentPath.isNotEmpty) 'attachment_path': attachmentPath,
      };
}

// ─── Donation Receipt ─────────────────────────────────────────────────────────

class DonationReceipt {
  const DonationReceipt({
    required this.donationId,
    required this.donationNumber,
    required this.voucherNumber,
    required this.donorName,
    required this.donorPhone,
    required this.donorPan,
    required this.amount,
    required this.category,
    required this.purpose,
    required this.schemeName,
    required this.businessDate,
    required this.bankName,
    required this.accountName,
    required this.referenceNumber,
    required this.verificationStatus,
    required this.message,
  });

  final int donationId;
  final String donationNumber;
  final String voucherNumber;
  final String donorName;
  final String donorPhone;
  final String donorPan;
  final Decimal amount;
  final String category;
  final String purpose;
  final String schemeName;
  final String businessDate;
  final String bankName;
  final String accountName;
  final String referenceNumber;
  final String verificationStatus;
  final String message;

  factory DonationReceipt.fromJson(dynamic json) {
    final m = json as Map<String, dynamic>;
    return DonationReceipt(
      donationId: (m['donation_id'] as num?)?.toInt() ?? 0,
      donationNumber: m['donation_number'] as String? ?? '',
      voucherNumber: m['voucher_number'] as String? ?? '',
      donorName: m['donor_name'] as String? ?? '',
      donorPhone: m['donor_phone'] as String? ?? '',
      donorPan: m['donor_pan'] as String? ?? '',
      amount: Decimal.tryParse((m['amount'] ?? '0').toString()) ?? Decimal.zero,
      category: m['category'] as String? ?? '',
      purpose: m['purpose'] as String? ?? '',
      schemeName: m['scheme_name'] as String? ?? '',
      businessDate: m['business_date'] as String? ?? '',
      bankName: m['bank_name'] as String? ?? '',
      accountName: m['account_name'] as String? ?? '',
      referenceNumber: m['reference_number'] as String? ?? '',
      verificationStatus: m['verification_status'] as String? ?? 'VERIFIED',
      message: m['message'] as String? ?? 'Donation verified successfully!',
    );
  }
}

// ─── Donor History Models ─────────────────────────────────────────────────────

class DonorHistoryResponse {
  const DonorHistoryResponse({
    required this.donor,
    required this.donations,
  });

  final DonorProfile? donor;
  final List<PastDonationItem> donations;

  factory DonorHistoryResponse.fromJson(dynamic json) {
    final m = json as Map<String, dynamic>;
    final donorMap = m['donor'] as Map<String, dynamic>?;
    return DonorHistoryResponse(
      donor: donorMap != null ? DonorProfile.fromJson(donorMap) : null,
      donations: (m['donations'] as List? ?? [])
          .map((e) => PastDonationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DonorProfile {
  const DonorProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.panNumber,
  });

  final int id;
  final String fullName;
  final String phone;
  final String email;
  final String panNumber;

  factory DonorProfile.fromJson(Map<String, dynamic> m) {
    return DonorProfile(
      id: (m['id'] as num?)?.toInt() ?? 0,
      fullName: m['full_name'] as String? ?? '',
      phone: m['phone'] as String? ?? '',
      email: m['email'] as String? ?? '',
      panNumber: m['pan_number'] as String? ?? '',
    );
  }
}

class PastDonationItem {
  const PastDonationItem({
    required this.id,
    required this.donationNumber,
    required this.businessDate,
    required this.amount,
    required this.category,
    required this.purpose,
    required this.reason,
    required this.schemeName,
    required this.verificationStatus,
    required this.paymentGatewayPaymentId,
    required this.upiReferenceNumber,
    required this.createdAt,
  });

  final int id;
  final String donationNumber;
  final String businessDate;
  final Decimal amount;
  final String category;
  final String purpose;
  final String reason;
  final String schemeName;
  final String verificationStatus;
  final String paymentGatewayPaymentId;
  final String upiReferenceNumber;
  final String createdAt;

  factory PastDonationItem.fromJson(Map<String, dynamic> m) {
    return PastDonationItem(
      id: (m['id'] as num?)?.toInt() ?? 0,
      donationNumber: m['donation_number'] as String? ?? '',
      businessDate: m['business_date'] as String? ?? '',
      amount: Decimal.tryParse((m['amount'] ?? '0').toString()) ?? Decimal.zero,
      category: m['category'] as String? ?? '',
      purpose: m['purpose'] as String? ?? '',
      reason: m['reason'] as String? ?? '',
      schemeName: m['scheme_name'] as String? ?? '',
      verificationStatus: m['verification_status'] as String? ?? 'VERIFIED',
      paymentGatewayPaymentId: m['payment_gateway_payment_id'] as String? ?? '',
      upiReferenceNumber: m['upi_reference_number'] as String? ?? '',
      createdAt: m['created_at'] as String? ?? '',
    );
  }
}

// ─── Razorpay Order Response ──────────────────────────────────────────────────────

class RazorpayOrderResponse {
  const RazorpayOrderResponse({
    required this.razorpayOrderId,
    required this.amount,
    required this.currency,
    required this.keyId,
  });

  final String razorpayOrderId;
  final int amount; // in paise
  final String currency;
  final String keyId;

  factory RazorpayOrderResponse.fromJson(dynamic json) {
    final m = json as Map<String, dynamic>;
    return RazorpayOrderResponse(
      razorpayOrderId: m['razorpay_order_id'] as String? ?? '',
      amount: (m['amount'] as num?)?.toInt() ?? 0,
      currency: m['currency'] as String? ?? 'INR',
      keyId: m['key_id'] as String? ?? '',
    );
  }
}
