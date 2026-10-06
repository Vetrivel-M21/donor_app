import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_footer.dart';
import '../models/models.dart';
import 'donation_history_screen.dart';

class DonationSuccessScreen extends StatefulWidget {
  const DonationSuccessScreen({super.key, required this.receipt});

  final DonationReceipt receipt;

  @override
  State<DonationSuccessScreen> createState() => _DonationSuccessScreenState();
}

class _DonationSuccessScreenState extends State<DonationSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPending = widget.receipt.verificationStatus == 'PENDING';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          isPending ? 'Donation Submitted' : 'Donation Confirmed',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── Animated Success / Pending Header ───────────────────────────
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    children: [
                      // Celebration ring
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPending
                                  ? const Color(0xFFFEF3C7).withValues(alpha: isDark ? 0.2 : 0.6)
                                  : const Color(0xFFD1FAE5).withValues(alpha: isDark ? 0.2 : 0.6),
                            ),
                          ),
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPending
                                  ? (isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7))
                                  : (isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5)),
                            ),
                            child: Icon(
                              isPending ? Icons.hourglass_top_rounded : Icons.check_circle_rounded,
                              color: isPending ? const Color(0xFFD97706) : const Color(0xFF059669),
                              size: 50,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isPending ? 'Donation Submitted! 🙏' : 'Thank You! 🙏',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.receipt.message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Official E-Receipt Card ─────────────────────────────────────
            Card(
              elevation: 3,
              shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPending ? 'PAYMENT ACKNOWLEDGEMENT' : 'OFFICIAL E-RECEIPT',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: isDark ? const Color(0xFFFBBF24) : AppTheme.primaryDark,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Nesakkaram Trust',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isPending
                                ? (isDark ? const Color(0xFF78350F).withValues(alpha: 0.4) : const Color(0xFFFEF3C7))
                                : (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFECFDF5)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isPending ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isPending ? Icons.schedule_rounded : Icons.verified_rounded,
                                size: 14,
                                color: isPending ? const Color(0xFFD97706) : const Color(0xFF059669),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isPending ? 'PENDING VERIFICATION' : 'VERIFIED',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isPending ? const Color(0xFFD97706) : const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _receiptRow(context, 'Donation Number', widget.receipt.donationNumber),
                    _receiptRow(
                      context,
                      'Voucher Receipt No.',
                      isPending ? 'Pending Staff Approval' : widget.receipt.voucherNumber,
                    ),
                    _receiptRow(context, 'Business Date', widget.receipt.businessDate),
                    _receiptRow(context, 'Donor Name', widget.receipt.donorName),
                    _receiptRow(context, 'Mobile Number', widget.receipt.donorPhone),
                    if (widget.receipt.donorPan.isNotEmpty)
                      _receiptRow(context, 'PAN Number', widget.receipt.donorPan),
                    _receiptRow(context, 'Category / Purpose', widget.receipt.purpose),
                    _receiptRow(context, 'Target Branch / Wing', widget.receipt.bankName),
                    _receiptRow(context, 'Payment Reference (UTR)', widget.receipt.referenceNumber),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Amount Paid',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '₹${widget.receipt.amount}',
                            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF059669)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── 80G Tax Exemption & Verification Notice ─────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : (isPending ? const Color(0xFFFFFBEB) : AppTheme.primaryLight.withValues(alpha: 0.6)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppTheme.primary.withValues(alpha: 0.3) : (isPending ? const Color(0xFFFDE68A) : const Color(0xFFFCD34D))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.primary.withValues(alpha: 0.2) : (isPending ? const Color(0xFFFEF3C7) : AppTheme.primaryLight),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPending ? Icons.verified_user_outlined : Icons.shield_rounded,
                      color: isDark ? const Color(0xFFFBBF24) : (isPending ? const Color(0xFFB45309) : AppTheme.primaryDark),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isPending
                          ? 'Your UPI transaction reference has been recorded. Once the branch accounts team verifies the credit in the bank statement, your official Section 80G tax receipt will be unlocked.'
                          : 'Donations to Nesakkaram Trust are eligible for tax deduction under Section 80G of the Income Tax Act.',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Navigation Buttons ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.history_rounded, size: 18),
                    label: Text('My Donations', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const DonationHistoryScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.home_rounded, size: 18),
                    label: Text('Back to Home', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const AppFooter(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(BuildContext context, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
