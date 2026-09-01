import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'conversation_screen.dart';
import 'settings_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.apiKey});

  final String apiKey;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  LanguageOption _target = languages[0];
  LanguageOption _native = languageByCode('en');
  CefrLevel _level = CefrLevel.a1;
  String _situationId = 'coffee';
  String _customSituation = '';
  CorrectionStyle _correctionStyle = CorrectionStyle.inline;
  SpeakingPace _pace = SpeakingPace.normal;
  MicMode _micMode = MicMode.openMic;

  String get _situationText {
    if (_situationId == 'custom') return _customSituation.trim();
    final preset = situationPresets.firstWhere((p) => p.id == _situationId);
    return '${preset.title}: ${preset.description}';
  }

  void _start() {
    if (_situationId == 'custom' && _customSituation.trim().isEmpty) return;

    final config = SessionConfig(
      targetLanguage: _target,
      nativeLanguage: _native,
      level: _level,
      situation: _situationText,
      correctionStyle: _correctionStyle,
      pace: _pace,
      micMode: _micMode,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConversationScreen(
          apiKey: widget.apiKey,
          config: config,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final targets = languages.where((l) => l.code != _native.code).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Tutor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Practice any language\nthrough conversation',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _label('Language to practice'),
          DropdownButtonFormField<LanguageOption>(
            value: _target,
            items: targets
                .map((l) => DropdownMenuItem(
                      value: l,
                      child: Text('${l.name} (${l.nativeName})'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _target = v!),
          ),
          const SizedBox(height: 16),
          _label('Your native language'),
          DropdownButtonFormField<LanguageOption>(
            value: _native,
            items: languages
                .map((l) => DropdownMenuItem(value: l, child: Text(l.name)))
                .toList(),
            onChanged: (v) => setState(() {
              _native = v!;
              if (_target.code == _native.code) {
                _target = targets.first;
              }
            }),
          ),
          const SizedBox(height: 16),
          _label('Level: ${_level.label}'),
          Slider(
            value: _level.index.toDouble(),
            min: 0,
            max: (cefrLevels.length - 1).toDouble(),
            divisions: cefrLevels.length - 1,
            label: _level.label,
            onChanged: (v) => setState(() => _level = cefrLevels[v.round()]),
          ),
          Text(
            levelDescriptions[_level]!,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _label('Situation'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: situationPresets.map((preset) {
              final selected = _situationId == preset.id;
              return ChoiceChip(
                label: Text('${preset.icon} ${preset.title}'),
                selected: selected,
                selectedColor: AppTheme.accent.withOpacity(0.3),
                onSelected: (_) => setState(() => _situationId = preset.id),
              );
            }).toList(),
          ),
          if (_situationId == 'custom') ...[
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(hintText: 'Describe your situation...'),
              onChanged: (v) => _customSituation = v,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Corrections'),
                    DropdownButtonFormField<CorrectionStyle>(
                      value: _correctionStyle,
                      items: const [
                        DropdownMenuItem(value: CorrectionStyle.inline, child: Text('Inline')),
                        DropdownMenuItem(value: CorrectionStyle.endOfTurn, child: Text('End of turn')),
                        DropdownMenuItem(value: CorrectionStyle.off, child: Text('Off')),
                      ],
                      onChanged: (v) => setState(() => _correctionStyle = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Pace'),
                    DropdownButtonFormField<SpeakingPace>(
                      value: _pace,
                      items: const [
                        DropdownMenuItem(value: SpeakingPace.slow, child: Text('Slow')),
                        DropdownMenuItem(value: SpeakingPace.normal, child: Text('Normal')),
                        DropdownMenuItem(value: SpeakingPace.fast, child: Text('Fast')),
                      ],
                      onChanged: (v) => setState(() => _pace = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _label('Mic mode'),
          DropdownButtonFormField<MicMode>(
            value: _micMode,
            items: const [
              DropdownMenuItem(value: MicMode.openMic, child: Text('Open mic')),
              DropdownMenuItem(value: MicMode.pushToTalk, child: Text('Push to talk')),
            ],
            onChanged: (v) => setState(() => _micMode = v!),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _start,
            child: const Text('Start talking', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
}
