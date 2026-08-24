import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:wallet_test/features/auth/auth_repository.dart';

class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier({
    required IAuthRepository auth,
    required GoRouter router,
  }) : _subscription = auth.onAuthChanged.listen((_) {
          router.refresh();
        });

  final StreamSubscription<bool> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
