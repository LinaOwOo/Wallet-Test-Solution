import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:wallet_test/core/dev_stubs/dev_card_issuer.dart';
import 'package:wallet_test/features/cards/card_issue_bloc.dart';
import 'package:wallet_test/features/cards/card_issue_page.dart';
import 'package:wallet_test/features/cards/card_issuer.dart';
import '../../helpers/test_get_it.dart';

void main() {
  testWidgets('page renders', (tester) async {
    await testWithGetIt(() async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CardIssuePage(cardId: 'card_1'),
        ),
      );

      expect(find.text('Issue card'), findsOneWidget);
    });
  });

  testWidgets('gets issuer and bloc from GetIt and closes bloc on dispose', (tester) async {
    await testWithGetIt(() async {
      final issuer = GetIt.instance<ICardIssuer>() as DevCardIssuer;
      final bloc = GetIt.instance<CardIssueBloc>();

      GetIt.instance.unregister<CardIssueBloc>();
      GetIt.instance.registerSingleton<CardIssueBloc>(bloc);

      await tester.pumpWidget(
        const MaterialApp(
          home: CardIssuePage(cardId: 'card_1'),
        ),
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(issuer, isA<DevCardIssuer>());
      expect(bloc.isClosed, isTrue);
      expect(issuer.cancelCalls, 1);
    });
  });

  testWidgets('cancelPending is called once on dispose', (tester) async {
    await testWithGetIt(() async {
      final issuer = GetIt.instance<ICardIssuer>() as DevCardIssuer;

      await tester.pumpWidget(
        const MaterialApp(
          home: CardIssuePage(cardId: 'card_1'),
        ),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await Future<void>.delayed(Duration.zero);

      expect(issuer.cancelCalls, 1);
    });
  });
}
