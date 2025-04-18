import 'package:finiapp/screens/main/components/splashscreen.dart';
import 'package:finiapp/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashController extends StatefulWidget {
  const SplashController({super.key});

  @override
  State<SplashController> createState() => _SplashControllerState();
}

class _SplashControllerState extends State<SplashController> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (auth.currentUser != null) {
        Navigator.pushReplacementNamed(context, '/mainScreen');
      } else {
        Navigator.pushReplacementNamed(context, '/signIn');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen(); // tu pantalla con animación
  }
}
