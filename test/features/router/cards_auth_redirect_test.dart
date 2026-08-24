import 'package:flutter_test/flutter_test.dart';

import 'package:wallet_test/features/router/cards_auth_redirect.dart';

void main() {
  test('redirects unauthenticated cards deep link to onboarding', () {
    expect(
      cardsAuthRedirect(
        Uri.parse('/cards/card_1/issue?step=2'),
        false,
      ),
      '/onboarding?next=%2Fcards%2Fcard_1%2Fissue%3Fstep%3D2',
    );
  });

  test('restores safe cards deep link after auth', () {
    expect(
      cardsAuthRedirect(
        Uri.parse(
          '/onboarding?next=%2Fcards%2Fcard_1%2Fissue%3Fstep%3D2',
        ),
        true,
      ),
      '/cards/card_1/issue?step=2',
    );
  });

  test('rejects external next value', () {
    expect(
      cardsAuthRedirect(
        Uri.parse('/onboarding?next=https%3A%2F%2Fevil.com'),
        true,
      ),
      '/cards',
    );
  });

  test('does not redirect unauthenticated onboarding', () {
    expect(cardsAuthRedirect(Uri.parse('/onboarding'), false), isNull);
  });

  test('does not redirect authenticated cards page', () {
    expect(cardsAuthRedirect(Uri.parse('/cards'), true), isNull);
  });
}
