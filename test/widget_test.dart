import 'package:flutter_test/flutter_test.dart';
import 'package:ibeacon/services/ble_scanner.dart';
import 'package:ibeacon/models/beacon_models.dart';
import 'package:ibeacon/main.dart';

class FakeScanner implements IBeaconScanner {
  @override
  Stream<List<BeaconDevice>> get devicesStream => const Stream.empty();

  @override
  Stream<String> get statusStream => const Stream.empty();

  @override
  bool get isScanning => false;

  @override
  void dispose() {}

  @override
  void setWhitelist(BeaconWhitelist wl) {}

  @override
  void start({String? filterUuid}) {}

  @override
  void stop() {}
}

// Test básico validando la aplicación principal
void main() {
  testWidgets('Muestra la aplicación principal', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that our app loads without errors
    expect(find.text('iBeacon Scanner'), findsOneWidget);
  });

  testWidgets('El botón de escaneo existe', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    // Verificar que el botón de escaneo existe
    expect(find.textContaining('Iniciar Escaneo'), findsOneWidget);
  });
}
