import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
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

  String _convertAmountToWords(Decimal amount) {
    final numVal = amount.toDouble();
    final intPart = numVal.floor();
    if (intPart <= 0) return 'Rupees Zero Only';

    const units = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten',
      'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
    ];
    const tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

    String numWords(int n) {
      if (n == 0) return '';
      if (n < 20) return units[n];
      if (n < 100) return '${tens[n ~/ 10]} ${units[n % 10]}'.trim();
      if (n < 1000) return '${units[n ~/ 100]} Hundred ${numWords(n % 100)}'.trim();
      if (n < 100000) return '${numWords(n ~/ 1000)} Thousand ${numWords(n % 1000)}'.trim();
      if (n < 10000000) return '${numWords(n ~/ 100000)} Lakh ${numWords(n % 100000)}'.trim();
      return '${numWords(n ~/ 10000000)} Crore ${numWords(n % 10000000)}'.trim();
    }

    return 'Rupees ${numWords(intPart)} Only';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPending = widget.receipt.verificationStatus == 'PENDING';

    final invoiceNo = widget.receipt.voucherNumber.isNotEmpty
        ? widget.receipt.voucherNumber
        : widget.receipt.donationNumber;

    final particularsMain = widget.receipt.purpose.isNotEmpty
        ? widget.receipt.purpose
        : '${widget.receipt.category} Donation';

    final particularsSub = [
      if (widget.receipt.schemeName.isNotEmpty) 'Scheme: ${widget.receipt.schemeName}',
      if (widget.receipt.category.isNotEmpty && widget.receipt.schemeName != widget.receipt.category)
        'Category: ${widget.receipt.category}',
      if (widget.receipt.bankName.isNotEmpty) 'Wing: ${widget.receipt.bankName}',
    ].join(' • ');

    final qrData = 'NESAKKARAM|${widget.receipt.donationNumber}|$invoiceNo|${widget.receipt.amount}|${widget.receipt.donorPhone}';

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
            const SizedBox(height: 12),

            // ── Animated Celebration Header ─────────────────────────────────
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPending
                                  ? const Color(0xFFFEF3C7).withValues(alpha: isDark ? 0.2 : 0.6)
                                  : const Color(0xFFD1FAE5).withValues(alpha: isDark ? 0.2 : 0.6),
                            ),
                          ),
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPending
                                  ? (isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7))
                                  : (isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5)),
                            ),
                            child: Icon(
                              isPending ? Icons.hourglass_top_rounded : Icons.check_circle_rounded,
                              color: isPending ? const Color(0xFFD97706) : const Color(0xFF059669),
                              size: 38,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isPending ? 'Donation Submitted! 🙏' : 'Thank You! 🙏',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.receipt.message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Official Receipt Card (Web-App Mirror Design) ────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Emerald Green Header (Matching Web App, Address Removed)
                  Container(
                    color: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.volunteer_activism_rounded,
                              color: Color(0xFF059669),
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NESAKKARAM TRUST',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isPending ? 'DONATION PAYMENT ACKNOWLEDGEMENT' : 'OFFICIAL DONATION RECEIPT',
                                style: GoogleFonts.nunito(
                                  color: const Color(0xFFD1FAE5),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Receipt White Sheet Body
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date & Invoice No
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DATE',
                                  style: GoogleFonts.nunito(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF94A3B8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.receipt.businessDate,
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'INVOICE NO',
                                  style: GoogleFonts.nunito(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF94A3B8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  invoiceNo,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 10),

                        // Received From / Donor
                        Text(
                          'RECEIVED FROM / DONOR',
                          style: GoogleFonts.nunito(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF94A3B8),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.receipt.donorName,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            if (widget.receipt.donorPhone.isNotEmpty)
                              Text(
                                'Mobile: +91 ${widget.receipt.donorPhone}',
                                style: GoogleFonts.nunito(fontSize: 11, color: const Color(0xFF475569)),
                              ),
                            if (widget.receipt.donorPan.isNotEmpty)
                              Text(
                                'PAN: ${widget.receipt.donorPan}',
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // 3. Particulars Table Header (Dark Slate #1E293B)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 26,
                                child: Text(
                                  'SL',
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'PARTICULARS',
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                'AMOUNT (₹)',
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Particulars Table Row
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 26,
                                child: Text(
                                  '1',
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      particularsMain,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF059669),
                                      ),
                                    ),
                                    if (particularsSub.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        particularsSub,
                                        style: GoogleFonts.nunito(
                                          fontSize: 10,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text(
                                '₹${widget.receipt.amount}',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Total Cost Bar (Dark Slate #1E293B)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Cost',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '₹${widget.receipt.amount}',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 4. Amount in Words (Amber Box #FFFBEB)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Text(
                            'Amount in Words: ${_convertAmountToWords(widget.receipt.amount)}',
                            style: GoogleFonts.nunito(
                              fontSize: 10.5,
                              color: const Color(0xFF92400E),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 5. Three Column Footer (Payment Details | QR Code | Signatory)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              // Column 1: Payment Details
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PAYMENT DETAILS',
                                      style: GoogleFonts.nunito(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      isPending ? 'Pending Verification' : 'Online Payment Received',
                                      style: GoogleFonts.outfit(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: isPending ? const Color(0xFFD97706) : const Color(0xFF059669),
                                      ),
                                    ),
                                    if (widget.receipt.referenceNumber.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Ref: ${widget.receipt.referenceNumber}',
                                        style: GoogleFonts.nunito(
                                          fontSize: 8.5,
                                          color: const Color(0xFF64748B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 3),
                                    Text(
                                      'Thanks for Your Support',
                                      style: GoogleFonts.nunito(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFB45309),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Column 2: QR Code
                              Expanded(
                                flex: 3,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    QrImageView(
                                      data: qrData,
                                      size: 52,
                                      version: QrVersions.auto,
                                      padding: EdgeInsets.zero,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Scan to verify',
                                      style: GoogleFonts.nunito(
                                        fontSize: 7.5,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Column 3: Authorized Signatory
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'For: NESAKKARAM TRUST',
                                      style: GoogleFonts.nunito(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF334155),
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                    const SizedBox(height: 22),
                                    Container(
                                      height: 1,
                                      width: 90,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Authorized Signatory',
                                      style: GoogleFonts.nunito(
                                        fontSize: 8,
                                        color: const Color(0xFF64748B),
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 6. Bottom Banner (Dark Slate #1E293B)
                  Container(
                    color: const Color(0xFF1E293B),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Text(
                      'Thank you for choosing NESAKKARAM TRUST — we appreciate your support!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),



            const SizedBox(height: 20),

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
}
