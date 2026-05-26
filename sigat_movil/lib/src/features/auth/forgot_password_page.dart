import 'package:flutter/material.dart';

import '../../core/session/session_controller.dart';
import '../../shared/widgets/auth_frame.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _resetStep = false;
  String _success = '';

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.watch(context);

    return AuthFrame(
      title: 'RECUPERAR',
      showBack: true,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: _resetStep
            ? _buildResetForm(context, session)
            : _buildEmailForm(context, session),
      ),
    );
  }

  Widget _buildEmailForm(BuildContext context, SessionController session) {
    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey('email'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electronico',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: _requiredEmail,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: session.isBusy ? null : () => _sendCode(context),
            child: Text(session.isBusy ? 'ENVIANDO...' : 'ENVIAR CODIGO'),
          ),
          AuthMessage(error: session.error, success: _success),
        ],
      ),
    );
  }

  Widget _buildResetForm(BuildContext context, SessionController session) {
    return Form(
      key: _resetFormKey,
      child: Column(
        key: const ValueKey('reset'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Codigo de 6 digitos',
              counterText: '',
            ),
            validator: (value) => (value == null || value.length != 6)
                ? 'Codigo requerido'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Nueva contrasena'),
            validator: (value) => (value == null || value.length < 6)
                ? 'Minimo 6 caracteres'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirmar contrasena',
            ),
            validator: (value) => value != _passwordController.text
                ? 'Las contrasenas no coinciden'
                : null,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: session.isBusy ? null : () => _resetPassword(context),
            child: Text(
              session.isBusy ? 'ACTUALIZANDO...' : 'ACTUALIZAR CONTRASENA',
            ),
          ),
          AuthMessage(error: session.error, success: _success),
        ],
      ),
    );
  }

  Future<void> _sendCode(BuildContext context) async {
    if (!(_emailFormKey.currentState?.validate() ?? false)) return;
    setState(() => _success = '');
    final ok = await SessionScope.read(
      context,
    ).requestPasswordReset(_emailController.text.trim());
    if (!context.mounted) return;
    if (ok) {
      setState(() {
        _resetStep = true;
        _success = 'Te enviamos un codigo unico a tu correo.';
      });
    }
  }

  Future<void> _resetPassword(BuildContext context) async {
    if (!(_resetFormKey.currentState?.validate() ?? false)) return;
    setState(() => _success = '');
    final ok = await SessionScope.read(context).resetPassword({
      'email': _emailController.text.trim(),
      'code': _codeController.text.trim(),
      'newPassword': _passwordController.text,
    });

    if (!context.mounted) return;
    if (ok) {
      setState(() => _success = 'Contrasena actualizada');
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  String? _requiredEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo requerido';
    if (!value.contains('@')) return 'Correo no valido';
    return null;
  }
}
