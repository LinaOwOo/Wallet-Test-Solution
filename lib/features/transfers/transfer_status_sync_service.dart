import 'dart:async';

import 'package:dio/dio.dart';

import 'package:wallet_test/core/errors/app_exception.dart';
import 'package:wallet_test/core/network/api_client.dart';
import 'package:wallet_test/features/transfers/transfer.dart';
import 'package:wallet_test/features/transfers/transfer_repository.dart';

class TransferStatusSyncService {
  TransferStatusSyncService({
    required ApiClient api,
    required ITransferRepository repository,
  })  : _api = api,
        _repository = repository;

  final ApiClient _api;
  final ITransferRepository _repository;

  Future<TransferStatus> sync(
    Transfer transfer, {
    CancelToken? cancelToken,
  }) async {
    final idempotencyKey = '${transfer.network.toLowerCase()}:${transfer.txHash}';

    Response<dynamic> response;
    var attempt = 0;

    while (true) {
      attempt++;
      try {
        response = await _api.dio.get<dynamic>(
          '/v1/transfers/${transfer.txHash}/status',
          cancelToken: cancelToken,
          options: Options(
            headers: <String, String>{
              'Idempotency-Key': idempotencyKey,
            },
          ),
        );
        break;
      } on DioException catch (error) {
        if (error.type == DioExceptionType.cancel) {
          throw const CancelException();
        }

        final statusCode = error.response?.statusCode;
        final retryableStatus = statusCode == 408 ||
            statusCode == 429 ||
            statusCode == 503;
        final retryableType = {
          DioExceptionType.connectionTimeout,
          DioExceptionType.connectionError,
          DioExceptionType.receiveTimeout,
          DioExceptionType.sendTimeout,
        }.contains(error.type);

        if (attempt >= 3 || (!retryableStatus && !retryableType)) {
          throw _mapDioException(error);
        }

        if (cancelToken?.isCancelled == true) {
          throw const CancelException();
        }

        await Future<void>.delayed(
          Duration(milliseconds: attempt == 1 ? 200 : 500),
        );

        if (cancelToken?.isCancelled == true) {
          throw const CancelException();
        }
      }
    }

    final data = response.data;
    final rawStatus = data is Map<String, dynamic>
        ? data['status']
        : null;
    final status = TransferStatus.fromName(
      rawStatus is String ? rawStatus : 'unknown',
    );

    try {
      await _repository.applyStatus(
        transfer,
        status,
        DateTime.now(),
      );
    } catch (error) {
      throw TransferSyncException(
        code: 'localPersistenceFailed',
        message: error.toString(),
      );
    }

    return status;
  }

  TransferSyncException _mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;

    switch (statusCode) {
      case 401:
        return const TransferSyncException(code: 'unauthorized');
      case 404:
        return const TransferSyncException(code: 'notFound');
      case 409:
        return const TransferSyncException(code: 'conflict');
      case 408:
      case 429:
        return const TransferSyncException(code: 'rateLimited');
      case 503:
        return const TransferSyncException(code: 'serverUnavailable');
      case 500:
        return const TransferSyncException(code: 'internal');
    }

    return TransferSyncException(
      code: 'network',
      message: error.message,
    );
  }
}
