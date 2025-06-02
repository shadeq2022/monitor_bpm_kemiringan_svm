import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'ble_service.dart';
import 'Page/login_page.dart';
import 'Page/register_page.dart';
import 'Page/monitoring_page.dart';
import 'Page/history_page.dart' as history_page;
import 'Page/warning_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RAA Tugas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/history': (context) => const history_page.HistoryPage(),
        '/warning': (context) =>  WarningPage(),
        // Jangan daftarkan MonitoringPage di routes karena butuh parameter / cara khusus untuk push
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? _user;
  bool _checkingAuth = true;
  bool _loggedInOnce = false;

  Future<void> requestBluetoothPermission() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  @override
  void initState() {
    super.initState();
    requestBluetoothPermission();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        _user = user;
        _checkingAuth = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null || !_loggedInOnce) {
      return LoginPage(
        onLoginSuccess: (user) {
          setState(() {
            _user = user;
            _loggedInOnce = true;
          });
        },
      );
    } else {
      return const MyHomePage();
    }
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final BLEService bleService = BLEService();

  String bpm = "0";
  String kemiringan = "0";

  @override
  void initState() {
    super.initState();
    requestPermissions();

    // Listen perubahan data dari BLEService singleton
    bleService.bpm.addListener(() {
      setState(() {
        bpm = bleService.bpm.value;
      });
    });
    bleService.kemiringan.addListener(() {
      setState(() {
        kemiringan = bleService.kemiringan.value;
      });
    });
  }

  Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      print("Izin Bluetooth dan lokasi tidak lengkap!");
    } else {
      print("Izin lengkap, siap scan BLE.");
    }
  }

  void _connect() {
    bleService.connectToDevice();
  }

  void _openMonitoringPage() {
    // Tidak perlu passing parameter, MonitoringPage ambil data sendiri dari BLE
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MonitoringPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BLE Demo")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('BPM: $bpm'),
            Text('Kemiringan: $kemiringan°'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _connect,
              child: const Text('Connect'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: (bpm != "0" && kemiringan != "0") ? _openMonitoringPage : null,
              child: const Text('Lihat Monitoring & Prediksi'),
            ),
          ],
        ),
      ),
    );
  }
}
