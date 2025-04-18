import 'package:flutter/material.dart';
import 'package:finiapp/screens/main/components/splashscreen.dart';
import 'package:finiapp/services/auth_service.dart';
import 'package:finiapp/widgets/buttons/button_continue_loading_widget.dart';
import 'package:finiapp/screens/login/phone_login.dart';
import 'package:finiapp/widgets/horizontal_line.dart';
import 'package:finiapp/widgets/signup_with_phone.dart';
import 'package:finiapp/widgets/social_button.dart';
import 'package:provider/provider.dart';

class SignInWithPrecache extends StatefulWidget {
  const SignInWithPrecache({super.key});

  @override
  State<SignInWithPrecache> createState() => _SignInWithPrecacheState();
}

class _SignInWithPrecacheState extends State<SignInWithPrecache>
    with SingleTickerProviderStateMixin {
  bool _isReady = false;
  bool _showContent = false;
  late AnimationController _fadeController;
  bool _hasAttemptedNavigation = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Verificar inmediatamente si hay un usuario autenticado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndNavigate();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Precargar la imagen
    _precargar().then((_) {
      if (mounted) {
        setState(() => _isReady = true);
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() => _showContent = true);
            _fadeController.forward();

            // Verificar nuevamente tras completar la animación
            _checkAndNavigate();
          }
        });
      }
    });
  }

  // Un método único para manejar la navegación
  void _checkAndNavigate() {
    if (!mounted || _hasAttemptedNavigation) return;

    final authProvider = Provider.of<AuthService>(context, listen: false);

    print(
        "Verificando navegación: ${authProvider.currentUser != null ? 'Usuario autenticado' : 'Sin usuario'}");

    if (authProvider.currentUser != null) {
      setState(() => _hasAttemptedNavigation = true);

      print("🚀 Navegando a MainScreen desde _checkAndNavigate");

      // Navegación directa al MainScreen
      Navigator.of(context).pushReplacementNamed('/mainScreen');
    }
  }

  Future<void> _precargar() async {
    try {
      await precacheImage(
        const AssetImage('assets/images/login.png'),
        context,
      );
      // Reducir el tiempo de espera para mejorar UX
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      print("Error al precargar imagen: $e");
      // Continuar incluso si hay error
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios en el estado de autenticación
    final authProvider = Provider.of<AuthService>(context);

    // Si todavía no está listo, mostrar pantalla de carga
    if (!_isReady) {
      return const SplashScreen();
    }

    // Verificar nuevamente en el build
    if (authProvider.currentUser != null && !_hasAttemptedNavigation) {
      _hasAttemptedNavigation = true;

      // Usar una pequeña demora para evitar ejecutar durante el build
      Future.microtask(() {
        if (mounted && context.mounted) {
          print("🚀 Navegando a MainScreen desde build");
          Navigator.of(context).pushReplacementNamed('/mainScreen');
        }
      });
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    return Container(
      // Aplicar el gradiente a nivel de toda la pantalla
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0033), Colors.black],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
      child: AnimatedOpacity(
        opacity: _showContent ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 600),
        child: Scaffold(
          // Usar un Scaffold transparente para que se vea el gradiente
          backgroundColor: Colors.transparent,
          // Extender el contenido a toda la pantalla incluido el área de sistema
          extendBody: true,
          extendBodyBehindAppBar: true,
          body: SafeArea(
            // Desactivar el padding inferior para evitar cortes
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (isDesktop) {
                  return Row(
                    children: [
                      Expanded(
                        child: Image.asset(
                          "assets/images/login.png",
                          width: screenWidth * 0.8,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Expanded(child: _buildButtons(context, authProvider)),
                    ],
                  );
                } else {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Image.asset(
                          "assets/images/login.png",
                          width: screenWidth * 0.8,
                          fit: BoxFit.contain,
                        ),
                        _buildButtons(context, authProvider),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context, AuthService authProvider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSpacing = screenWidth > 600 ? 16.0 : 8.0;

    return Container(
      padding: EdgeInsets.all(screenWidth / 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SocialButton(
            name: "Entrar con Google",
            icon: "assets/icons/google.svg",
            onPressed: () => _signInWithGoogle(context),
          ),
          SizedBox(height: buttonSpacing * 2),
          const HorizontalLine(name: "O", height: 0.1),
          SizedBox(height: buttonSpacing),
          SignupWithPhone(
            name: "Ingresar con número",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PhoneLogin()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 50.0),
            child: IconOrSpinnerButton(
              showIcon: authProvider.isLoading,
              loading: authProvider.isLoading,
              onPressed: () {},
            ),
          )
        ],
      ),
    );
  }

  void _signInWithGoogle(BuildContext context) async {
    if (_hasAttemptedNavigation) return;

    final authProvider = Provider.of<AuthService>(context, listen: false);

    try {
      // Intentar iniciar sesión con Google
      await authProvider.signInWithGoogle();

      // Pequeña pausa para asegurar que los estados se actualicen
      await Future.delayed(const Duration(milliseconds: 500));

      // Verificar si el inicio de sesión fue exitoso
      if (authProvider.currentUser != null) {
        if (!mounted || !context.mounted) return;

        setState(() => _hasAttemptedNavigation = true);

        print("🚀 Navegando a MainScreen después de signInWithGoogle");

        // ¡NAVEGACIÓN FUERTE! Esta es la clave para garantizar que funcione
        Navigator.pushReplacementNamed(context, '/mainScreen');
      } else {
        if (!mounted || !context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo iniciar sesión con Google")),
        );
      }
    } catch (e) {
      if (!mounted || !context.mounted) return;

      print("Error al iniciar sesión con Google: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}
