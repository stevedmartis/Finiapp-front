import 'dart:io';

import 'package:finiapp/models/create_user_dto.dart';
import 'package:finiapp/responses/userResponse.dart';
import 'package:finiapp/services/accounts_services.dart';
import 'package:finiapp/services/finance_summary_service.dart';
import 'package:finiapp/services/transaction_service.dart';
import 'package:finiapp/storage/auth_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  //final GoogleSignIn _googleSignIn = GoogleSignIn();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  UserAuth? currentUser; // Almacena la información del usuario globalmente
  bool isLoading = false;

  int _index = 0;

  // Getter to get the card number
  int get index => _index;

  // Setter to set the card number and notify listeners
  set cardSelectNumber(int newNumber) {
    _index = newNumber;
    notifyListeners(); // Notify all listening widgets of a change
  }

  String? _cardsHero = 'cardsHome';

  // Getter to get the card number
  String? get cardsHero => _cardsHero;

  // Setter to set the card number and notify listeners
  set cardsHero(String? value) {
    _cardsHero = value;
    notifyListeners(); // Notify all listening widgets of a change
  }

  final TokenStorage tokenStorage = TokenStorage();

  AuthService() {
    loadUserData();
    _listenAuthState();
  }

  // Method to check the validity of the session
  Future<bool> checkSession() async {
    // Try to refresh the token to check session validity
    bool isTokenRefreshed = await refreshToken();
    if (isTokenRefreshed) {
      // If the token is successfully refreshed, the session is valid
      return true;
    } else {
      // If the token could not be refreshed, it may be expired or invalid
      return false;
    }
  }

  Future<void> loadUserData() async {
    currentUser = await tokenStorage.getUser();
    if (currentUser != null) {
      notifyListeners();
    }
  }

  Future<bool> refreshToken() async {
    String? refreshToken = await tokenStorage.getRefreshToken();

    if (refreshToken == null) {
      // No refresh token available; user needs to log in again.
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/user/refresh-access-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        await tokenStorage.saveToken(data['accessToken'], data['refreshToken']);
        return true; // Token was refreshed successfully
      } else {
        // Handle error, token refresh failed
        return false;
      }
    } catch (e) {
      // Network error, parsing error, etc.
      return false;
    }
  }

  bool isLogin = false;
  bool get isAuthenticated => _firebaseAuth.currentUser != null;

  UserAuth? get globalUser => currentUser; // Devuelve el AppUser global

  bool _handledSignOut = false;
  void _listenAuthState() {
    _firebaseAuth.authStateChanges().listen((User? user) async {
      print("👤 Estado de autenticación cambiado: $user");

      if (user != null) {
        _handledSignOut = false;

        currentUser = UserAuth(
          userId: user.uid,
          email: user.email,
          fullName: user.displayName,
          accessToken: await user.getIdToken(),
          refreshToken: "",
          photoUrl: user.photoURL,
        );

        await tokenStorage.saveUser(currentUser!);
        notifyListeners();
      } else if (!_handledSignOut) {
        _handledSignOut = true;
        currentUser = null;
        await tokenStorage.deleteAllTokens();
        notifyListeners();
      }
    });
  }

  Future<void> signInWithGoogle() async {
    try {
      isLoading = true;
      notifyListeners();

      // Intento de inicio de sesión con Google con timeout
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signIn().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            print("⚠️ Timeout en el inicio de sesión con Google");
            return null;
          },
        );
      } catch (e) {
        print("🔴 Error específico en _googleSignIn.signIn(): $e");
        // Intenta hacer un signOut para limpiar cualquier estado pendiente
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
        rethrow;
      }

      if (googleUser == null) {
        print(
            "⚠️ El usuario canceló el inicio de sesión con Google o hubo un error");
        isLoading = false;
        notifyListeners();
        return;
      }

      // Obtener tokens de autenticación
      GoogleSignInAuthentication? googleAuth;
      try {
        googleAuth = await googleUser.authentication;
      } catch (e) {
        print("🔴 Error al obtener autenticación de Google: $e");
        isLoading = false;
        notifyListeners();
        return;
      }

      // Flujo específico por plataforma
      if (Platform.isIOS) {
        // Flujo para iOS
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        try {
          final UserCredential authResult =
              await _firebaseAuth.signInWithCredential(credential);
          final User? firebaseUser = authResult.user;

          if (firebaseUser != null) {
            final String? token = await firebaseUser.getIdToken();

            currentUser = UserAuth(
              userId: firebaseUser.uid,
              email: firebaseUser.email,
              fullName: firebaseUser.displayName,
              accessToken: token,
              refreshToken: "",
              photoUrl: firebaseUser.photoURL,
            );

            await tokenStorage.saveUser(currentUser!);
          }
        } catch (e) {
          print("🔴 Error al iniciar sesión con Firebase: $e");
          isLoading = false;
          notifyListeners();
          return;
        }
      } else {
        // Flujo para Android - usando Firebase directamente también para Android
        try {
          // Crear credencial
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          // Iniciar sesión con Firebase
          final UserCredential authResult =
              await _firebaseAuth.signInWithCredential(credential);
          final User? firebaseUser = authResult.user;

          if (firebaseUser != null) {
            final String? token = await firebaseUser.getIdToken();

            currentUser = UserAuth(
              userId: firebaseUser.uid,
              email: firebaseUser.email,
              fullName: firebaseUser.displayName,
              accessToken: token,
              refreshToken: "",
              photoUrl: firebaseUser.photoURL,
            );

            await tokenStorage.saveUser(currentUser!);
          } else {
            print("⚠️ No se pudo obtener el usuario de Firebase");
          }
        } catch (e) {
          print("🔴 Error en el flujo de Android con Firebase: $e");
          isLoading = false;
          notifyListeners();
          return;
        }
      }

      notifyListeners();
    } catch (error) {
      print("🔴 Error general en signInWithGoogle: $error");
      // No lanzar el error, solo registrarlo
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

/*   Future<void> register(CreateUserDto user) async {
    var url = Uri.parse('http://localhost:3000/user');
    var headers = {'Content-Type': 'application/json'};
    var body = jsonEncode(user.toJson());

    try {
      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 201) {
        var data = jsonDecode(response.body);
        if (data != null && data is Map<String, dynamic>) {
          if (data['accessToken'] != null && data['refreshToken'] != null) {
            await tokenStorage.saveToken(
                data['accessToken'], data['refreshToken']);

            currentUser = UserAuth.fromJson(data);

            if (currentUser != null) {
              await tokenStorage.saveUser(currentUser!);
              isLoading = false;
              //notifyListeners();
            } else {}
          } else {}
        } else {}
      } else {}
    } catch (e) {
      return;
    } finally {
      isLoading =
          false; // Establecer isLoading como false después de completar la solicitud de registro
      notifyListeners();
    }
  }
 */
  Future<void> register(CreateUserDto user) async {
    try {
      // Simular token ficticio (puedes usar UUID o lo que quieras)
      final fakeAccessToken = 'token_falso_${user.email}';
      const fakeRefreshToken = 'refresh_token_falso';

      await tokenStorage.saveToken(fakeAccessToken, fakeRefreshToken);

      currentUser = UserAuth(
        email: user.email,
        fullName: user.fullName,
        accessToken: fakeAccessToken,
        refreshToken: fakeRefreshToken,
      );

      await tokenStorage.saveUser(currentUser!);
    } catch (e) {
      print('Error simulado al registrar: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut({
    AccountsProvider? accountsProvider,
    TransactionProvider? transactionProvider,
    FinancialDataService? financialProvider,
  }) async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      await tokenStorage.deleteAllTokens();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // 🔥 Limpiar datos de la app
      currentUser = null;
      isLoading = false;

      // ✅ Borrar datos locales
      await accountsProvider?.clearAccounts();
      await transactionProvider?.clearTransactions();
      await financialProvider?.clearFinanceData();
      await prefs.setBool("hasCompletedOnboarding", false);
      notifyListeners();
    } catch (error) {
      print("❌ Error en signOut: $error");
    }
  }
}
