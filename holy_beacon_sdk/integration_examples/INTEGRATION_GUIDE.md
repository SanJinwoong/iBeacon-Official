# Holy Beacon SDK - Guía de Integración

Esta guía muestra cómo integrar el Holy Beacon SDK en diferentes tipos de aplicaciones.

## 📱 Integración en Flutter

### 1. Instalación

```yaml
dependencies:
  holy_beacon_sdk: ^1.0.0
```

### 2. Ejemplo Básico

```dart
import 'package:flutter/material.dart';
import 'package:holy_beacon_sdk/holy_beacon_sdk.dart';

class BeaconPage extends StatefulWidget {
  @override
  _BeaconPageState createState() => _BeaconPageState();
}

class _BeaconPageState extends State<BeaconPage> {
  final HolyBeaconScanner scanner = HolyBeaconScanner();
  List<BeaconDevice> devices = [];
  String status = '';

  @override
  void initState() {
    super.initState();
    _setupScanner();
  }

  Future<void> _setupScanner() async {
    // Configuración optimizada para Holy devices
    await scanner.initialize(
      config: BeaconScanConfig(
        scanDuration: Duration(seconds: 30),
        prioritizeHolyDevices: true,
        enableDebugLogs: true,
      ),
      whitelist: BeaconWhitelist.allowAll(),
    );

    // Escuchar dispositivos
    scanner.devices.listen((deviceList) {
      setState(() => devices = deviceList);
    });

    // Escuchar estado
    scanner.status.listen((msg) {
      setState(() => status = msg);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Holy Beacon Scanner')),
      body: Column(
        children: [
          // Control de escaneo
          ElevatedButton(
            onPressed: scanner.isScanning 
              ? () => scanner.stopScanning()
              : () => scanner.startScanning(),
            child: Text(scanner.isScanning ? 'Stop' : 'Start'),
          ),
          
          // Estado
          Text(status),
          
          // Lista de dispositivos
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  title: Text(device.name),
                  subtitle: Text('${device.rssi} dBm - ${device.estimatedDistance}'),
                  leading: Icon(
                    device.isHolyDevice ? Icons.verified : Icons.bluetooth,
                    color: device.isHolyDevice ? Colors.blue : Colors.grey,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    scanner.dispose();
    super.dispose();
  }
}
```

## 🤖 Integración Android Nativo

### 1. Dependencia Gradle

```gradle
// app/build.gradle
dependencies {
    implementation 'com.holybeacon:sdk:1.0.0'
}
```

### 2. Ejemplo Kotlin

```kotlin
import com.holybeacon.sdk.HolyBeaconScanner
import com.holybeacon.sdk.BeaconDevice
import com.holybeacon.sdk.BeaconScanConfig

class MainActivity : AppCompatActivity() {
    private lateinit var scanner: HolyBeaconScanner
    private val deviceAdapter = DeviceAdapter()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        setupScanner()
        setupUI()
    }

    private fun setupScanner() {
        scanner = HolyBeaconScanner(this).apply {
            // Configurar callback de dispositivos
            setDeviceCallback { devices ->
                runOnUiThread {
                    deviceAdapter.updateDevices(devices)
                }
            }
            
            // Configurar callback de estado
            setStatusCallback { status ->
                runOnUiThread {
                    statusText.text = status
                }
            }
        }
    }

    private fun setupUI() {
        val recyclerView = findViewById<RecyclerView>(R.id.recyclerView)
        recyclerView.adapter = deviceAdapter
        
        val startButton = findViewById<Button>(R.id.startButton)
        startButton.setOnClickListener {
            if (scanner.isScanning) {
                scanner.stopScanning()
                startButton.text = "Start Scanning"
            } else {
                val config = BeaconScanConfig.Builder()
                    .setHolyOptimized(true)
                    .setScanDuration(30000) // 30 segundos
                    .setMinRssi(-90)
                    .build()
                
                scanner.startScanning(config)
                startButton.text = "Stop Scanning"
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        scanner.dispose()
    }
}

// Adapter para RecyclerView
class DeviceAdapter : RecyclerView.Adapter<DeviceViewHolder>() {
    private var devices = listOf<BeaconDevice>()

    fun updateDevices(newDevices: List<BeaconDevice>) {
        devices = newDevices
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): DeviceViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_device, parent, false)
        return DeviceViewHolder(view)
    }

    override fun onBindViewHolder(holder: DeviceViewHolder, position: Int) {
        holder.bind(devices[position])
    }

    override fun getItemCount() = devices.size
}

class DeviceViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
    private val nameText = itemView.findViewById<TextView>(R.id.deviceName)
    private val rssiText = itemView.findViewById<TextView>(R.id.rssi)
    private val holyIcon = itemView.findViewById<ImageView>(R.id.holyIcon)

    fun bind(device: BeaconDevice) {
        nameText.text = device.name.ifEmpty { "Unknown Device" }
        rssiText.text = "${device.rssi} dBm - ${device.estimatedDistance}"
        holyIcon.visibility = if (device.isHolyDevice) View.VISIBLE else View.GONE
    }
}
```

### 3. Permisos Android

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
```

## 🍎 Integración iOS Swift

### 1. Swift Package Manager

Agrega al `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/SanJinwoong/holy-beacon-sdk-ios", from: "1.0.0")
]
```

### 2. Ejemplo Swift

```swift
import UIKit
import HolyBeaconSDK

class BeaconViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var scanButton: UIButton!
    
    private let scanner = HolyBeaconScanner()
    private var devices: [BeaconDevice] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScanner()
        setupUI()
    }
    
    private func setupScanner() {
        // Configurar callbacks
        scanner.deviceCallback = { [weak self] devices in
            DispatchQueue.main.async {
                self?.devices = devices
                self?.tableView.reloadData()
            }
        }
        
        scanner.statusCallback = { [weak self] status in
            DispatchQueue.main.async {
                self?.statusLabel.text = status
            }
        }
        
        scanner.errorCallback = { [weak self] error in
            DispatchQueue.main.async {
                self?.showAlert(message: error.localizedDescription)
            }
        }
    }
    
    private func setupUI() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DeviceCell")
    }
    
    @IBAction func scanButtonTapped(_ sender: UIButton) {
        if scanner.isScanning {
            scanner.stopScanning()
            scanButton.setTitle("Start Scanning", for: .normal)
        } else {
            let config = BeaconScanConfig(
                scanDuration: 30, // segundos
                holyOptimized: true,
                minRssi: -90
            )
            
            scanner.startScanning(with: config)
            scanButton.setTitle("Stop Scanning", for: .normal)
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    deinit {
        scanner.dispose()
    }
}

// MARK: - TableView DataSource & Delegate
extension BeaconViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)
        let device = devices[indexPath.row]
        
        cell.textLabel?.text = device.name.isEmpty ? "Unknown Device" : device.name
        cell.detailTextLabel?.text = "\(device.rssi) dBm - \(device.estimatedDistance)"
        
        // Icono para dispositivos Holy
        if device.isHolyDevice {
            cell.imageView?.image = UIImage(systemName: "checkmark.seal.fill")
            cell.imageView?.tintColor = .systemBlue
        } else {
            cell.imageView?.image = UIImage(systemName: "dot.radiowaves.left.and.right")
            cell.imageView?.tintColor = .systemGray
        }
        
        return cell
    }
}
```

### 3. Permisos iOS

```xml
<!-- Info.plist -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Esta aplicación usa Bluetooth para detectar dispositivos beacon cercanos.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Esta aplicación usa Bluetooth para detectar dispositivos beacon cercanos.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Esta aplicación necesita acceso a la ubicación para detectar beacons BLE.</string>
```

## 🔧 Configuraciones Avanzadas

### Whitelist Personalizada

```dart
// Flutter
final customWhitelist = BeaconWhitelist(
  allowedUuids: {
    'FDA50693-A4E2-4FB1-AFCF-C6EB07647825', // Holy-Shun
    'E2C56DB5-DFFB-48D2-B060-D0F5A7100000', // Holy-Jin
  },
  allowedNames: {'Holy', 'Kronos', 'MyDevice'},
  allowUnknown: false,
);

scanner.setWhitelist(customWhitelist);
```

```kotlin
// Android
val whitelist = BeaconWhitelist.Builder()
    .addAllowedUuid("FDA50693-A4E2-4FB1-AFCF-C6EB07647825")
    .addAllowedName("Holy")
    .setAllowUnknown(false)
    .build()

scanner.setWhitelist(whitelist)
```

```swift
// iOS
let whitelist = BeaconWhitelist(
    allowedUuids: ["FDA50693-A4E2-4FB1-AFCF-C6EB07647825"],
    allowedNames: ["Holy", "Kronos"],
    allowUnknown: false
)

scanner.setWhitelist(whitelist)
```

### Configuración de Escaneo Personalizada

```dart
// Flutter - Configuración para diferentes escenarios
final config = BeaconScanConfig(
  scanDuration: Duration(minutes: 5),
  minRssi: -75, // Solo dispositivos cercanos
  prioritizeHolyDevices: true,
  enableDebugLogs: false,
);
```

### Manejo de Errores

```dart
// Flutter
scanner.errors.listen((error) {
  switch (error.type) {
    case HolyBeaconErrorType.permissions:
      _requestPermissions();
      break;
    case HolyBeaconErrorType.bluetooth:
      _showBluetoothDialog();
      break;
    case HolyBeaconErrorType.scanning:
      _handleScanError(error.message);
      break;
  }
});
```

## 🧪 Testing

### Test Unitarios Flutter

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_beacon_sdk/holy_beacon_sdk.dart';

void main() {
  group('HolyBeaconScanner Tests', () {
    late HolyBeaconScanner scanner;

    setUp(() {
      scanner = HolyBeaconScanner();
    });

    tearDown(() {
      scanner.dispose();
    });

    test('should initialize correctly', () async {
      await scanner.initialize();
      expect(scanner.isScanning, false);
    });

    test('should detect Holy devices correctly', () {
      final holyDevice = BeaconDevice(
        deviceId: 'test-id',
        name: 'Holy-IOT Jin',
        rssi: -50,
        uuid: 'E2C56DB5-DFFB-48D2-B060-D0F5A7100000',
        major: 1,
        minor: 2,
        protocol: BeaconProtocol.ibeacon,
        lastSeen: DateTime.now(),
      );

      expect(holyDevice.isHolyDevice, true);
    });
  });
}
```

## 📱 Aplicaciones de Ejemplo Completas

### Flutter E-commerce con Proximity

```dart
class StoreBeaconService {
  final HolyBeaconScanner scanner = HolyBeaconScanner();
  final StreamController<List<StoreOffer>> _offersController = 
      StreamController<List<StoreOffer>>.broadcast();
  
  Stream<List<StoreOffer>> get nearbyOffers => _offersController.stream;

  Future<void> startProximityOffers() async {
    await scanner.initialize(
      config: BeaconScanConfig(
        scanDuration: Duration(hours: 1),
        minRssi: -70, // Solo ofertas cercanas
        prioritizeHolyDevices: false,
      ),
      whitelist: BeaconWhitelist.allowAll(),
    );

    scanner.devices.listen((devices) {
      final offers = devices
          .where((device) => device.rssi > -60) // Muy cercano
          .map((device) => _getOfferForBeacon(device))
          .where((offer) => offer != null)
          .cast<StoreOffer>()
          .toList();
      
      _offersController.add(offers);
    });

    await scanner.startScanning();
  }

  StoreOffer? _getOfferForBeacon(BeaconDevice beacon) {
    // Mapear beacons específicos a ofertas
    switch (beacon.uuid) {
      case 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825':
        return StoreOffer(
          title: '20% descuento en electrónicos',
          description: 'Cerca de la sección de electrónicos',
          beacon: beacon,
        );
      default:
        return null;
    }
  }
}

class StoreOffer {
  final String title;
  final String description;
  final BeaconDevice beacon;

  StoreOffer({
    required this.title,
    required this.description,
    required this.beacon,
  });
}
```

### Android Asset Tracking

```kotlin
class AssetTracker(private val context: Context) {
    private val scanner = HolyBeaconScanner(context)
    private val trackedAssets = mutableMapOf<String, Asset>()
    private var trackingCallback: ((List<Asset>) -> Unit)? = null

    fun startTracking(assets: List<Asset>, callback: (List<Asset>) -> Unit) {
        this.trackingCallback = callback
        
        // Configurar whitelist solo para assets específicos
        val whitelist = BeaconWhitelist.Builder()
            .apply {
                assets.forEach { asset ->
                    addAllowedUuid(asset.beaconUuid)
                }
            }
            .setAllowUnknown(false)
            .build()

        scanner.setWhitelist(whitelist)
        
        scanner.setDeviceCallback { devices ->
            val updatedAssets = devices.mapNotNull { device ->
                trackedAssets.values.find { it.beaconUuid == device.uuid }?.copy(
                    lastSeen = device.lastSeen,
                    rssi = device.rssi,
                    isNear = device.rssi > -60
                )
            }
            
            callback(updatedAssets)
        }

        val config = BeaconScanConfig.Builder()
            .setScanMode(ScanMode.BALANCED)
            .setReportDelay(1000) // Reportar cada segundo
            .build()

        scanner.startScanning(config)
    }

    fun stopTracking() {
        scanner.stopScanning()
        trackingCallback = null
    }
}

data class Asset(
    val id: String,
    val name: String,
    val beaconUuid: String,
    val lastSeen: Date? = null,
    val rssi: Int? = null,
    val isNear: Boolean = false
)
```

## 🚀 Despliegue en Producción

### Optimizaciones de Rendimiento

```dart
// Configuración optimizada para producción
final productionConfig = BeaconScanConfig(
  scanDuration: Duration(minutes: 2), // Ciclos cortos
  minRssi: -80, // Filtrar dispositivos lejanos
  prioritizeHolyDevices: true,
  enableDebugLogs: false, // Desactivar en producción
);

// Gestión de memoria
Timer.periodic(Duration(minutes: 5), (timer) {
  scanner.clearDevices();
});

// Pausa automática en background
class AppLifecycleManager extends WidgetsBindingObserver {
  final HolyBeaconScanner scanner;
  
  AppLifecycleManager(this.scanner);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        scanner.stopScanning();
        break;
      case AppLifecycleState.resumed:
        scanner.startScanning();
        break;
      default:
        break;
    }
  }
}
```

### Monitoreo y Analytics

```dart
class BeaconAnalytics {
  static void trackScanSession(BeaconScanStats stats) {
    // Enviar métricas a analytics
    analytics.track('beacon_scan_completed', {
      'total_devices': stats.totalDevices,
      'holy_devices': stats.holyDevices,
      'scan_duration': stats.scanDuration.inSeconds,
      'average_rssi': stats.averageRssi,
    });
  }

  static void trackHolyDeviceDetected(BeaconDevice device) {
    analytics.track('holy_device_detected', {
      'device_name': device.name,
      'uuid': device.uuid,
      'rssi': device.rssi,
      'distance': device.estimatedDistance,
    });
  }
}

// Uso en la aplicación
scanner.devices.listen((devices) {
  final holyDevices = devices.where((d) => d.isHolyDevice);
  for (final device in holyDevices) {
    BeaconAnalytics.trackHolyDeviceDetected(device);
  }
});
```

## 📞 Soporte y Recursos

- **Documentación**: [docs.holybeacon.com](https://docs.holybeacon.com)
- **GitHub**: [github.com/SanJinwoong/holy-beacon-sdk](https://github.com/SanJinwoong/holy-beacon-sdk)
- **Issues**: Para reportar bugs o solicitar features
- **Discussions**: Para preguntas de la comunidad
- **Email**: soporte@holybeacon.com