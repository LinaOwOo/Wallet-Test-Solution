import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wallet_test/features/cards/card_issuer.dart';

abstract class CardIssueEvent {
  const CardIssueEvent();
}

class IssueTapped extends CardIssueEvent {
  const IssueTapped(this.request);

  final CardIssueRequest request;
}

class CardIssueState {
  const CardIssueState({
    this.issuing = false,
    this.error,
  });

  final bool issuing;
  final String? error;
}

class CardIssueBloc extends Bloc<CardIssueEvent, CardIssueState> {
  CardIssueBloc({
    required ICardIssuer issuer,
  })  : _issuer = issuer,
        super(const CardIssueState()) {
    on<IssueTapped>(_onIssueTapped);
  }

  final ICardIssuer _issuer;

  Future<void> _onIssueTapped(
    IssueTapped event,
    Emitter<CardIssueState> emit,
  ) async {
    emit(const CardIssueState(issuing: true));

    try {
      await _issuer.issue(event.request);
      if (!isClosed) {
        emit(const CardIssueState());
      }
    } catch (_) {
      if (!isClosed) {
        emit(const CardIssueState(error: 'issue_failed'));
      }
    }
  }
}
