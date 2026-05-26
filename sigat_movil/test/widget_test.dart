import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigat_movil/src/app/sigat_app.dart';

void main() {
  testWidgets('muestra pantalla de login', (tester) async {
    await tester.pumpWidget(const SigatAppTestHost());
    await tester.pumpAndSettle();

    expect(find.text('INICIAR SESION'), findsWidgets);
    expect(find.text('REGISTRARTE'), findsOneWidget);
  });
}

class SigatAppTestHost extends StatelessWidget {
  const SigatAppTestHost({super.key});

  @override
  Widget build(BuildContext context) => const SigatApp();
}
