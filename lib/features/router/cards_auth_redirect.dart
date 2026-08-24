String? cardsAuthRedirect(Uri uri, bool isAuthed) {
  final path = uri.path;
  final isCardsPath = path == '/cards' || path.startsWith('/cards/');

  if (!isAuthed && isCardsPath) {
    final next = Uri.encodeComponent(uri.toString());
    return '/onboarding?next=$next';
  }

  if (isAuthed && path == '/onboarding') {
    final next = uri.queryParameters['next'];
    if (next != null && _isSafeCardsPath(next)) {
      return next;
    }
    return '/cards';
  }

  if (!isAuthed && path == '/onboarding') {
    return null;
  }

  return null;
}

bool _isSafeCardsPath(String value) {
  final parsed = Uri.tryParse(value);
  if (parsed == null || parsed.hasScheme || parsed.hasAuthority) {
    return false;
  }

  final path = parsed.path;
  return path == '/cards' || path.startsWith('/cards/');
}
