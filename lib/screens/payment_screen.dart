import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/api_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_footer.dart';
import '../core/widgets/donation_stepper.dart';
import '../models/models.dart';
import '../providers/donor_portal_providers.dart';
import 'donation_success_screen.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _refCtrl = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;
  File? _screenshotFile;
  bool _isUploadingScreenshot = false;
  String? _uploadedScreenshotPath;

  @override
  void dispose() {
    _refCtrl.dispose();
    super.dispose();
  }

  String _buildUpiUri(TrustHomeItem home, AppDonationConfig config, String amount, String donorName) {
    String upiId = home.upiId.trim();
    if (upiId.isEmpty) {
      upiId = config.upiId.trim();
    }
    if (upiId.isEmpty) {
      upiId = '7373709961@okbizaxis';
    }

    // Determine clean registered merchant / payee name (avoid hyphens or special symbols which fail on NPCI)
    String cleanName;
    String merchantCode = '7392';
    if (upiId.contains('7373709961')) {
      cleanName = 'Nesakkaram Trust';
      merchantCode = '7392';
    } else if (upiId.contains('8825524702')) {
      cleanName = 'NESAKKARAM HOME FOR CHILDREN GIRLS';
      merchantCode = '7392';
    } else if (upiId.contains('9345034208')) {
      cleanName = 'NESAKKARAM SPECIAL';
      merchantCode = '5945';
    } else {
      cleanName = home.homeName.isNotEmpty
          ? 'Nesakkaram ${home.homeName.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), ' ')}'.trim()
          : (config.accountName.isNotEmpty ? config.accountName : 'Nesakkaram Trust');
      merchantCode = '8398'; // Charitable & Social Service Organizations
    }

    final encName = Uri.encodeComponent(cleanName);
    final cleanNote = 'Donation by ${donorName.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), ' ')}'.trim();
    final encNote = Uri.encodeComponent(cleanNote.isNotEmpty ? cleanNote : 'Donation');

    // Format amount cleanly
    final numAmt = double.tryParse(amount);
    final formattedAmt = numAmt != null ? (numAmt == numAmt.roundToDouble() ? numAmt.toInt().toString() : numAmt.toStringAsFixed(2)) : amount;

    // For Axis Bank / Google Pay Business merchant VPAs (@okbizaxis), mode=01 and mc are required for P2M intents
    if (upiId.endsWith('@okbizaxis')) {
      return 'upi://pay?pa=$upiId&pn=$encName&mc=$merchantCode&mode=01&am=$formattedAmt&cu=INR&tn=$encNote';
    }

    return 'upi://pay?pa=$upiId&pn=$encName&am=$formattedAmt&cu=INR&tn=$encNote';
  }

  Future<void> _launchUpiApp(String upiUri, {String? packageName, String? appName}) async {
    // 1. If a specific package is targeted on Android, try intent with package
    if (packageName != null && packageName.isNotEmpty) {
      final intentUri = Uri.parse(
        'intent://${upiUri.replaceFirst("upi://", "")}#Intent;scheme=upi;package=$packageName;end',
      );
      try {
        final launched = await launchUrl(intentUri, mode: LaunchMode.externalApplication);
        if (launched) return;
      } catch (_) {}
    }

    // 2. Fallback to standard UPI URI
    final uri = Uri.parse(upiUri);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appName != null
                ? '$appName could not be opened. Please scan the QR code above.'
                : 'No UPI app found. Please scan the QR code above.'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appName != null
                ? 'Could not open $appName. Please scan the QR code directly.'
                : 'Could not open UPI app. Please scan the QR code directly.'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadScreenshot() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked == null) return;

      final file = File(picked.path);
      setState(() {
        _screenshotFile = file;
        _isUploadingScreenshot = true;
        _errorMessage = null;
      });

      final api = ref.read(apiClientProvider);
      final path = await api.uploadPaymentScreenshot(file.path);
      setState(() {
        _uploadedScreenshotPath = path;
        _isUploadingScreenshot = false;
      });
      ref.read(donationDraftProvider.notifier).setAttachmentPath(path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment screenshot uploaded successfully!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingScreenshot = false;
          _errorMessage = 'Screenshot upload failed: ${e.toString().replaceFirst("Exception: ", "")}';
        });
      }
    }
  }

  Future<void> _submitDonation({String? refNumOverride}) async {
    final draft = ref.read(donationDraftProvider);
    final refNum = (refNumOverride ?? _refCtrl.text).trim();

    if (refNum.isEmpty) {
      setState(() => _errorMessage = 'Please enter the UPI Transaction Reference / UTR Number after completing your payment.');
      return;
    }

    setState(() { _isSubmitting = true; _errorMessage = null; });

    ref.read(donationDraftProvider.notifier).setPaymentDetails(
      upiRef: refNum,
      orderId: 'DIR_UPI_${DateTime.now().millisecondsSinceEpoch}',
      paymentId: refNum,
      attachmentPath: _uploadedScreenshotPath ?? '',
    );

    try {
      final api = ref.read(apiClientProvider);
      final req = ref.read(donationDraftProvider).toCreateRequest();
      final receipt = await api.createDonation(req);
      ref.invalidate(dashboardFutureProvider);
      ref.invalidate(donorHistoryFutureProvider(draft.phone));
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => DonationSuccessScreen(receipt: receipt)),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  Map<String, dynamic> _getHomeMeta(String key, [TrustHomeItem? homeItem]) {
    final title = (homeItem != null && homeItem.homeName.isNotEmpty) ? homeItem.homeName : '';
    final tamil = (homeItem != null && homeItem.homeNameTamil.isNotEmpty) ? homeItem.homeNameTamil : '';

    switch (key) {
      case 'OLD_AGE_HOME':
        return {
          'title': title.isNotEmpty ? title : 'Old Age Home',
          'tamil': tamil.isNotEmpty ? tamil : 'முதியோர்கள் இல்லம்',
          'badge': 'Senior Care Wing',
          'icon': Icons.elderly_rounded,
          'color': const Color(0xFFD97706),
        };
      case 'CHILDREN_HOME':
        return {
          'title': title.isNotEmpty ? title : 'Children Home',
          'tamil': tamil.isNotEmpty ? tamil : 'குழந்தைகள் இல்லம்',
          'badge': 'Child Welfare Wing',
          'icon': Icons.child_care_rounded,
          'color': const Color(0xFF059669),
        };
      case 'ADOPTION_HOME':
        return {
          'title': title.isNotEmpty ? title : 'Children Adoption Home',
          'tamil': tamil.isNotEmpty ? tamil : 'சிறப்பு தத்தெடுத்தல் மையம்',
          'badge': 'Adoption Agency Wing',
          'icon': Icons.family_restroom_rounded,
          'color': const Color(0xFF7C3AED),
        };
      default:
        final isBranch = key.startsWith('BRANCH_');
        return {
          'title': title.isNotEmpty ? title : (isBranch ? 'Trust Branch' : 'Nesakkaram Care Wing'),
          'tamil': tamil.isNotEmpty ? tamil : (isBranch ? 'அறக்கட்டளை கிளை' : 'நேசக்கரம் அறக்கட்டளை'),
          'badge': isBranch ? 'Trust Branch' : 'Dedicated Wing',
          'icon': isBranch ? Icons.account_balance_rounded : Icons.volunteer_activism_rounded,
          'color': isBranch ? const Color(0xFF0284C7) : const Color(0xFF2563EB),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final draft = ref.watch(donationDraftProvider);
    final configAsync = ref.watch(appDonationConfigFutureProvider);
    final homeItem = configAsync.maybeWhen(
      data: (c) => c.getHome(draft.trustHome),
      orElse: () => null,
    );
    final homeMeta = _getHomeMeta(draft.trustHome, homeItem);
    final homeColor = homeMeta['color'] as Color;

    return Scaffold(
      appBar: AppBar(
        title: Text('Direct Payment', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DonationStepper(currentStep: 3),
            const SizedBox(height: 20),

            // ── Amount & Cause Summary Card ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F0D2A), Color(0xFF1E1B4B), Color(0xFF312E81)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF1E1B4B).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Contribution',
                        style: GoogleFonts.nunito(color: const Color(0xFFE0E7FF), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: homeColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: homeColor.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (homeItem != null && homeItem.logoPath.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  ApiConstants.assetUrl(homeItem.logoPath),
                                  width: 14,
                                  height: 14,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(homeMeta['icon'] as IconData, size: 13, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 4),
                            ] else ...[
                              Icon(homeMeta['icon'] as IconData, size: 13, color: Colors.white),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              homeMeta['badge'] as String,
                              style: GoogleFonts.nunito(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${draft.amount}',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (homeItem != null && homeItem.logoPath.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  ApiConstants.assetUrl(homeItem.logoPath),
                                  width: 16,
                                  height: 16,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              'Beneficiary Home: ',
                              style: GoogleFonts.nunito(color: const Color(0xFFC7D2FE), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            Expanded(
                              child: Text(
                                '${homeMeta['title']} (${homeMeta['tamil']})',
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Category: ${draft.category}${draft.selectedScheme != null ? ' • ${draft.selectedScheme!.name}' : (draft.reason.isNotEmpty ? ' • ${draft.reason}' : '')}',
                          style: GoogleFonts.nunito(color: const Color(0xFFE0E7FF), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Donor: ${draft.fullName} (+91 ${draft.phone})',
                    style: GoogleFonts.nunito(color: const Color(0xFF818CF8), fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Error Message Banner (if any) ───────────────────────────────
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.nunito(
                          color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Primary Direct Payment Interface (QR & UPI App) ─────────────
            configAsync.when(
              data: (config) {
                final homeConfig = config.getHome(draft.trustHome);
                final upiId = homeConfig.upiId.isNotEmpty
                    ? homeConfig.upiId
                    : (config.upiId.isNotEmpty ? config.upiId : 'nesakkaram@sbi');
                final upiUri = _buildUpiUri(homeConfig, config, draft.amount.toString(), draft.fullName);
                final qrImageUrl = homeConfig.qrCodePath.isNotEmpty
                    ? ApiConstants.assetUrl(homeConfig.qrCodePath)
                    : (config.qrCodePath.isNotEmpty ? ApiConstants.assetUrl(config.qrCodePath) : '');

                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(16),
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Home Title & UPI Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: homeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(homeMeta['icon'] as IconData, color: homeColor, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Direct Payment for ${homeConfig.homeName}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                                    ),
                                  ),
                                  Text(
                                    homeConfig.homeNameTamil.isNotEmpty ? homeConfig.homeNameTamil : (homeMeta['tamil'] as String),
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),

                        // UPI ID with copy button
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Trust UPI ID',
                                    style: GoogleFonts.nunito(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    upiId,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: isDark ? const Color(0xFFFBBF24) : AppTheme.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? const Color(0xFF374151) : Colors.white,
                                  foregroundColor: isDark ? Colors.white : const Color(0xFF1F2937),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB)),
                                  ),
                                ),
                                icon: const Icon(Icons.copy_rounded, size: 14),
                                label: Text('Copy', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700)),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: upiId));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('UPI ID ($upiId) copied to clipboard!')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // QR Code Section
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: qrImageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          qrImageUrl,
                                          width: 190,
                                          height: 190,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, error, stackTrace) => QrImageView(
                                            data: upiUri,
                                            version: QrVersions.auto,
                                            size: 190,
                                            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.secondary),
                                            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.secondary),
                                          ),
                                        ),
                                      )
                                    : QrImageView(
                                        data: upiUri,
                                        version: QrVersions.auto,
                                        size: 190,
                                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.secondary),
                                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.secondary),
                                      ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Scan QR code with any UPI app',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                                ),
                              ),
                              Text(
                                'Google Pay • PhonePe • Paytm • BHIM • CRED',
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Action 1: Dedicated UPI App Launch Buttons
                        Text(
                          'Pay Directly via App:',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Row with PhonePe & Google Pay
                        Row(
                          children: [
                            // PhonePe Direct Button
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5F259F),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _launchUpiApp(
                                  upiUri,
                                  packageName: 'com.phonepe.app',
                                  appName: 'PhonePe',
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.flash_on_rounded, size: 18, color: Color(0xFFFFD700)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'PhonePe',
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Google Pay Direct Button
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
                                  elevation: 2,
                                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
                                  side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1), width: 1.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _launchUpiApp(
                                  upiUri,
                                  packageName: 'com.google.android.apps.nbu.paisa.user',
                                  appName: 'Google Pay',
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.account_balance_wallet_rounded, size: 18, color: Color(0xFF1A73E8)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Google Pay',
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Row with Paytm & All UPI Apps
                        Row(
                          children: [
                            // Paytm Direct Button
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF002E6E),
                                  foregroundColor: Colors.white,
                                  elevation: 1,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _launchUpiApp(
                                  upiUri,
                                  packageName: 'net.one97.paytm',
                                  appName: 'Paytm',
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.payment_rounded, size: 16, color: Color(0xFF00BAF2)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Paytm',
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // All UPI Apps / Chooser
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                  side: BorderSide(color: isDark ? const Color(0xFF059669) : const Color(0xFF10B981), width: 1.2),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _launchUpiApp(upiUri),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.apps_rounded, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Other Apps',
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Security & Failure Guidance Note
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Note: If your bank app restricts 3rd-party deep links for merchant accounts (@okbizaxis), please scan the QR code above with Google Pay or PhonePe scanner — scanning always works without restrictions!',
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),
                        const Divider(height: 1),
                        const SizedBox(height: 18),

                        // Step: UTR / Reference Entry
                        Text(
                          'Step 2: Enter Transaction Reference / UTR Number *',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'After completing payment in your UPI app, paste the 12-digit UTR or Transaction ID here:',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _refCtrl,
                          decoration: InputDecoration(
                            hintText: 'e.g. 4235XXXXXXXX or UPI Ref No.',
                            prefixIcon: const Icon(Icons.receipt_rounded, color: Color(0xFF6B7280)),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.paste_rounded, size: 20, color: AppTheme.primary),
                              tooltip: 'Paste from clipboard',
                              onPressed: () async {
                                final data = await Clipboard.getData('text/plain');
                                if (data?.text != null) _refCtrl.text = data!.text!.trim();
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Step 3: Payment Screenshot / Proof Upload (Recommended for Fast Verification)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Step 3: Upload Payment Screenshot',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Recommended',
                                style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Upload your payment success screen from GPay / PhonePe / Paytm so trust staff can verify immediately:',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Upload Box
                        if (_screenshotFile == null)
                          InkWell(
                            onTap: _isUploadingScreenshot ? null : _pickAndUploadScreenshot,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.add_photo_alternate_rounded, color: AppTheme.primary, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Select Payment Screenshot',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                                        ),
                                      ),
                                      Text(
                                        'From Gallery • PNG, JPG up to 10MB',
                                        style: GoogleFonts.nunito(
                                          fontSize: 11,
                                          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _screenshotFile!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _isUploadingScreenshot ? Icons.cloud_upload_rounded : Icons.check_circle_rounded,
                                            color: const Color(0xFF059669),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _isUploadingScreenshot ? 'Uploading Proof...' : 'Proof Uploaded!',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                              color: const Color(0xFF059669),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _screenshotFile!.path.split(RegExp(r'[\\/]')).last,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.nunito(fontSize: 11, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF059669),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  icon: const Icon(Icons.refresh_rounded, size: 14),
                                  label: Text('Change', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700)),
                                  onPressed: _isUploadingScreenshot ? null : _pickAndUploadScreenshot,
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 18),

                        // Action 2: Complete & Generate Receipt Button
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF4F46E5) : AppTheme.secondary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isSubmitting ? null : () => _submitDonation(),
                          icon: _isSubmitting
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.check_circle_rounded, color: Colors.white),
                          label: Text(
                            _isSubmitting ? 'Verifying & Generating Receipt...' : 'Confirm & Complete Donation',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Bank Account Details Accordion (for NEFT / IMPS)
                        Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.account_balance_rounded,
                              size: 20,
                              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            ),
                            title: Text(
                              'Need Bank Transfer Details? (NEFT / IMPS)',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
                              ),
                            ),
                            children: [
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      _bankRow(context, 'Account Name', config.accountName),
                                      const Divider(height: 12),
                                      _bankRow(context, 'Bank & Branch', '${config.bankName} (${config.branch})'),
                                      const Divider(height: 12),
                                      _bankRow(context, 'Account No.', config.accountNumberMasked),
                                      const Divider(height: 12),
                                      _bankRow(context, 'IFSC Code', config.ifscCode),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              ),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                child: Text('Donation settings could not be loaded: $err', style: TextStyle(color: Colors.red.shade800, fontSize: 12)),
              ),
            ),

            const SizedBox(height: 20),

            // ── How to Pay Guide ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? const Color(0xFF059669).withValues(alpha: 0.5) : const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Direct UPI Payment Steps',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF14532D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _howToStep(context, '1', 'Tap "Pay via UPI App" to open GPay, PhonePe or Paytm, OR scan the QR code'),
                  _howToStep(context, '2', 'Complete the payment on your UPI app for ₹${draft.amount}'),
                  _howToStep(context, '3', 'Enter the 12-digit UTR / UPI reference number above'),
                  _howToStep(context, '4', 'Tap "Confirm & Complete Donation" to immediately receive your official 80G receipt ✅'),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const AppFooter(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _howToStep(BuildContext context, String step, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1, right: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF059669),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF166534),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bankRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 13,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}
