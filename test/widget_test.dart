import 'package:flutter_test/flutter_test.dart';
import 'package:ibeacon/services/ble_scanner.dart';
import 'package:ibeacon/models/beacon_models.dart';
import 'package:ibeacon/main.dart';

class FakeScanner implements IBeaconScanner {
  @override
  Stream<List<BeaconDevice>> get devicesStream => const Stream.empty();
  @override
  void dispose() {}
  @override
  void setWhitelist(BeaconWhitelist wl) {}
  @override
  void start({String? filterUuid}) {}
  @override
  void stop() {}
}
// Test básico validando pantalla inicial de permisos.

void main() {
  testWidgets('Muestra pantalla de permisos inicial', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(BeaconApp(scanner: FakeScanner()));
    expect(find.textContaining('Permisos'), findsOneWidget);
  }, skip: true); // Saltado en CI porque no mockeamos platform channels aún.
}
