import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/providers.dart';
import '../../design/tokens.dart';

/// Length of the one-time codes Auth emails (`auth.email.otp_length`).
const codeLength = 6;

/// [input] with Persian and Arabic-Indic digits turned into ASCII ones, so
/// codes typed on a Persian keyboard still verify.
String asciiDigits(String input) {
  final out = StringBuffer();
  for (final unit in input.runes) {
    if (unit >= 0x06F0 && unit <= 0x06F9) {
      out.writeCharCode(0x30 + unit - 0x06F0);
    } else if (unit >= 0x0660 && unit <= 0x0669) {
      out.writeCharCode(0x30 + unit - 0x0660);
    } else {
      out.writeCharCode(unit);
    }
  }
  return out.toString();
}

/// The one-time code inside pasted text such as "Your code: 123 456", or
/// null when there is none.
String? extractCode(String? text) {
  if (text == null) return null;
  final normalized = asciiDigits(text);
  final run = RegExp('(?<![0-9])[0-9]{$codeLength}(?![0-9])').firstMatch(normalized);
  if (run != null) return run.group(0);
  final digits = normalized.replaceAll(RegExp('[^0-9]'), '');
  return digits.length == codeLength ? digits : null;
}

/// A deliberately loose check; Auth has the final word.
bool isValidEmail(String email) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

/// `auth.minimum_password_length`.
const minPasswordLength = 8;

/// Mirrors `auth.password_requirements = "letters_digits"`, so a new
/// password is turned down before a round trip: at least
/// [minPasswordLength] characters with a Latin letter and a digit 0-9 (Auth
/// counts only those, not Persian letters or digits).
bool isAcceptablePassword(String password) =>
    password.length >= minPasswordLength && password.contains(RegExp('[A-Za-z]')) && password.contains(RegExp('[0-9]'));

/// Keeps a code field to [codeLength] ASCII digits and pulls the code out
/// of pasted text.
class CodeInputFormatter extends TextInputFormatter {
  const CodeInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final pasted = newValue.text.length - oldValue.text.length > 1 ? extractCode(newValue.text) : null;
    var digits = pasted ?? asciiDigits(newValue.text).replaceAll(RegExp('[^0-9]'), '');
    if (digits.length > codeLength) digits = digits.substring(0, codeLength);
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

/// Emblem, headline and a line on why to sign in.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, this.body, this.icon = Icons.local_fire_department_rounded});

  final String title;
  final String? body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Column(
      children: [
        ExcludeSemantics(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [p.glow, p.sunken]),
              border: Border.all(color: p.hairline),
              boxShadow: AppShadows.glow(p.accent, strength: p.isDark ? 0.22 : 0.14, blur: 22),
            ),
            child: Icon(icon, size: 34, color: p.accent),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Semantics(
          header: true,
          child: Text(title, style: text.headlineSmall, textAlign: TextAlign.center),
        ),
        if (body != null) ...[
          const SizedBox(height: AppSpace.sm),
          Text(
            body!,
            style: text.bodyMedium?.copyWith(color: p.inkMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Status line under a form. Announced by screen readers when it changes.
class AuthMessage extends StatelessWidget {
  const AuthMessage({super.key, required this.message, this.isError = true});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = isError ? p.accent : p.success;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm + 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppRadius.softAll,
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(isError ? Icons.error_outline_rounded : Icons.mark_email_read_outlined, size: 18, color: color),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: p.ink)),
            ),
          ],
        ),
      ),
    );
  }
}

/// "or" between the email form and the provider buttons.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(child: Divider(color: p.hairline)),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.md),
          child: Text(context.l10n.authOr, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: p.inkMuted)),
        ),
        Expanded(child: Divider(color: p.hairline)),
      ],
    );
  }
}

/// Outlined button for a third-party sign-in.
class ProviderButton extends StatelessWidget {
  const ProviderButton({super.key, required this.label, required this.mark, required this.onPressed});

  final String label;
  final Widget mark;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ExcludeSemantics(child: mark),
        const SizedBox(width: AppSpace.sm + 2),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );
}

/// Round badge standing in for a provider's logo (no remote images).
class ProviderMark extends StatelessWidget {
  const ProviderMark(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 24,
      height: 24,
      alignment: AlignmentDirectional.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: p.ink),
      child: Icon(icon, size: 15, color: p.canvas),
    );
  }
}

/// Password field with a show/hide toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.helper,
    this.newPassword = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? helper;

  /// Hints password managers to suggest a new password instead of filling
  /// the saved one.
  final bool newPassword;
  final VoidCallback? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextField(
      controller: widget.controller,
      obscureText: !_visible,
      enableSuggestions: false,
      autocorrect: false,
      autofillHints: [widget.newPassword ? AutofillHints.newPassword : AutofillHints.password],
      textDirection: TextDirection.ltr,
      textInputAction: TextInputAction.done,
      onSubmitted: widget.onSubmitted == null ? null : (_) => widget.onSubmitted!(),
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helper,
        suffixIcon: IconButton(
          tooltip: _visible ? l10n.authHidePassword : l10n.authShowPassword,
          icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
    );
  }
}

/// Email address field.
class EmailField extends StatelessWidget {
  const EmailField({super.key, required this.controller, this.autofocus = false, this.onSubmitted});

  final TextEditingController controller;
  final bool autofocus;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    autofocus: autofocus,
    keyboardType: TextInputType.emailAddress,
    autofillHints: const [AutofillHints.email, AutofillHints.username],
    autocorrect: false,
    enableSuggestions: false,
    textDirection: TextDirection.ltr,
    textInputAction: onSubmitted == null ? TextInputAction.next : TextInputAction.go,
    onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
    decoration: InputDecoration(
      labelText: context.l10n.authEmail,
      prefixIcon: const Icon(Icons.alternate_email_rounded),
    ),
  );
}

/// The 6-digit code: one wide field so paste, the keyboard's code
/// suggestion and screen readers all work as usual. Verifies itself when
/// the last digit lands.
class CodeField extends StatelessWidget {
  const CodeField({super.key, required this.controller, required this.onCompleted, this.enabled = true});

  final TextEditingController controller;
  final VoidCallback onCompleted;
  final bool enabled;

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final code = extractCode(data?.text);
    if (code == null) return;
    controller.value = TextEditingValue(
      text: code,
      selection: TextSelection.collapsed(offset: code.length),
    );
    onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontFamily: 'Inter',
      fontFeatures: const [FontFeature.tabularFigures()],
      letterSpacing: 10,
      fontWeight: FontWeight.w600,
    );
    return TextField(
      controller: controller,
      enabled: enabled,
      autofocus: true,
      keyboardType: TextInputType.number,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: const [CodeInputFormatter()],
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      textInputAction: TextInputAction.done,
      style: style,
      onChanged: (v) {
        if (v.length == codeLength) onCompleted();
      },
      onSubmitted: (_) => onCompleted(),
      decoration: InputDecoration(
        labelText: l10n.authCodeLabel,
        hintText: '••••••',
        floatingLabelAlignment: FloatingLabelAlignment.center,
        contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xxxl, vertical: AppSpace.lg),
        suffixIcon: IconButton(
          tooltip: l10n.authPasteCode,
          icon: const Icon(Icons.content_paste_rounded),
          onPressed: enabled ? _paste : null,
        ),
      ),
    );
  }
}
