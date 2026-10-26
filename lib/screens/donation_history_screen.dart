import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_footer.dart';
import '../models/models.dart';
import '../providers/donor_portal_providers.dart';
import 'receipt_view_screen.dart';

class DonationHistoryScreen extends ConsumerStatefulWidget {
  const DonationHistoryScreen({super.key, this.phone});

  final String? phone;

  @override
  ConsumerState<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends ConsumerState<DonationHistoryScreen> {
  final _phoneCtrl = TextEditingController();
  String _activePhone = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final draft = ref.read(donationDraftProvider);
      if (widget.phone != null && widget.phone!.isNotEmpty) {
        _phoneCtrl.text = widget.phone!;
        setState(() => _activePhone = widget.phone!);
      } else if (draft.phone.isNotEmpty) {
        _phoneCtrl.text = draft.phone;
        setState(() => _activePhone = draft.phone);
      } else {
        final saved = await ref.read(savedPhoneProvider.future);
        if (saved.isNotEmpty) {
          _phoneCtrl.text = saved;
          setState(() => _activePhone = saved);
        }
      }
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final clean = _phoneCtrl.text.trim();
    if (clean.length == 10) {
      setState(() => _activePhone = clean);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number')),
      );
    }
  }

  Color _categoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'FOOD': return const Color(0xFFD97706);
      case 'MEDICINE': return const Color(0xFF059669);
      case 'EDUCATION': return const Color(0xFF2563EB);
      case 'GENERAL': return const Color(0xFF7C3AED);
      default: return const Color(0xFFDB2777);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'FOOD': return Icons.soup_kitchen_rounded;
      case 'MEDICINE': return Icons.medical_services_rounded;
      case 'EDUCATION': return Icons.school_rounded;
      case 'GENERAL': return Icons.temple_hindu_rounded;
      default: return Icons.volunteer_activism_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Donations', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 17)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Search Card ───────────────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.history_rounded, color: AppTheme.primary, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'View Donation History',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                                ),
                              ),
                              Text(
                                'Enter your registered phone number',
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: const InputDecoration(
                                hintText: '10 digit mobile number',
                                prefixIcon: Icon(Icons.phone_rounded, size: 20),
                              ),
                              onFieldSubmitted: (_) => _onSearch(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              minimumSize: const Size(80, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _onSearch,
                            child: Text('Search', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Donations List ────────────────────────────────────────────
              if (_activePhone.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkBorder : const Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_long_rounded, size: 40, color: Color(0xFF9CA3AF)),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'No Phone Number Entered',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter your mobile number above to load history',
                          style: GoogleFonts.nunito(
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Consumer(
                  builder: (context, ref, _) {
                    final historyAsync = ref.watch(donorHistoryFutureProvider(_activePhone));
                    return historyAsync.when(
                      data: (resp) {
                        final donor = resp.donor;
                        final donations = resp.donations;

                        if (donations.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppTheme.darkCard : AppTheme.primaryLight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.volunteer_activism_outlined,
                                      size: 40,
                                      color: isDark ? const Color(0xFFFBBF24) : AppTheme.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'No Donations Yet',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Make your first offering to support Nesakkaram Trust!',
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final totalContributed = donations.fold<Decimal>(
                          Decimal.zero,
                          (sum, item) => sum + item.amount,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Donor Profile Card
                            if (donor != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [AppTheme.primaryDark.withValues(alpha: 0.3), AppTheme.darkCard]
                                        : [AppTheme.primaryLight.withValues(alpha: 0.6), Colors.white],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? AppTheme.darkBorder : AppTheme.primary.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor: AppTheme.primary,
                                      child: Text(
                                        donor.fullName.isNotEmpty ? donor.fullName[0].toUpperCase() : 'D',
                                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            donor.fullName,
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                                            ),
                                          ),
                                          Text(
                                            '+91 ${donor.phone}',
                                            style: GoogleFonts.nunito(
                                              fontSize: 12,
                                              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                            ),
                                          ),
                                          if (donor.panNumber.isNotEmpty)
                                            Container(
                                              margin: const EdgeInsets.only(top: 4),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isDark ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.primaryLight,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'PAN: ${donor.panNumber}',
                                                style: GoogleFonts.nunito(
                                                  fontSize: 11,
                                                  color: isDark ? const Color(0xFFFBBF24) : AppTheme.primaryDark,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Total Offerings',
                                          style: GoogleFonts.nunito(
                                            fontSize: 10,
                                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                          ),
                                        ),
                                        Text(
                                          '₹$totalContributed',
                                          style: GoogleFonts.outfit(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                          ),
                                        ),
                                        Text(
                                          '${donations.length} donations',
                                          style: GoogleFonts.nunito(fontSize: 10, color: const Color(0xFF9CA3AF)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                            Text(
                              'Donation History (${donations.length})',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 12),

                            ...donations.asMap().entries.map((entry) => _buildDonationItem(context, donor, entry.value, entry.key == 0)),
                          ],
                        );
                      },
                      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppTheme.primary))),
                      error: (err, _) => Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Text('Could not load history: $err', style: TextStyle(color: Colors.red.shade800, fontSize: 12)),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 20),
              const AppFooter(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDonationItem(BuildContext context, DonorProfile? donor, PastDonationItem d, bool isLatest) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = _categoryColor(d.category);
    final catIcon = _categoryIcon(d.category);
    final isVerified = d.verificationStatus == 'VERIFIED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLatest ? catColor.withValues(alpha: 0.4) : (isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB))),
        boxShadow: isLatest
            ? [BoxShadow(color: catColor.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isVerified ? () => _openReceipt(context, d, donor) : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(catIcon, color: catColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        d.donationNumber,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12, color: catColor),
                      ),
                      if (isLatest)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Latest', style: GoogleFonts.nunito(fontSize: 9, fontWeight: FontWeight.w800, color: catColor)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    d.purpose.isNotEmpty ? d.purpose : '${d.category} Donation',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                    ),
                  ),
                  if (d.schemeName.isNotEmpty)
                    Text(
                      'Scheme: ${d.schemeName}',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
                      ),
                    ),
                  if (d.reason.isNotEmpty)
                    Text(
                      'Reason: ${d.reason}',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 11, color: Color(0xFF9CA3AF)),
                          const SizedBox(width: 4),
                          Text(
                            d.businessDate,
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (d.verificationStatus == 'PENDING')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.4) : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFF59E0B)),
                              ),
                              child: Text(
                                '⏳ PENDING VERIFICATION',
                                style: GoogleFonts.nunito(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFD97706),
                                ),
                              ),
                            )
                          else if (d.verificationStatus == 'REJECTED')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF881337).withValues(alpha: 0.4) : const Color(0xFFFFE4E6),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFF43F5E)),
                              ),
                              child: Text(
                                '✕ REJECTED',
                                style: GoogleFonts.nunito(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFE11D48),
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF10B981)),
                              ),
                              child: Text(
                                '✓ VERIFIED',
                                style: GoogleFonts.nunito(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Text(
                            '₹${d.amount}',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (d.upiReferenceNumber.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Ref / UTR: ${d.upiReferenceNumber}', style: GoogleFonts.nunito(fontSize: 10, color: const Color(0xFF9CA3AF))),
                    ),
                  if (d.verificationStatus == 'PENDING')
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Awaiting bank statement confirmation by branch staff',
                        style: GoogleFonts.nunito(fontSize: 9.5, color: const Color(0xFFD97706), fontStyle: FontStyle.italic),
                      ),
                    ),
                  // ── Official Receipt Action Button ──────────────────────
                  if (isVerified) ...[
                    const SizedBox(height: 10),
                    Divider(height: 1, color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF059669)),
                            const SizedBox(width: 4),
                            Text(
                              'Official Receipt Available',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => _openReceipt(context, d, donor),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withValues(alpha: isDark ? 0.25 : 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.receipt_long_rounded, size: 14, color: Color(0xFF059669)),
                                const SizedBox(width: 5),
                                Text(
                                  'View / Download',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11.5,
                                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  void _openReceipt(BuildContext context, PastDonationItem d, DonorProfile? donor) {
    final receipt = DonationReceipt(
      donationId: d.id,
      donationNumber: d.donationNumber,
      voucherNumber: d.donationNumber,
      donorName: (donor != null && donor.fullName.trim().isNotEmpty) ? donor.fullName : 'Valued Donor',
      donorPhone: donor?.phone ?? '',
      donorPan: donor?.panNumber ?? '',
      amount: d.amount,
      category: d.category,
      purpose: d.purpose.isNotEmpty ? d.purpose : '${d.category} Donation',
      schemeName: d.schemeName,
      businessDate: d.businessDate,
      bankName: 'Nesakkaram General Wing',
      accountName: 'Nesakkaram Trust',
      referenceNumber: d.upiReferenceNumber.isNotEmpty ? d.upiReferenceNumber : d.paymentGatewayPaymentId,
      verificationStatus: d.verificationStatus,
      message: 'Official Donation Receipt',
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReceiptViewScreen(receipt: receipt)),
    );
  }
}
