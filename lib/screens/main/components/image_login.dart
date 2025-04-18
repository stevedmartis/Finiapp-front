import 'package:flutter/material.dart';

class LoginIllustration extends StatefulWidget {
  const LoginIllustration({super.key});

  @override
  State<LoginIllustration> createState() => _LoginIllustrationState();
}

class _LoginIllustrationState extends State<LoginIllustration> {
  bool _isLoaded = false;
  bool _hasPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasPrecached) {
      precacheImage(
        const AssetImage('assets/images/login.png'),
        context,
      ).then((_) {
        if (mounted) {
          setState(() {
            _isLoaded = true;
          });
        }
      });
      _hasPrecached =
          true; // evita que lo vuelva a hacer si cambia dependencias
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: _isLoaded
          ? AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: 1.0,
              child: Image.asset(
                'assets/images/login.png',
                width: screenWidth * 0.8,
                fit: BoxFit.contain,
              ),
            )
          : const Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
    );
  }
}
