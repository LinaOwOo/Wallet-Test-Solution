import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:wallet_test/features/cards/card_issue_bloc.dart';
import 'package:wallet_test/features/cards/card_issuer.dart';

class CardIssuePage extends StatefulWidget {
  const CardIssuePage({
    super.key,
    required this.cardId,
  });

  final String cardId;

  @override
  State<CardIssuePage> createState() => _CardIssuePageState();
}

class _CardIssuePageState extends State<CardIssuePage> {
  late final ICardIssuer _issuer;
  late final CardIssueBloc _bloc;
  bool _cancelRequested = false;

  @override
  void initState() {
    super.initState();
    _issuer = GetIt.instance<ICardIssuer>();
    _bloc = GetIt.instance<CardIssueBloc>();
  }

  void _cancelOnce() {
    if (_cancelRequested) {
      return;
    }

    _cancelRequested = true;
    _issuer.cancelPending();
  }

  @override
  void dispose() {
    _cancelOnce();
    _bloc.close();
    super.dispose();
  }

  void _issue() {
    _bloc.add(
      IssueTapped(
        CardIssueRequest(cardId: widget.cardId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: BlocBuilder<CardIssueBloc, CardIssueState>(
          bloc: _bloc,
          builder: (context, state) {
            return ElevatedButton(
              onPressed: state.issuing ? null : _issue,
              child: Text(state.error == null ? 'Issue card' : 'Try again'),
            );
          },
        ),
      ),
    );
  }
}
