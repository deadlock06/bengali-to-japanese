import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensei_app/presentation/book_screen_v4.dart';
import 'package:sensei_app/app/providers.dart';
import 'package:sensei_app/data/book_repository.dart';

void main() {
  testWidgets('BookScreenV4 shows a loading spinner while the book loads',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Never-completing future → the screen stays in its loading state.
          bookProvider.overrideWith((ref) => Completer<BookRepository>().future),
        ],
        child: const MaterialApp(home: BookScreenV4()),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
