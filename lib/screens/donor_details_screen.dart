import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_footer.dart';
import '../core/widgets/donation_stepper.dart';
import '../providers/donor_portal_providers.dart';
import 'donation_selection_screen.dart';

class DonorDetailsScreen extends ConsumerStatefulWidget {
  const DonorDetailsScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  ConsumerState<DonorDetailsScreen> createState() => _DonorDetailsScreenState();
}

class _DonorDetailsScreenState extends ConsumerState<DonorDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();

  bool _isCheckingPhone = false;
  bool _foundExistingDonor = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPrefill());
  }

  Future<void> _initPrefill() async {
    final draft = ref.read(donationDraftProvider);
    if (widget.initialCategory != null) {
      ref.read(donationDraftProvider.notifier).setCategory(widget.initialCategory!);
    }
    if (draft.phone.isNotEmpty) {
      _phoneCtrl.text = draft.phone;
      _nameCtrl.text = draft.fullName;
      _emailCtrl.text = draft.email;
      _panCtrl.text = draft.panNumber;
      _addressCtrl.text = draft.addressLine;
      _cityCtrl.text = draft.city;
      _stateCtrl.text = draft.state;
      _pincodeCtrl.text = draft.pincode;
      return;
    }
    final savedPhone = await ref.read(savedPhoneProvider.future);
    if (savedPhone.isNotEmpty) {
      _phoneCtrl.text = savedPhone;
      _checkPhone(savedPhone);
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _panCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkPhone(String phone) async {
    final cleanPhone = phone.trim();
    if (cleanPhone.length != 10) return;
    setState(() { _isCheckingPhone = true; _foundExistingDonor = false; });
    try {
      final api = ref.read(apiClientProvider);
      final history = await api.getDonorHistory(cleanPhone);
      if (history.donor != null) {
        final d = history.donor!;
        setState(() {
          _foundExistingDonor = true;
          if (_nameCtrl.text.isEmpty) _nameCtrl.text = d.fullName;
          if (_emailCtrl.text.isEmpty) _emailCtrl.text = d.email;
          if (_panCtrl.text.isEmpty) _panCtrl.text = d.panNumber;
        });
      }
    } catch (_) {}
    finally { if (mounted) setState(() => _isCheckingPhone = false); }
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(donationDraftProvider.notifier);
    notifier.setPhone(_phoneCtrl.text.trim());
    notifier.setDonorDetails(
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      panNumber: _panCtrl.text.trim().toUpperCase(),
      addressLine: _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      pincode: _pincodeCtrl.text.trim(),
    );
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DonationSelectionScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Donor Details', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 17)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DonationStepper(currentStep: 1),
                const SizedBox(height: 20),

                // Info Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : AppTheme.primaryLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: isDark ? 0.4 : 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: isDark ? const Color(0xFFFBBF24) : AppTheme.primaryDark, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your details are used to issue an official donation receipt.',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_foundExistingDonor) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Welcome back! Your registered details have been auto-filled.',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Section: Personal Info ──────────────────────────────────
                _sectionHeader(context, 'Personal Information', Icons.person_outline_rounded),
                const SizedBox(height: 12),

                _fieldLabel(context, 'Mobile Number *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    hintText: '10 digit mobile number',
                    prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF6B7280), size: 20),
                    suffixIcon: _isCheckingPhone
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
                          )
                        : null,
                  ),
                  onChanged: (v) { if (v.trim().length == 10) _checkPhone(v); },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Mobile number is required';
                    if (v.trim().length != 10) return 'Please enter a valid 10-digit number';
                    return null;
                  },
                ),

                const SizedBox(height: 14),
                _fieldLabel(context, 'Full Name *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Enter donor full name',
                    prefixIcon: Icon(Icons.person_rounded, color: Color(0xFF6B7280), size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Full name is required';
                    return null;
                  },
                ),

                const SizedBox(height: 14),
                _fieldLabel(context, 'Email Address (Optional)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'For sending donation e-receipt',
                    prefixIcon: Icon(Icons.email_rounded, color: Color(0xFF6B7280), size: 20),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Section: Identification Details ─────────────────────────
                _sectionHeader(context, 'Identification Details', Icons.badge_outlined),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Text(
                      'PAN Number',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Optional',
                        style: GoogleFonts.nunito(
                          color: isDark ? const Color(0xFFFBBF24) : AppTheme.primaryDark,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _panCtrl,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [LengthLimitingTextInputFormatter(10)],
                  decoration: const InputDecoration(
                    hintText: 'ABCDE1234F',
                    prefixIcon: Icon(Icons.badge_rounded, color: Color(0xFF6B7280), size: 20),
                  ),
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
                      if (!panRegex.hasMatch(v.trim().toUpperCase())) {
                        return 'Enter a valid 10-character PAN (e.g. ABCDE1234F)';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // ── Section: Address (Expandable) ───────────────────────────
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.home_rounded, color: Color(0xFF2563EB), size: 18),
                    ),
                    title: Text(
                      'Postal Address (Optional)',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                      ),
                    ),
                    children: [
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _addressCtrl,
                        decoration: const InputDecoration(hintText: 'Street / Door / Area'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityCtrl,
                              decoration: const InputDecoration(hintText: 'City'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _stateCtrl,
                              decoration: const InputDecoration(hintText: 'State'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _pincodeCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: const InputDecoration(hintText: 'Pincode (6 digits)'),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _onContinue,
                  icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                  label: Text('Continue to Donation Details', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
                ),

                const SizedBox(height: 20),
                const AppFooter(),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: GoogleFonts.nunito(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
      ),
    );
  }
}
