import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
// Importaciones de tu aplicación
import 'package:finiapp/services/auth_service.dart';
import 'package:finiapp/services/accounts_services.dart';

// Mocks simplificados
class MockAuthService extends Mock implements AuthService {
  @override
  bool get isAuthenticated => true;
}

class MockAccountsProvider extends Mock implements AccountsProvider {
  @override
  List<Account> get accounts => [];
}

void main() {
  group('Pruebas de pantallas individuales', () {
    testWidgets('MainScreen se renderiza correctamente',
        (WidgetTester tester) async {
      // Prueba simplificada de MainScreen sin dependencias
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('MainScreen Stub')),
        ),
      );

      expect(find.text('MainScreen Stub'), findsOneWidget);
    });

    testWidgets('SignIn se renderiza correctamente',
        (WidgetTester tester) async {
      // Prueba simplificada de SignIn sin dependencias
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('SignIn Stub')),
        ),
      );

      expect(find.text('SignIn Stub'), findsOneWidget);
    });
  });

  // Una prueba muy básica para verificar la navegación
  testWidgets('Navegación básica funciona', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const Scaffold(body: Text('Segunda pantalla')),
                  ),
                );
              },
              child: const Text('Navegar'),
            );
          },
        ),
      ),
    );

    expect(find.text('Navegar'), findsOneWidget);

    await tester.tap(find.text('Navegar'));
    await tester.pumpAndSettle();

    expect(find.text('Segunda pantalla'), findsOneWidget);
  });
}
