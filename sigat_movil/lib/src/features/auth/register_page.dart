import 'package:flutter/material.dart';

import '../../core/session/session_controller.dart';
import '../../shared/widgets/auth_frame.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String _success = '';

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.watch(context);

    return AuthFrame(
      title: 'REGISTRARSE',
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nombreController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nombres',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _apellidoController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Apellidos',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Contrasena',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: _password,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar contrasena',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
              validator: _confirmPassword,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: session.isBusy ? null : () => _register(context),
              child: Text(session.isBusy ? 'REGISTRANDO...' : 'REGISTRARSE'),
            ),
            AuthMessage(error: session.error, success: _success),
          ],
        ),
      ),
    );
  }

  Future<void> _register(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _success = '');
    final session = SessionScope.read(context);
    final ok = await session.register({
      'nombre': _nombreController.text.trim(),
      'apellido': _apellidoController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
    });

    if (!context.mounted) return;
    if (ok) {
      setState(() => _success = 'Registro exitoso');
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
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

  String? _password(String? value) {
    if (value == null || value.length < 6) return 'Minimo 6 caracteres';
    return null;
  }

  String? _confirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Las contrasenas no coinciden';
    }
    return null;
  }
}
