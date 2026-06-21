import 'package:blobfiles/widgets/centered_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('stretch children fill the centered column on wide viewports',
      (WidgetTester tester) async {
    const viewportWidth = 800.0;
    const columnKey = Key('stretch-column');
    const markerKey = Key('stretch-marker');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: viewportWidth,
            height: 600,
            child: CenteredScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                key: columnKey,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    key: markerKey,
                    height: 24,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final columnBox = tester.getRect(find.byKey(columnKey));
    final markerBox = tester.getRect(find.byKey(markerKey));

    expect(columnBox.width, CenteredScrollMetrics.defaultMaxWidth);
    expect(markerBox.width, CenteredScrollMetrics.defaultMaxWidth);
    expect(columnBox.center.dx, closeTo(viewportWidth / 2, 1));
  });

  testWidgets('stretch children fill the viewport on narrow screens',
      (WidgetTester tester) async {
    const viewportWidth = 360.0;
    const markerKey = Key('stretch-marker');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: viewportWidth,
            height: 600,
            child: CenteredScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    key: markerKey,
                    height: 24,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final markerBox = tester.getRect(find.byKey(markerKey));
    expect(markerBox.width, viewportWidth);
  });

  testWidgets('center alignment vertically positions sparse content',
      (WidgetTester tester) async {
    const viewportHeight = 600.0;
    const markerKey = Key('centered-marker');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: viewportHeight,
            child: CenteredScrollView(
              padding: EdgeInsets.zero,
              child: Container(
                key: markerKey,
                height: 40,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );

    final markerBox = tester.getRect(find.byKey(markerKey));
    expect(markerBox.center.dy, closeTo(viewportHeight / 2, 1));
  });

  testWidgets('non-scrollable mode gives Expanded children bounded height',
      (WidgetTester tester) async {
    const expandedKey = Key('expanded-child');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CenteredScrollView(
            scrollable: false,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Expanded(
                  child: SizedBox(
                    key: expandedKey,
                    width: double.infinity,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(expandedKey)).height, greaterThan(0));
  });
}