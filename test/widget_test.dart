import 'package:blobfiles/config/supabase_config.dart';
import 'package:blobfiles/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  });

  testWidgets('Landing page renders', (WidgetTester tester) async {
    await tester.pumpWidget(const BlobfilesApp());
    await tester.pumpAndSettle();

    expect(find.text('blobfiles'), findsOneWidget);
    expect(
      find.text('Your Content Archive • Clip • Organize • Share'),
      findsOneWidget,
    );
    expect(find.text('Get Started'), findsOneWidget);
  });
}