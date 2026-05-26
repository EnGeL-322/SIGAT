import 'package:flutter/material.dart';

import '../../core/session/session_controller.dart';
import '../../shared/widgets/auth_frame.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.watch(context);

    return AuthFrame(
      title: 'INICIAR SESION',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Correo electronico',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: _requiredEmail,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contrasena',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: _required,
              onFieldSubmitted: (_) => _login(context),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/forgot-password'),
                child: const Text('SE TE OLVIDO LA CONTRASENA?'),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: session.isBusy ? null : () => _login(context),
              child: Text(session.isBusy ? 'INGRESANDO...' : 'INICIAR SESION'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: session.isBusy
                  ? null
                  : () => Navigator.pushNamed(context, '/register'),
              child: const Text('REGISTRARTE'),
            ),
            AuthMessage(error: session.error),
          ],
        ),
      ),
    );
  }

  Future<void> _login(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final session = SessionScope.read(context);
    final ok = await session.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (!context.mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false);
    }
  }

  String? _required(String? value) {
    return (value == null || value.trim().isEmpty) ? 'Campo requerido' : null;
  }

  String? _requiredEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo requerido';
    if (!value.contains('@')) return 'Correo no valido';
    return null;
  }
}
