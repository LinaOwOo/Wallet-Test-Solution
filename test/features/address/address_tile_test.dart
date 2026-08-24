import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wallet_test/core/dev_stubs/in_memory_address_repository.dart';
import 'package:wallet_test/features/address/address_repository.dart';
import 'package:wallet_test/features/address/address_tile.dart';
import 'package:wallet_test/features/address/address_tile_bloc.dart';
import '../../helpers/test_get_it.dart';

void main() {
  Future<void> pumpTile(
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AddressTile(
          address: '0x1234567890abcdef1234567890abcdef12345678',
          network: 'Ethereum',
        ),
      ),
    );
  }

  testWidgets('renders the widget', (tester) async {
    await testWithGetIt(() async {
      await pumpTile(tester);
      expect(find.text('Ethereum'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });
  });

  testWidgets('has no overflow at text scale 2.0', (tester) async {
    await testWithGetIt(() async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(textScaleFactor: 2.0),
          child: MaterialApp(
            home: AddressTile(
              address: '0x1234567890abcdef1234567890abcdef12345678',
              network: 'Ethereum',
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('copy button calls repository and shows copied state', (tester) async {
    await testWithGetIt(() async {
      final repository =
          GetIt.instance<IAddressRepository>() as InMemoryAddressRepository;

      await pumpTile(tester);
      await tester.tap(find.byIcon(Icons.copy));
      await tester.pump(const Duration(milliseconds: 50));

      expect(repository.copyCalls, 1);
      expect(repository.lastAddress, startsWith('0x'));
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  testWidgets('copy failure shows error state', (tester) async {
    await testWithGetIt(() async {
      final repository =
          GetIt.instance<IAddressRepository>() as InMemoryAddressRepository;
      repository.shouldFail = true;

      await pumpTile(tester);
      await tester.tap(find.byIcon(Icons.copy));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  testWidgets('copied state resets after 1500ms', (tester) async {
    await testWithGetIt(() async {
      await pumpTile(tester);
      await tester.tap(find.byIcon(Icons.copy));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });
  });

  testWidgets('bloc is closed when widget is disposed', (tester) async {
    await testWithGetIt(() async {
      final repository =
          GetIt.instance<IAddressRepository>() as InMemoryAddressRepository;
      final bloc = AddressTileBloc(repository: repository);

      GetIt.instance.unregister<AddressTileBloc>();
      GetIt.instance.registerSingleton<AddressTileBloc>(bloc);

      await pumpTile(tester);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(bloc.isClosed, isTrue);
    });
  });
}
