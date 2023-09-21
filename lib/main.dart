import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'component/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SplashApp());
}

class SplashApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jewellers.Live',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = true;
  String? url = kReleaseMode
      ? "https://admin.jewellers.live/"
      : "https://sipadmin.1ounce.in/";

  @override
  void initState() {
    super.initState();
    loadWebView();
  }

  Future<void> loadWebView() async {
    // Simulate a delay before loading the web view
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Scaffold(
            body: Center(
              child:
                  Image.asset("assets/images/jlb.png", width: 250, height: 250),
            ),
          )
        : MyHomePage(initialUrl: url); // Replace with your Home class or widget
  }
}
