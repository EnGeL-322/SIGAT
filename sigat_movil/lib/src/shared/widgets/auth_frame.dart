import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AuthFrame extends StatelessWidget {
  const AuthFrame({
    super.key,
    required this.title,
    required this.child,
    this.showBack = false,
  });

  final String title;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/bg-auth.png', fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.navy.withValues(alpha: 0.72),
                  AppTheme.blue.withValues(alpha: 0.34),
                  Colors.white.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (showBack)
                        IconButton.filledTonal(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Atras',
                        ),
                      Expanded(
                        child: Align(
                          alignment: showBack
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Image.asset(
                            'assets/images/logo-sigat.png',
                            height: 72,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 44),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.ink.withValues(alpha: 0.18),
                          blurRadius: 30,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthMessage extends StatelessWidget {
  const AuthMessage({super.key, this.error, this.success});

  final String? error;
  final String? success;

  @override
  Widget build(BuildContext context) {
    final text = (error?.isNotEmpty ?? false) ? error! : success;
    if (text == null || text.isEmpty) return const SizedBox.shrink();

    final isError = error?.isNotEmpty ?? false;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isError ? const Color(0xFF7D1832) : const Color(0xFF0F6F38),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
