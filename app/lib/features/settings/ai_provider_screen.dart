import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wyrd_engine/wyrd_engine.dart';

import '../../app/providers.dart';
import '../../data/ai/ai_client.dart';
import '../../data/ai/ai_evaluator.dart';
import '../../design/components/panel.dart';
import '../../design/tokens.dart';
import '../../l10n/content.dart';
import '../../l10n/generated/app_localizations.dart';

String aiProviderLabel(AppLocalizations l10n, AiProviderKind k) => switch (k) {
  AiProviderKind.anthropic => l10n.aiProviderAnthropic,
  AiProviderKind.openai => l10n.aiProviderOpenai,
  AiProviderKind.gemini => l10n.aiProviderGemini,
  AiProviderKind.anthropicCompatible => l10n.aiProviderAnthropicCompatible,
  AiProviderKind.openaiCompatible => l10n.aiProviderOpenaiCompatible,
};

String aiErrorText(AppLocalizations l10n, AiException e) => switch (e.kind) {
  AiErrorKind.auth => l10n.aiErrAuth,
  AiErrorKind.rateLimited => l10n.aiErrRate,
  AiErrorKind.network => l10n.aiErrNetwork,
  AiErrorKind.refused => l10n.aiErrRefused,
  AiErrorKind.badResponse => l10n.aiErrBadResponse,
  AiErrorKind.http => l10n.aiErrHttp('${e.status ?? ''}'),
};

/// Connect your own AI provider: Anthropic, OpenAI, Google Gemini or any
/// service speaking the Anthropic or OpenAI protocol.
class AiProviderScreen extends ConsumerStatefulWidget {
  const AiProviderScreen({super.key});

  @override
  ConsumerState<AiProviderScreen> createState() => _AiProviderScreenState();
}

class _AiProviderScreenState extends ConsumerState<AiProviderScreen> {
  final _baseUrl = TextEditingController();
  final _model = TextEditingController();
  final _key = TextEditingController();
  AiProviderKind _kind = AiProviderKind.anthropic;
  bool _hasKey = false;
  bool _busy = false;
  bool _loaded = false;
  String? _status;
  bool _statusOk = false;

  static const _defaultModels = {AiProviderKind.anthropic: 'claude-opus-5-5'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(aiSettingsRepositoryProvider);
    final config = await repo.config();
    bool hasKey;
    try {
      hasKey = await repo.hasKey();
    } on Object {
      hasKey = false;
    }
    if (!mounted) return;
    setState(() {
      if (config != null) {
        _kind = config.kind;
        _model.text = config.model;
        _baseUrl.text = config.baseUrl;
      } else {
        _model.text = _defaultModels[_kind] ?? '';
      }
      _hasKey = hasKey;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _model.dispose();
    _key.dispose();
    super.dispose();
  }

  AiProviderConfig get _config =>
      AiProviderConfig(kind: _kind, model: _model.text.trim(), baseUrl: _baseUrl.text.trim());

  Future<void> _save() async {
    setState(() => _busy = true);
    final enteredKey = _key.text.trim().isNotEmpty;
    await ref.read(aiSettingsRepositoryProvider).save(_config, apiKey: _key.text);
    _key.clear();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _hasKey = _hasKey || enteredKey;
      _status = context.l10n.aiSaved;
      _statusOk = true;
    });
  }

  /// Saves, then evaluates a sample quest end to end with the real provider.
  Future<void> _test() async {
    final l10n = context.l10n;
    await _save();
    setState(() => _busy = true);
    try {
      final client = await ref.read(aiSettingsRepositoryProvider).client();
      if (client == null) throw const AiException(AiErrorKind.auth);
      final p = await AiEvaluator(client).evaluate(
        AiEvaluationInput(
          title: l10n.suggestStudy,
          tier: QuestTier.daily,
          declaredMinutes: 30,
          outputLanguage: ref.read(regionalProvider).locale.languageCode,
        ),
      );
      _status = l10n.aiTestOk(l10n.categoryName(p.category));
      _statusOk = true;
    } on AiException catch (e) {
      _status = l10n.aiTestFailed(aiErrorText(l10n, e));
      _statusOk = false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    await ref.read(aiSettingsRepositoryProvider).clear();
    if (mounted) context.canPop() ? context.pop() : context.go('/settings');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final ready = _model.text.trim().isNotEmpty && (!_kind.customEndpoint || _baseUrl.text.trim().startsWith('http'));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiProvider),
        leading: context.canPop()
            ? null
            : IconButton(
                tooltip: l10n.actionClose,
                icon: const Icon(Icons.close),
                onPressed: () => context.go('/settings'),
              ),
      ),
      body: !_loaded
          ? const SizedBox.shrink()
          : Align(
              alignment: AlignmentDirectional.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsetsDirectional.all(AppSpace.lg),
                  children: [
                    Text(l10n.aiProviderHelp, style: text.bodyMedium),
                    const SizedBox(height: AppSpace.lg),
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<AiProviderKind>(
                            initialValue: _kind,
                            isExpanded: true,
                            decoration: InputDecoration(labelText: l10n.aiProviderKind),
                            items: [
                              for (final k in AiProviderKind.values)
                                DropdownMenuItem(value: k, child: Text(aiProviderLabel(l10n, k))),
                            ],
                            onChanged: (k) => setState(() {
                              if (k == null) return;
                              if (_model.text.trim().isEmpty || _model.text == _defaultModels[_kind]) {
                                _model.text = _defaultModels[k] ?? '';
                              }
                              _kind = k;
                            }),
                          ),
                          if (_kind.customEndpoint) ...[
                            const SizedBox(height: AppSpace.md),
                            TextField(
                              controller: _baseUrl,
                              keyboardType: TextInputType.url,
                              textDirection: TextDirection.ltr,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(labelText: l10n.aiBaseUrl, hintText: l10n.aiBaseUrlHint),
                            ),
                          ],
                          const SizedBox(height: AppSpace.md),
                          TextField(
                            controller: _model,
                            textDirection: TextDirection.ltr,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(labelText: l10n.aiModel, helperText: l10n.aiModelHint),
                          ),
                          const SizedBox(height: AppSpace.md),
                          TextField(
                            controller: _key,
                            obscureText: true,
                            autocorrect: false,
                            enableSuggestions: false,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              labelText: l10n.aiApiKey,
                              helperText: _hasKey ? l10n.aiApiKeySaved : null,
                            ),
                          ),
                          if (kIsWeb) ...[
                            const SizedBox(height: AppSpace.sm),
                            Text(l10n.aiWebKeyNote, style: text.bodySmall),
                          ],
                          const SizedBox(height: AppSpace.lg),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _busy || !ready ? null : _test,
                                  child: Text(l10n.aiTest),
                                ),
                              ),
                              const SizedBox(width: AppSpace.md),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _busy || !ready ? null : _save,
                                  child: Text(l10n.actionSave),
                                ),
                              ),
                            ],
                          ),
                          if (_busy) ...[const SizedBox(height: AppSpace.md), const LinearProgressIndicator()],
                          if (_status != null) ...[
                            const SizedBox(height: AppSpace.md),
                            Text(
                              _status!,
                              style: text.bodyMedium?.copyWith(
                                color: _statusOk ? AppColors.attrVitality : AppColors.ember,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    TextButton(onPressed: _remove, child: Text(l10n.aiRemove)),
                  ],
                ),
              ),
            ),
    );
  }
}
