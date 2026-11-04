import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers.dart';
import '../../data/remote/backend.dart';
import '../../design/components/panel.dart';
import '../../design/components/states.dart';
import '../../design/tokens.dart';

/// Email + password or magic-link sign-in. Upgrading from guest keeps all
/// local data; the sync engine uploads it to the new account (A2).
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _message;
  bool _error = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function(SupabaseClient c) action, {String? success}) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null || _busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action(client);
      if (!mounted) return;
      setState(() {
        _message = success;
        _error = false;
      });
      if (success == null && context.mounted) context.canPop() ? context.pop() : context.go('/character');
    } on AuthException {
      if (mounted) {
        setState(() {
          _message = context.l10n.authInvalid;
          _error = true;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _message = context.l10n.errorGeneric;
          _error = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider).value;
    final configured = ref.watch(supabaseClientProvider) != null;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authTitle)),
      body: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsetsDirectional.all(AppSpace.lg),
            children: [
              if (!configured)
                ErrorState(message: l10n.authBackendMissing)
              else if (user != null)
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.signedInAs(user.email ?? ''), style: text.bodyLarge),
                      const SizedBox(height: AppSpace.lg),
                      OutlinedButton(
                        onPressed: _busy ? null : () => _run((c) => c.auth.signOut(), success: ''),
                        child: Text(l10n.signOut),
                      ),
                    ],
                  ),
                )
              else
                Panel(
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(labelText: l10n.authEmail),
                        ),
                        const SizedBox(height: AppSpace.md),
                        TextField(
                          controller: _password,
                          obscureText: true,
                          autofillHints: const [AutofillHints.password],
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(labelText: l10n.authPassword),
                        ),
                        const SizedBox(height: AppSpace.lg),
                        FilledButton(
                          onPressed: _busy
                              ? null
                              : () => _run(
                                  (c) => c.auth.signInWithPassword(email: _email.text.trim(), password: _password.text),
                                ),
                          child: Text(l10n.signIn),
                        ),
                        const SizedBox(height: AppSpace.sm),
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _run((c) => c.auth.signUp(email: _email.text.trim(), password: _password.text)),
                          child: Text(l10n.createAccount),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _run(
                                  (c) => c.auth.signInWithOtp(email: _email.text.trim()),
                                  success: l10n.authMagicLinkSent,
                                ),
                          child: Text(l10n.authMagicLink),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_message != null && _message!.isNotEmpty) ...[
                const SizedBox(height: AppSpace.md),
                Text(
                  _message!,
                  style: text.bodyMedium?.copyWith(color: _error ? AppColors.ember : AppColors.attrVitality),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
