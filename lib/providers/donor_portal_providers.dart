import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../models/models.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final dashboardFutureProvider = FutureProvider<PublicDashboard>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.getDashboard();
});

final schemesFutureProvider = FutureProvider<List<PublicScheme>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.getActiveSchemes();
});

final appDonationConfigFutureProvider = FutureProvider<AppDonationConfig>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.getAppDonationConfig();
});

final donorHistoryFutureProvider =
    FutureProvider.family<DonorHistoryResponse, String>((ref, phone) async {
  final api = ref.watch(apiClientProvider);
  return api.getDonorHistory(phone);
});

// ─── Local Storage for Remembered Phone ───────────────────────────────────────

final savedPhoneProvider = FutureProvider<String>((ref) async {
  final sp = await SharedPreferences.getInstance();
  return sp.getString('saved_donor_phone') ?? '';
});

// ─── Current Donation Draft State ─────────────────────────────────────────────

class DonationDraftState {
  // ignore: prefer_initializing_formals
  const DonationDraftState({
    this.phone = '',
    this.fullName = '',
    this.email = '',
    this.panNumber = '',
    this.addressLine = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.trustHome = 'OLD_AGE_HOME',
    this.category = 'FOOD', // Default standard FOOD
    this.reason = '',
    this.selectedScheme,
    this.schemeUnits = 1,
    Decimal? amount,
    this.eventType = '',
    this.eventPersonName = '',
    this.eventDate = '',
    this.relationshipToDonor = '',
    this.upiReferenceNumber = '',
    this.paymentGatewayOrderId = '',
    this.paymentGatewayPaymentId = '',
    this.attachmentPath = '',
  }) : _amount = amount;

  final String phone;
  final String fullName;
  final String email;
  final String panNumber;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;
  final String trustHome;
  final String category;
  final String reason;
  final PublicScheme? selectedScheme;
  final int schemeUnits;
  final Decimal? _amount;
  Decimal get amount => _amount ?? Decimal.zero;
  final String eventType;
  final String eventPersonName;
  final String eventDate;
  final String relationshipToDonor;
  final String upiReferenceNumber;
  final String paymentGatewayOrderId;
  final String paymentGatewayPaymentId;
  final String attachmentPath;

  DonationDraftState copyWith({
    String? phone,
    String? fullName,
    String? email,
    String? panNumber,
    String? addressLine,
    String? city,
    String? state,
    String? pincode,
    String? trustHome,
    String? category,
    String? reason,
    PublicScheme? selectedScheme,
    bool clearScheme = false,
    int? schemeUnits,
    Decimal? amount,
    String? eventType,
    String? eventPersonName,
    String? eventDate,
    String? relationshipToDonor,
    String? upiReferenceNumber,
    String? paymentGatewayOrderId,
    String? paymentGatewayPaymentId,
    String? attachmentPath,
  }) {
    return DonationDraftState(
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      panNumber: panNumber ?? this.panNumber,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      trustHome: trustHome ?? this.trustHome,
      category: category ?? this.category,
      reason: reason ?? this.reason,
      selectedScheme: clearScheme ? null : (selectedScheme ?? this.selectedScheme),
      schemeUnits: schemeUnits ?? this.schemeUnits,
      amount: amount ?? this.amount,
      eventType: eventType ?? this.eventType,
      eventPersonName: eventPersonName ?? this.eventPersonName,
      eventDate: eventDate ?? this.eventDate,
      relationshipToDonor: relationshipToDonor ?? this.relationshipToDonor,
      upiReferenceNumber: upiReferenceNumber ?? this.upiReferenceNumber,
      paymentGatewayOrderId: paymentGatewayOrderId ?? this.paymentGatewayOrderId,
      paymentGatewayPaymentId: paymentGatewayPaymentId ?? this.paymentGatewayPaymentId,
      attachmentPath: attachmentPath ?? this.attachmentPath,
    );
  }

  CreateDonationRequest toCreateRequest() {
    return CreateDonationRequest(
      fullName: fullName.trim(),
      phone: phone.trim(),
      email: email.trim(),
      panNumber: panNumber.trim().toUpperCase(),
      addressLine: addressLine.trim(),
      city: city.trim(),
      state: state.trim(),
      pincode: pincode.trim(),
      trustHome: trustHome,
      amount: amount,
      category: category,
      reason: reason.trim(),
      schemeId: selectedScheme?.id,
      eventType: eventType.trim(),
      eventPersonName: eventPersonName.trim(),
      eventDate: eventDate.trim(),
      relationshipToDonor: relationshipToDonor.trim(),
      upiReferenceNumber: upiReferenceNumber.trim(),
      paymentGatewayOrderId: paymentGatewayOrderId.trim(),
      paymentGatewayPaymentId: paymentGatewayPaymentId.trim(),
      attachmentPath: attachmentPath.trim(),
    );
  }
}

class DonationDraftNotifier extends Notifier<DonationDraftState> {
  @override
  DonationDraftState build() => const DonationDraftState();

  void setTrustHome(String homeKey) {
    state = state.copyWith(trustHome: homeKey);
  }

  void setPhone(String phone) {
    state = state.copyWith(phone: phone);
    _persistPhone(phone);
  }

  Future<void> _persistPhone(String phone) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('saved_donor_phone', phone);
  }

  void setDonorDetails({
    required String fullName,
    String email = '',
    String panNumber = '',
    String addressLine = '',
    String city = '',
    String state = '',
    String pincode = '',
  }) {
    this.state = this.state.copyWith(
          fullName: fullName,
          email: email,
          panNumber: panNumber,
          addressLine: addressLine,
          city: city,
          state: state,
          pincode: pincode,
        );
  }

  void setCategory(String category) {
    if (category == 'FOOD') {
      state = state.copyWith(category: category, reason: '', clearScheme: true, amount: Decimal.zero);
    } else {
      state = state.copyWith(category: category, clearScheme: true);
    }
  }

  void selectFoodScheme(PublicScheme scheme, int units) {
    final total = scheme.defaultAmount * Decimal.fromInt(units);
    state = state.copyWith(
      selectedScheme: scheme,
      schemeUnits: units,
      amount: total,
    );
  }

  void setDirectAmount(Decimal amt) {
    state = state.copyWith(amount: amt);
  }

  void setReason(String r) {
    state = state.copyWith(reason: r);
  }

  void setEventDetails({
    String? eventType,
    String? eventPersonName,
    String? eventDate,
    String? relationshipToDonor,
  }) {
    state = state.copyWith(
      eventType: eventType,
      eventPersonName: eventPersonName,
      eventDate: eventDate,
      relationshipToDonor: relationshipToDonor,
    );
  }

  void setAttachmentPath(String path) {
    state = state.copyWith(attachmentPath: path);
  }

  void setPaymentDetails({
    required String upiRef,
    String orderId = '',
    String paymentId = '',
    String attachmentPath = '',
  }) {
    state = state.copyWith(
      upiReferenceNumber: upiRef,
      paymentGatewayOrderId: orderId,
      paymentGatewayPaymentId: paymentId,
      attachmentPath: attachmentPath.isNotEmpty ? attachmentPath : state.attachmentPath,
    );
  }

  void resetDraft() {
    final currentPhone = state.phone;
    final currentName = state.fullName;
    final currentEmail = state.email;
    final currentPan = state.panNumber;
    state = DonationDraftState(
      phone: currentPhone,
      fullName: currentName,
      email: currentEmail,
      panNumber: currentPan,
    );
  }
}

final donationDraftProvider =
    NotifierProvider<DonationDraftNotifier, DonationDraftState>(DonationDraftNotifier.new);
