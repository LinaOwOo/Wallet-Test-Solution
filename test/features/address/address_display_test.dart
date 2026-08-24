import 'package:flutter_test/flutter_test.dart';

import 'package:wallet_test/features/address/address_display.dart';

void main() {
  const address = '0x1234567890abcdef1234567890abcdef12345678';

  test('short address stays unchanged', () {
    expect(formatAddressForCell('0x1234', 2.0), '0x1234');
  });

  test('long 0x address uses 6 + 4 at normal scale', () {
    expect(formatAddressForCell(address, 1.0), '0x123456…5678');
  });

  test('large text scale uses 4 + 4', () {
    expect(formatAddressForCell(address, 2.0), '0x1234…5678');
  });

  test('address without 0x is shortened', () {
    expect(
      formatAddressForCell(
        '1234567890abcdef1234567890abcdef12345678',
        1.0,
      ),
      '123456…5678',
    );
  });

  test('0x prefix is preserved', () {
    expect(
      formatAddressForCell(address, 1.0).startsWith('0x'),
      isTrue,
    );
  });
}
