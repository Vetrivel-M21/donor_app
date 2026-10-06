import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/constants/api_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_footer.dart';
import '../core/widgets/donation_stepper.dart';
import '../models/models.dart';
import '../providers/donor_portal_providers.dart';
import 'payment_screen.dart';

class DonationSelectionScreen extends ConsumerStatefulWidget {
  const DonationSelectionScreen({super.key});

  @override
  ConsumerState<DonationSelectionScreen> createState() => _DonationSelectionScreenState();
}

class _DonationSelectionScreenState extends ConsumerState<DonationSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _personNameCtrl = TextEditingController();
  final _relationshipCtrl = TextEditingController();

  String _selectedCategory = 'FOOD';
  String _selectedHome = 'OLD_AGE_HOME';
  PublicScheme? _selectedScheme;
  int _units = 1;
  String _eventType = '';
  DateTime? _eventDate;

  static Map<String, dynamic> _getHomeVisual(TrustHomeItem home) {
    switch (home.homeKey) {
      case 'OLD_AGE_HOME':
        return {
          'icon': Icons.elderly_rounded,
          'color': const Color(0xFFD97706),
          'badge': 'Senior Care Wing',
          'isBranch': false,
        };
      case 'CHILDREN_HOME':
        return {
          'icon': Icons.child_care_rounded,
          'color': const Color(0xFF059669),
          'badge': 'Child Welfare Wing',
          'isBranch': false,
        };
      case 'ADOPTION_HOME':
        return {
          'icon': Icons.family_restroom_rounded,
          'color': const Color(0xFF7C3AED),
          'badge': 'Adoption Agency',
          'isBranch': false,
        };
      default:
        final isBranch = home.homeKey.startsWith('BRANCH_');
        return {
          'icon': isBranch ? Icons.account_balance_rounded : Icons.volunteer_activism_rounded,
          'color': isBranch ? const Color(0xFF0284C7) : const Color(0xFF4F46E5),
          'badge': isBranch ? 'Trust Branch' : 'Dedicated Wing',
          'isBranch': isBranch,
        };
    }
  }

  static const List<Map<String, dynamic>> _categories = [
    {'key': 'FOOD', 'label': 'Food / Annadhanam', 'icon': Icons.soup_kitchen_rounded, 'color': Color(0xFFD97706)},
    {'key': 'MEDICINE', 'label': 'Medicine / Health', 'icon': Icons.medical_services_rounded, 'color': Color(0xFF059669)},
    {'key': 'EDUCATION', 'label': 'Education Aid', 'icon': Icons.school_rounded, 'color': Color(0xFF2563EB)},
    {'key': 'GENERAL', 'label': 'General Trust', 'icon': Icons.temple_hindu_rounded, 'color': Color(0xFF7C3AED)},
    {'key': 'OTHER', 'label': 'Special Cause', 'icon': Icons.volunteer_activism_rounded, 'color': Color(0xFFDB2777)},
  ];

  static const List<String> _eventTypes = [
    'Birthday',
    'Wedding Anniversary',
    'In Memory Of (Ninaivu Naal)',
    'Temple Festival / Pooja',
    'Family Well-being / Prarthanai',
    'Special Occasion',
  ];

  @override
  void initState() {
    super.initState();
    final draft = ref.read(donationDraftProvider);
    _selectedHome = draft.trustHome.isNotEmpty ? draft.trustHome : 'OLD_AGE_HOME';
    _selectedCategory = draft.category.isNotEmpty ? draft.category : 'FOOD';
    _selectedScheme = draft.selectedScheme;
    _units = draft.schemeUnits > 0 ? draft.schemeUnits : 1;
    if (draft.amount > Decimal.zero) _amountCtrl.text = draft.amount.toString();
    _reasonCtrl.text = draft.reason;
    _eventType = draft.eventType;
    _personNameCtrl.text = draft.eventPersonName;
    _relationshipCtrl.text = draft.relationshipToDonor;
    if (draft.eventDate.isNotEmpty) {
      try { _eventDate = DateTime.parse(draft.eventDate); } catch (_) {}
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    _personNameCtrl.dispose();
    _relationshipCtrl.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String cat) {
    setState(() {
      _selectedCategory = cat;
      if (cat != 'FOOD') _selectedScheme = null;
    });
    ref.read(donationDraftProvider.notifier).setCategory(cat);
  }

  void _onHomeChanged(String homeKey) {
    setState(() {
      _selectedHome = homeKey;
    });
    ref.read(donationDraftProvider.notifier).setTrustHome(homeKey);
  }

  void _onSchemeSelected(PublicScheme scheme) {
    setState(() {
      _selectedScheme = scheme;
      _units = 1;
      _amountCtrl.text = (scheme.defaultAmount * Decimal.fromInt(_units)).toString();
    });
    ref.read(donationDraftProvider.notifier).selectFoodScheme(scheme, _units);
  }

  void _updateUnits(int delta) {
    if (_selectedScheme == null) return;
    final newUnits = _units + delta;
    if (newUnits < 1) return;
    setState(() {
      _units = newUnits;
      _amountCtrl.text = (_selectedScheme!.defaultAmount * Decimal.fromInt(_units)).toString();
    });
    ref.read(donationDraftProvider.notifier).selectFoodScheme(_selectedScheme!, _units);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  void _onProceedToPayment() {
    if (!_formKey.currentState!.validate()) return;
    final amt = Decimal.tryParse(_amountCtrl.text.trim()) ?? Decimal.zero;
    if (amt <= Decimal.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a donation amount greater than 0')),
      );
      return;
    }
    final notifier = ref.read(donationDraftProvider.notifier);
    notifier.setTrustHome(_selectedHome);
    notifier.setCategory(_selectedCategory);
    if (_selectedCategory == 'FOOD' && _selectedScheme != null) {
      notifier.selectFoodScheme(_selectedScheme!, _units);
    } else {
      notifier.setDirectAmount(amt);
    }
    notifier.setReason(_reasonCtrl.text.trim());
    notifier.setEventDetails(
      eventType: _eventType,
      eventPersonName: _personNameCtrl.text.trim(),
      eventDate: _eventDate != null ? DateFormat('yyyy-MM-dd').format(_eventDate!) : '',
      relationshipToDonor: _relationshipCtrl.text.trim(),
    );
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaymentScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final schemesAsync = ref.watch(schemesFutureProvider);
    final configAsync = ref.watch(appDonationConfigFutureProvider);

    final homesList = configAsync.maybeWhen(
      data: (config) => config.activeHomes,
      orElse: () => AppDonationConfig.defaultHomes,
    );

    // Ensure selected home exists in active homes
    if (homesList.isNotEmpty && !homesList.any((h) => h.homeKey == _selectedHome)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedHome = homesList.first.homeKey;
          });
          ref.read(donationDraftProvider.notifier).setTrustHome(_selectedHome);
        }
      });
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Cause & Scheme', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 17)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DonationStepper(currentStep: 2),
                const SizedBox(height: 20),

                // ── Trust Home / Branch Selection (Dynamic & Modern) ────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Trust Wing / Branch *',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        '${homesList.length} Active Options',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose which wing or branch your contribution directly empowers:',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 12),

                Column(
                  children: homesList.map((home) {
                    final isSelected = _selectedHome == home.homeKey;
                    final meta = _getHomeVisual(home);
                    final color = meta['color'] as Color;
                    final icon = meta['icon'] as IconData;
                    final badge = meta['badge'] as String;
                    final isBranch = meta['isBranch'] as bool;
                    final hasUpiOrQR = home.upiId.isNotEmpty || home.qrCodePath.isNotEmpty;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _onHomeChanged(home.homeKey),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: isDark ? 0.22 : 0.07)
                                : (isDark ? AppTheme.darkCard : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : (isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Wing/Branch Icon Squircle or Custom Logo
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isSelected ? color : color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: home.logoPath.isNotEmpty
                                        ? Image.network(
                                            ApiConstants.assetUrl(home.logoPath),
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Icon(
                                              icon,
                                              color: isSelected ? Colors.white : color,
                                              size: 23,
                                            ),
                                          )
                                        : Icon(
                                            icon,
                                            color: isSelected ? Colors.white : color,
                                            size: 23,
                                          ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Name & Badge
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                home.homeName,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                              decoration: BoxDecoration(
                                                color: color.withValues(alpha: 0.14),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: color.withValues(alpha: 0.25)),
                                              ),
                                              child: Text(
                                                badge,
                                                style: GoogleFonts.nunito(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: color,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (home.homeNameTamil.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            home.homeNameTamil,
                                            style: GoogleFonts.nunito(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // Selection Indicator
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? color : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? color
                                            : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                        : null,
                                  ),
                                ],
                              ),

                              if (home.description.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  home.description,
                                  style: GoogleFonts.nunito(
                                    fontSize: 11.5,
                                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                    height: 1.3,
                                  ),
                                ),
                              ],

                              // Bottom Feature Chips (UPI & Branch indicators)
                              if (hasUpiOrQR || isBranch) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (hasUpiOrQR)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF059669).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.qr_code_rounded, size: 11, color: Color(0xFF059669)),
                                            const SizedBox(width: 3.5),
                                            Text(
                                              'Instant UPI & QR Scan',
                                              style: GoogleFonts.nunito(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF059669),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (hasUpiOrQR && isBranch) const SizedBox(width: 6),
                                    if (isBranch)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.location_on_rounded, size: 11, color: Color(0xFF0284C7)),
                                            const SizedBox(width: 3.5),
                                            Text(
                                              'Branch Location',
                                              style: GoogleFonts.nunito(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF0284C7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // ── Category Selection ──────────────────────────────────────
                Text(
                  'Select Donation Category *',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.1,
                  children: _categories.map((c) {
                    final isSelected = _selectedCategory == c['key'];
                    final color = c['color'] as Color;
                    return GestureDetector(
                      onTap: () => _onCategoryChanged(c['key'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected ? color : (isDark ? AppTheme.darkCard : Colors.white),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? color : (isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(c['icon'] as IconData, size: 26, color: isSelected ? Colors.white : color),
                            const SizedBox(height: 6),
                            Text(
                              c['label'] as String,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : (isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // ── Food Schemes ────────────────────────────────────────────
                if (_selectedCategory == 'FOOD') ...[
                  Row(
                    children: [
                      Text(
                        'Select Food Scheme *',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Annadhanam',
                          style: GoogleFonts.nunito(
                            color: isDark ? const Color(0xFFFBBF24) : AppTheme.primaryDark,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  schemesAsync.when(
                    data: (schemes) {
                      final foodSchemes = schemes.where((s) => s.category.toUpperCase() == 'FOOD').toList();
                      if (foodSchemes.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkCard : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'No pre-set schemes currently active. Enter your custom donation amount below.',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: foodSchemes.map((s) {
                          final isSelected = _selectedScheme?.id == s.id;
                          return GestureDetector(
                            onTap: () => _onSchemeSelected(s),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? AppTheme.primaryDark.withValues(alpha: 0.3) : AppTheme.primaryLight.withValues(alpha: 0.5))
                                    : (isDark ? AppTheme.darkCard : Colors.white),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primary : (isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? AppTheme.primary : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected ? AppTheme.primary : (isDark ? AppTheme.darkBorder : const Color(0xFF9CA3AF)),
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.displayName,
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected
                                                ? (isDark ? const Color(0xFFFBBF24) : AppTheme.primaryDark)
                                                : (isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827)),
                                          ),
                                        ),
                                        if (s.description.isNotEmpty)
                                          Text(
                                            s.description,
                                            style: GoogleFonts.nunito(
                                              fontSize: 11,
                                              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '₹${s.defaultAmount}/meal',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppTheme.primary))),
                    error: (e, _) => Text('Could not load schemes: $e', style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),

                  if (_selectedScheme != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : AppTheme.primaryLight.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: isDark ? 0.4 : 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Number of meals:', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13)),
                              Text(
                                '₹${_selectedScheme!.defaultAmount} × $_units = ₹${_selectedScheme!.defaultAmount * Decimal.fromInt(_units)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _unitBtn(context, Icons.remove_rounded, _units > 1 ? () => _updateUnits(-1) : null),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('$_units', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900)),
                              ),
                              _unitBtn(context, Icons.add_rounded, () => _updateUnits(1)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                // ── Reason Field ───────────────────────────────────────────
                if (_selectedCategory != 'FOOD') ...[
                  Text(
                    'Donation Purpose / Reason *',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _reasonCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Support hospital medicines / Student tuition fee',
                      prefixIcon: Icon(Icons.edit_note_rounded, color: Color(0xFF6B7280)),
                    ),
                    validator: (v) {
                      if (_selectedCategory != 'FOOD' && (v == null || v.trim().isEmpty)) {
                        return 'Please provide a reason / specific purpose';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Donation Amount ────────────────────────────────────────
                const SizedBox(height: 8),
                Text(
                  'Donation Amount (INR) *',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 14, right: 8, top: 12, bottom: 12),
                      child: Text(
                        '₹',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isDark ? const Color(0xFFFBBF24) : AppTheme.primaryDark,
                        ),
                      ),
                    ),
                    hintText: '0.00',
                    hintStyle: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                      color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter donation amount';
                    final num = Decimal.tryParse(v.trim());
                    if (num == null || num <= Decimal.zero) return 'Amount must be greater than 0';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [500, 1000, 2500, 5000, 10000].map((amt) {
                    return ActionChip(
                      label: Text(
                        '₹$amt',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFFBBF24) : AppTheme.primaryDark,
                        ),
                      ),
                      backgroundColor: isDark ? AppTheme.darkCard : AppTheme.primaryLight,
                      side: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFFCD34D)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      onPressed: () {
                        setState(() {
                          _amountCtrl.text = amt.toString();
                          _selectedScheme = null;
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // ── Dedicate Donation ──────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(14),
                    color: isDark ? AppTheme.darkCard : Colors.white,
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF831843).withValues(alpha: 0.3) : const Color(0xFFFDF2F8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFDB2777), size: 18),
                      ),
                      title: Text(
                        'Dedicate this Donation (Optional)',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF374151),
                        ),
                      ),
                      subtitle: Text(
                        'Birthday, Memorial, Wedding Anniversary',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        DropdownButtonFormField<String>(
                          value: _eventType.isNotEmpty ? _eventType : null,
                          decoration: const InputDecoration(labelText: 'Occasion Type'),
                          items: _eventTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.nunito(fontSize: 13)))).toList(),
                          onChanged: (v) => setState(() => _eventType = v ?? ''),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _personNameCtrl,
                          decoration: const InputDecoration(labelText: 'In the name of (Person Name)'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _pickDate,
                                child: InputDecorator(
                                  decoration: const InputDecoration(labelText: 'Occasion Date'),
                                  child: Text(
                                    _eventDate != null ? DateFormat('dd MMM yyyy').format(_eventDate!) : 'Select Date',
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      color: _eventDate != null
                                          ? (isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827))
                                          : const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _relationshipCtrl,
                                decoration: const InputDecoration(labelText: 'Relationship (e.g. Mother)'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _onProceedToPayment,
                  icon: const Icon(Icons.payment_rounded, color: Colors.white),
                  label: Text('Proceed to Payment', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
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

  Widget _unitBtn(BuildContext context, IconData icon, VoidCallback? onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null ? AppTheme.primary : (isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: onTap != null ? Colors.white : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
          size: 20,
        ),
      ),
    );
  }
}
