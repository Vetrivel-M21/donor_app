import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/api_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_footer.dart';
import '../models/models.dart';
import '../providers/donor_portal_providers.dart';
import 'donor_details_screen.dart';
import 'donation_history_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary, width: 1.5),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/high_resolution_ultra_clean_vector_style_circular_emblem_badge_logo_based.png',
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Nesakkaram Trust',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'My Donations',
            icon: Icon(
              Icons.receipt_long_rounded,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.secondary,
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DonationHistoryScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          ref.invalidate(dashboardFutureProvider);
          ref.invalidate(schemesFutureProvider);
          ref.invalidate(appDonationConfigFutureProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroBanner(context, dashAsync),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _buildDonateCta(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildTrustWingsSection(context, ref),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildImpactSection(context, dashAsync),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _buildCausesSection(context, dashAsync),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildOccasionsSection(context, dashAsync),
              ),
              const SizedBox(height: 20),
              const AppFooter(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
            label: Text(
              'Donate Now',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DonorDetailsScreen()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, AsyncValue<PublicDashboard> dashAsync) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F0D2A), Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFFB45309)],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.15),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dashAsync.when(
                  data: (d) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFFBBF24), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/high_resolution_ultra_clean_vector_style_circular_emblem_badge_logo_based.png',
                                width: 54,
                                height: 54,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.trustName.isNotEmpty ? d.trustName : 'Nesakkaram Trust',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  d.tagline.isNotEmpty ? d.tagline : 'Service to Humanity • Care & Dignity',
                                  style: GoogleFonts.nunito(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, color: Color(0xFFFBBF24), size: 14),
                            const SizedBox(width: 6),
                            Text(
                              d.taxExemption,
                              style: GoogleFonts.nunito(
                                color: const Color(0xFFFBBF24),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  loading: () => const Center(
                    child: SizedBox(
                      height: 40,
                      width: 40,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                  error: (_, __) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nesakkaram Trust',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Selfless Service & Annadhanam for All',
                        style: GoogleFonts.nunito(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonateCta(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 3,
      shadowColor: AppTheme.primary.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: isDark
                ? [AppTheme.primaryDark.withValues(alpha: 0.35), AppTheme.darkCard]
                : [AppTheme.primaryLight.withValues(alpha: 0.7), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.volunteer_activism_rounded, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Direct Trust Contribution',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Support Annadhanam, Medicine, Education & More',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DonationHistoryScreen()),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFF9CA3AF)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size.fromHeight(42),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'My History',
                      style: GoogleFonts.nunito(
                        color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DonorDetailsScreen()),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size.fromHeight(42),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text('Donate Now', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustWingsSection(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final configAsync = ref.watch(appDonationConfigFutureProvider);
    final homesList = configAsync.maybeWhen(
      data: (config) => config.activeHomes,
      orElse: () => AppDonationConfig.defaultHomes,
    );

    const defaultWingsMeta = [
      {
        'key': 'OLD_AGE_HOME',
        'title': 'Old Age Home',
        'tamil': 'முதியோர்கள் இல்லம்',
        'badge': 'Senior Care',
        'icon': Icons.elderly_rounded,
        'color': Color(0xFFD97706),
        'desc': 'Providing dignified shelter, healthcare & daily annadhanam for senior citizens',
      },
      {
        'key': 'CHILDREN_HOME',
        'title': 'Children Home',
        'tamil': 'குழந்தைகள் இல்லம்',
        'badge': 'Child Welfare',
        'icon': Icons.child_care_rounded,
        'color': Color(0xFF059669),
        'desc': 'Quality education, holistic care & nutritious meals for underprivileged children',
      },
      {
        'key': 'ADOPTION_HOME',
        'title': 'Children Adoption Home',
        'tamil': 'சிறப்பு தத்தெடுத்தல் மையம்',
        'badge': 'Adoption Agency',
        'icon': Icons.family_restroom_rounded,
        'color': Color(0xFF7C3AED),
        'desc': 'Specialised adoption agency offering infant medical care & loving families',
      },
    ];

    final effectiveHomes = homesList.isNotEmpty ? homesList : AppDonationConfig.defaultHomes;
    final wings = effectiveHomes.map((h) {
      final meta = defaultWingsMeta.cast<Map<String, dynamic>>().firstWhere(
        (m) => m['key'] == h.homeKey,
        orElse: () => <String, dynamic>{},
      );
      final isBranch = h.homeKey.startsWith('BRANCH_') || (!['OLD_AGE_HOME', 'CHILDREN_HOME', 'ADOPTION_HOME'].contains(h.homeKey));
      final color = meta.isNotEmpty ? meta['color'] as Color : (isBranch ? const Color(0xFF0284C7) : const Color(0xFF4F46E5));
      final icon = meta.isNotEmpty ? meta['icon'] as IconData : (isBranch ? Icons.account_balance_rounded : Icons.volunteer_activism_rounded);
      final badge = meta.isNotEmpty ? meta['badge'] as String : (isBranch ? 'Trust Branch' : 'Dedicated Wing');

      return {
        'key': h.homeKey,
        'title': h.homeName.isNotEmpty ? h.homeName : (meta['title'] as String? ?? 'Trust Home'),
        'tamil': h.homeNameTamil.isNotEmpty ? h.homeNameTamil : (meta['tamil'] as String? ?? ''),
        'badge': badge,
        'icon': icon,
        'color': color,
        'desc': h.description.isNotEmpty ? h.description : (meta['desc'] as String? ?? ''),
        'logoPath': h.logoPath,
      };
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Our Three Homes',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
              ),
            ),
            Text(
              'நேசக்கரம் இல்லங்கள்',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...wings.map((w) {
          final color = w['color'] as Color;
          final logoPath = w['logoPath'] as String? ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () {
                ref.read(donationDraftProvider.notifier).setTrustHome(w['key'] as String);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DonorDetailsScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: logoPath.isNotEmpty
                          ? Image.network(
                              ApiConstants.assetUrl(logoPath),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(w['icon'] as IconData, color: color, size: 26),
                            )
                          : Icon(w['icon'] as IconData, color: color, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                w['title'] as String,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  w['badge'] as String,
                                  style: GoogleFonts.nunito(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            w['tamil'] as String,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            w['desc'] as String,
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Donate',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildImpactSection(BuildContext context, AsyncValue<PublicDashboard> dashAsync) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Charitable Impact',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        dashAsync.when(
          data: (d) => Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppTheme.primaryDark.withValues(alpha: 0.3), AppTheme.darkCard]
                        : [const Color(0xFFFEF3C7).withValues(alpha: 0.8), const Color(0xFFFEF9EC)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppTheme.primary.withValues(alpha: 0.4) : const Color(0xFFFCD34D),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDark ? AppTheme.primary : const Color(0xFFFCD34D)).withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.rice_bowl_rounded,
                        color: isDark ? const Color(0xFFFBBF24) : AppTheme.primaryDark,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        d.annadhanamDaily,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statItem(context, 'Total Donors', '${d.totalDonors}', Icons.group_rounded, const Color(0xFF2563EB)),
                  const SizedBox(width: 10),
                  _statItem(context, 'Donations', '${d.totalDonations}', Icons.favorite_rounded, const Color(0xFFDC2626)),
                  const SizedBox(width: 10),
                  _statItem(context, 'Active Schemes', '${d.activeSchemes}', Icons.ramen_dining_rounded, AppTheme.primary),
                ],
              ),
            ],
          ),
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppTheme.primary))),
          error: (err, _) => _buildErrorRetry(context),
        ),
      ],
    );
  }

  Widget _buildErrorRetry(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: isDark ? const Color(0xFFFBBF24) : AppTheme.primaryDark, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Could not load data. Pull down to refresh.',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(BuildContext context, String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 10,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCausesSection(BuildContext context, AsyncValue<PublicDashboard> dashAsync) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Donation Causes',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        dashAsync.when(
          data: (d) => d.categories.isEmpty
              ? const SizedBox.shrink()
              : SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemCount: d.categories.length,
                    itemBuilder: (_, i) => _causeCard(context, d.categories[i]),
                  ),
                ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _causeCard(BuildContext context, DonationCategory cat) {
    IconData iconData;
    List<Color> gradientColors;

    switch (cat.key) {
      case 'FOOD':
        iconData = Icons.soup_kitchen_rounded;
        gradientColors = [const Color(0xFFD97706), const Color(0xFFF59E0B)];
        break;
      case 'MEDICINE':
        iconData = Icons.medical_services_rounded;
        gradientColors = [const Color(0xFF059669), const Color(0xFF10B981)];
        break;
      case 'EDUCATION':
        iconData = Icons.school_rounded;
        gradientColors = [const Color(0xFF2563EB), const Color(0xFF3B82F6)];
        break;
      case 'GENERAL':
        iconData = Icons.temple_hindu_rounded;
        gradientColors = [const Color(0xFF7C3AED), const Color(0xFF8B5CF6)];
        break;
      default:
        iconData = Icons.volunteer_activism_rounded;
        gradientColors = [const Color(0xFFDB2777), const Color(0xFFEC4899)];
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DonorDetailsScreen(initialCategory: cat.key)),
      ),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: gradientColors[0].withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, color: Colors.white, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat.title,
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('Donate', style: GoogleFonts.nunito(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 12),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccasionsSection(BuildContext context, AsyncValue<PublicDashboard> dashAsync) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return dashAsync.when(
      data: (d) {
        if (d.upcomingOccasions.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming Spiritual Occasions',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            ...d.upcomingOccasions.map(
              (o) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.event_available_rounded, color: AppTheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                              o.description,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                o.date,
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFFBBF24) : AppTheme.primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
