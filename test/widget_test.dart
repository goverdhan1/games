import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/hub/game_catalog.dart';

void main() {
  test('catalog includes all three waves', () {
    expect(kGameCatalog.where((g) => g.wave == GameWave.wave1).length, greaterThanOrEqualTo(7));
    expect(kGameCatalog.where((g) => g.wave == GameWave.wave2).length, greaterThanOrEqualTo(7));
    expect(kGameCatalog.where((g) => g.wave == GameWave.wave3).length, greaterThanOrEqualTo(6));
  });
}
