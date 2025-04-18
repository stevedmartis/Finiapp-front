import 'package:finiapp/screens/main/components/login_precharge.dart';
import 'package:flutter/material.dart';

// Clase personalizada para transición sin parpadeo
class NoFlickerPageRoute extends PageRouteBuilder {
  final Widget Function(BuildContext) builder;

  NoFlickerPageRoute({required this.builder})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Usar solo transiciones de opacidad
            var fadeAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: child,
            );
          },
          // Duración más corta para la transición
          transitionDuration: const Duration(milliseconds: 300),
          // Importante: mantener el mismo color de fondo durante la transición
          opaque: false,
          barrierColor: Colors.transparent,
          maintainState: true,
        );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool _nextScreenReady = false;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _textController.forward();
    });

    // Precargar recursos antes de navegar
    _preloadNextScreen();
  }

  Future<void> _preloadNextScreen() async {
    try {
      // Precargar la imagen de login
      await precacheImage(
        const AssetImage('assets/images/login.png'),
        context,
      );

      // Esperar un tiempo mínimo para mostrar el splash
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        setState(() {
          _nextScreenReady = true;
        });

        // Navegar a la siguiente pantalla con transición personalizada
        _navigateToNextScreen();
      }
    } catch (e) {
      print("Error precargando recursos: $e");
      // En caso de error, navegar después de un tiempo mínimo
      if (mounted) {
        Future.delayed(const Duration(seconds: 3), () {
          _navigateToNextScreen();
        });
      }
    }
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    // Usar la ruta personalizada para evitar parpadeos
    Navigator.of(context).pushReplacement(
      NoFlickerPageRoute(
        builder: (context) => const SignInWithPrecache(),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No establecer color de fondo para el Scaffold
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Color(0xFF1A0033)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _logoController,
                child: AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple
                                .withOpacity(_glowAnimation.value),
                            blurRadius: 60,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/finia_logo.png',
                        width: 120,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _textController,
                child: Column(
                  children: const [
                    Text(
                      "finIA",
                      style: TextStyle(
                        fontSize: 26,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Tu mente financiera potenciada con IA",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              // Mostrar un indicador de carga mientras los recursos se precargan
              if (!_nextScreenReady)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.6),
                      ),
                      strokeWidth: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
