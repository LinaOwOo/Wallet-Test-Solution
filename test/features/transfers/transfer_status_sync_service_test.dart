import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wallet_test/core/dev_stubs/in_memory_transfer_repository.dart';
import 'package:wallet_test/core/errors/app_exception.dart';
import 'package:wallet_test/core/network/api_client.dart';
import 'package:wallet_test/features/transfers/transfer.dart';
import 'package:wallet_test/features/transfers/transfer_status_sync_service.dart';
import '../../fakes/fake_http_client_adapter.dart';

Transfer makeTransfer({String network = 'Ethereum'}) {
  return Transfer(
    id: '1',
    network: network,
    txHash: '0x1234abcd',
  );
}

TransferStatusSyncService makeService(
  InMemoryTransferRepository repository,
  FakeHttpClientAdapter adapter,
) {
  final dio = Dio();
  dio.httpClientAdapter = adapter;
  return TransferStatusSyncService(
    api: ApiClient(dio: dio),
    repository: repository,
  );
}

void main() {
  test('429 then 200 retries once, persists once, and returns confirmed', () async {
    final adapter = FakeHttpClientAdapter([
      HttpOutcome(429),
      HttpOutcome(200, body: {'status': 'confirmed'}),
    ]);
    final repository = InMemoryTransferRepository();
    final service = makeService(repository, adapter);

    final result = await service.sync(makeTransfer());

    expect(result, TransferStatus.confirmed);
    expect(adapter.calls, hasLength(2));
    expect(repository.applyCalls, 1);
  });

  test('401 is not retried and maps to unauthorized', () async {
    final adapter = FakeHttpClientAdapter([HttpOutcome(401)]);
    final repository = InMemoryTransferRepository();
    final service = makeService(repository, adapter);

    await expectLater(
      service.sync(makeTransfer()),
      throwsA(
        isA<TransferSyncException>().having(
          (e) => e.code,
          'code',
          'unauthorized',
        ),
      ),
    );
    expect(adapter.calls, hasLength(1));
    expect(repository.applyCalls, 0);
  });

  test('500 is not retried and maps to internal', () async {
    final adapter = FakeHttpClientAdapter([HttpOutcome(500)]);
    final repository = InMemoryTransferRepository();
    final service = makeService(repository, adapter);

    await expectLater(
      service.sync(makeTransfer()),
      throwsA(
        isA<TransferSyncException>().having(
          (e) => e.code,
          'code',
          'internal',
        ),
      ),
    );
    expect(adapter.calls, hasLength(1));
  });

  test('three 429 responses make exactly three calls', () async {
    final adapter = FakeHttpClientAdapter([
      HttpOutcome(429),
      HttpOutcome(429),
      HttpOutcome(429),
    ]);
    final repository = InMemoryTransferRepository();
    final service = makeService(repository, adapter);

    await expectLater(
      service.sync(makeTransfer()),
      throwsA(
        isA<TransferSyncException>().having(
          (e) => e.code,
          'code',
          'rateLimited',
        ),
      ),
    );
    expect(adapter.calls, hasLength(3));
    expect(repository.applyCalls, 0);
  });

  test('successful HTTP with DB failure maps to localPersistenceFailed', () async {
    final adapter = FakeHttpClientAdapter([
      HttpOutcome(200, body: {'status': 'confirmed'}),
    ]);
    final repository = InMemoryTransferRepository()..shouldFail = true;
    final service = makeService(repository, adapter);

    await expectLater(
      service.sync(makeTransfer()),
      throwsA(
        isA<TransferSyncException>().having(
          (e) => e.code,
          'code',
          'localPersistenceFailed',
        ),
      ),
    );
  });


  test('cancelled request does not retry or persist', () async {
    final adapter = FakeHttpClientAdapter([
      HttpOutcome(200, body: {'status': 'confirmed'}),
    ]);
    final repository = InMemoryTransferRepository();
    final service = makeService(repository, adapter);
    final cancelToken = CancelToken()..cancel();

    await expectLater(
      service.sync(
        makeTransfer(),
        cancelToken: cancelToken,
      ),
      throwsA(isA<CancelException>()),
    );
    expect(adapter.calls, isEmpty);
    expect(repository.applyCalls, 0);
  });

  test('sets stable lower-case idempotency key', () async {
    final adapter = FakeHttpClientAdapter([
      HttpOutcome(200, body: {'status': 'confirmed'}),
    ]);
    final repository = InMemoryTransferRepository();
    final service = makeService(repository, adapter);

    await service.sync(makeTransfer(network: 'Ethereum'));

    expect(
      adapter.calls.single.headers['Idempotency-Key'],
      'ethereum:0x1234abcd',
    );
    expect(adapter.calls.single.method, 'GET');
    expect(adapter.calls.single.path, '/v1/transfers/0x1234abcd/status');
  });
}
