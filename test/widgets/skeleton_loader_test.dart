import 'package:amsv2/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SkeletonListView can be embedded in a scrollable column',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SingleChildScrollView(
          child: Column(
            children: [
              SkeletonListView(itemCount: 1),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SkeletonListItem), findsOneWidget);
  });
}
