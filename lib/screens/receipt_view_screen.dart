import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/widgets/official_receipt_card.dart';
import '../models/models.dart';

class ReceiptViewScreen extends StatefulWidget {
  const ReceiptViewScreen({super.key, required this.receipt});

  final DonationReceipt receipt;

  @override
  State<ReceiptViewScreen> createState() => _ReceiptViewScreenState();
}

class _ReceiptViewScreenState extends State<ReceiptViewScreen> {
  final GlobalKey _receiptKey = GlobalKey();
  bool _isExporting = false;

  Future<void> _shareOrDownloadReceipt() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      // Find the render object of the receipt card
      final boundary = _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Receipt view not ready. Please try again.');
      }

      // Capture at high resolution (3x)
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to generate receipt image data.');
      }
      final pngBytes = byteData.buffer.asUint8List();

      // Save to temporary file for sharing
      final tempDir = await getTemporaryDirectory();
      final cleanNum = widget.receipt.donationNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final filePath = '${tempDir.path}/Nesakkaram_Receipt_$cleanNum.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes, flush: true);

      // Trigger native share sheet (allowing save to device, WhatsApp, Drive, email, etc.)
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
    final invoiceNo = widget.receipt.voucherNumber.isNotEmpty
        ? widget.receipt.voucherNumber
        : widget.receipt.donationNumber;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Donation Receipt',
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Receipt Number Chip Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF059669)),
                      const SizedBox(width: 6),
                      Text(
                        'Verified Trust Receipt',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: invoiceNo));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Receipt number copied to clipboard!')),
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            invoiceNo,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Captured boundary containing the official receipt card
            RepaintBoundary(
              key: _receiptKey,
              child: OfficialReceiptCard(
                receipt: widget.receipt,
                showShadow: false,
              ),
            ),

            const SizedBox(height: 20),

            // Download & Share Primary Button
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

            const SizedBox(height: 10),

            // Secondary Close Button
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Back to History',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
