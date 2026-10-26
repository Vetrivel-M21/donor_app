import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/widgets/app_footer.dart';
import '../core/widgets/official_receipt_card.dart';
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
  final GlobalKey _receiptKey = GlobalKey();
  bool _isExporting = false;

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

  Future<void> _shareOrDownloadReceipt() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final boundary = _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Receipt view not ready. Please try again.');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to generate receipt image data.');
      }
      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final cleanNum = widget.receipt.donationNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final filePath = '${tempDir.path}/Nesakkaram_Receipt_$cleanNum.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes, flush: true);

      await Share.shareXFiles(
        [XFile(filePath, mimeType: 'image/png', name: 'Nesakkaram_Receipt_$cleanNum.png')],
        text: 'Nesakkaram Trust Official Donation Receipt - ${widget.receipt.donationNumber}\nAmount: ₹${widget.receipt.amount}',
        subject: 'Donation Receipt ${widget.receipt.donationNumber}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not export receipt: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
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
        actions: [
          IconButton(
            tooltip: 'Download / Share Receipt',
            onPressed: _isExporting ? null : _shareOrDownloadReceipt,
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.share_rounded),
          ),
        ],
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
            RepaintBoundary(
              key: _receiptKey,
              child: OfficialReceiptCard(
                receipt: widget.receipt,
                showShadow: true,
              ),
            ),

            const SizedBox(height: 20),

            // ── Download & Share Receipt Action Button ──────────────────────
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              onPressed: _isExporting ? null : _shareOrDownloadReceipt,
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded, size: 20),
              label: Text(
                _isExporting ? 'Preparing Receipt Image...' : 'Download / Share Receipt',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),

            const SizedBox(height: 14),

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
