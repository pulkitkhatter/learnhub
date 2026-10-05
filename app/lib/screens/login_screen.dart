import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../state/auth_controller.dart';

// Seeded by the server on start-up so reviewers can try the app instantly.
const _demoEmail = 'demo@learnhub.dev';
const _demoPassword = 'demo1234';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _register = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit({String? email, String? password}) async {
    if (email == null && !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthController>();
    try {
      if (_register && email == null) {
        await auth.register(_name.text, _email.text, _password.text);
      } else {
        await auth.login(email ?? _email.text, password ?? _password.text);
      }
      // Router redirects once the auth state changes.
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.school_rounded, size: 56, color: scheme.primary),
                    const SizedBox(height: 12),
                    Text('LearnHub',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      _register ? 'Create your account' : 'Sign in to continue learning',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 28),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: _register
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: TextFormField(
                                controller: _name,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.name],
                                decoration: const InputDecoration(
                                    labelText: 'Name', prefixIcon: Icon(Icons.person_outline)),
                                validator: (v) => (v ?? '').trim().length < 2
                                    ? 'Enter your name'
                                    : null,
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                          labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                      validator: (v) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch((v ?? '').trim())
                          ? null
                          : 'Enter a valid email',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _busy ? null : _submit(),
                      autofillHints: [
                        _register ? AutofillHints.newPassword : AutofillHints.password
                      ],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v ?? '').length < 6
                          ? 'Use at least 6 characters'
                          : null,
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: _error == null
                          ? const SizedBox(width: double.infinity)
                          : Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: scheme.errorContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(children: [
                                  Icon(Icons.error_outline, color: scheme.onErrorContainer),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(_error!,
                                        style: TextStyle(color: scheme.onErrorContainer)),
                                  ),
                                ]),
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5))
                          : Text(_register ? 'Create account' : 'Sign in'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _register = !_register;
                                _error = null;
                              }),
                      child: Text(_register
                          ? 'Already have an account? Sign in'
                          : "New here? Create an account"),
                    ),
                    const Divider(height: 32),
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _submit(email: _demoEmail, password: _demoPassword),
                      icon: const Icon(Icons.rocket_launch_outlined),
                      label: const Text('Try the demo account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
