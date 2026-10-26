import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trust_donor_app/main.dart';
import 'package:trust_donor_app/models/models.dart';
import 'package:trust_donor_app/providers/donor_portal_providers.dart';

void main() {
  testWidgets('Donor app smoke test with mock data', (WidgetTester tester) async {
    const mockDashboard = PublicDashboard(
      trustName: 'Sri Agathiyar Trust',
      tagline: 'Selfless Service',
      taxExemption: 'Official Receipt',
      activeSchemes: 4,
      totalDonors: 120,
      totalDonations: 350,
      annadhanamDaily: '500+ meals daily',
      categories: [
        DonationCategory(key: 'FOOD', title: 'Food', icon: 'food', description: 'Annadhanam meals'),
      ],
      upcomingOccasions: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardFutureProvider.overrideWith((ref) async => mockDashboard),
          schemesFutureProvider.overrideWith((ref) async => []),
          appDonationConfigFutureProvider.overrideWith(
            (ref) async => const AppDonationConfig(
              bankName: 'SBI',
              accountName: 'Trust',
              accountNumberMasked: 'XXXX1234',
              ifscCode: 'SBIN0001234',
              branch: 'Chennai',
              upiId: 'trust@sbi',
              qrCodePath: '',
            ),
          ),
          savedPhoneProvider.overrideWith((ref) async => ''),
        ],
        child: const TrustDonorApp(),
      ),
    );

    // Initial frame
    await tester.pump();
    expect(find.text('Sri Agathiyar Trust'), findsWidgets);
    expect(find.text('Selfless Service'), findsOneWidget);
    expect(find.text('Donate Now'), findsWidgets);
  });
}
