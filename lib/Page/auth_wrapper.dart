import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:raa_tugas/Page/login_page.dart';
import 'package:raa_tugas/Page/monitoring_page.dart'; // Tanpa alias karena tidak perlu

import 'package:permission_handler/permission_handler.dart';

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
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
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
      return const MonitoringPage(); // Tidak butuh parameter lagi
    }
  }
}
