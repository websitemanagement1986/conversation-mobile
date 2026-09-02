import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/session_controller.dart';
import '../theme/app_theme.dart';
import 'recap_screen.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    super.key,
    required this.apiKey,
    required this.config,
  });

  final String apiKey;
  final SessionConfig config;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  late final SessionController _session;
  final _scrollController = ScrollController();
  bool _micPressed = false;
  String? _error;
  String _partialUser = '';
  String _partialAssistant = '';

  @override
  void initState() {
    super.initState();
    _session = SessionController(apiKey: widget.apiKey, config: widget.config);
    _session.errorStream.listen((e) => setState(() => _error = e));
    _session.transcriptStream.listen((_) {
      setState(() {});
      _scrollToBottom();
    });
    _session.partialTranscriptStream.listen((text) {
      setState(() => _partialUser = text);
      _scrollToBottom();
    });
    _session.assistantPartialStream.listen((text) {
      setState(() => _partialAssistant = text);
      _scrollToBottom();
    });
    _session.correctionStream.listen((_) => setState(() {}));
    _session.vocabStream.listen((_) => setState(() {}));
    _session.statusStream.listen((_) => setState(() {}));
    _session.start();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _endSession() async {
    final recap = _session.buildRecap();
    await _session.dispose();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => RecapScreen(recap: recap)),
    );
  }

  void _onMicDown() {
    if (widget.config.micMode == MicMode.pushToTalk) {
      setState(() => _micPressed = true);
      _session.setListening(true);
    } else {
      final listening = _session.status == SessionStatus.listening;
      _session.setListening(!listening);
    }
  }

  void _onMicUp() {
    if (widget.config.micMode == MicMode.pushToTalk) {
      setState(() => _micPressed = false);
      _session.setListening(false);
    }
  }

  @override
  void dispose() {
    if (_session.status != SessionStatus.ended) {
      _session.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _session.status;
    final isListening = status == SessionStatus.listening;
    final isSpeaking = status == SessionStatus.speaking;
    final isPushToTalk = widget.config.micMode == MicMode.pushToTalk;
    final micActive = isPushToTalk ? _micPressed : isListening;

    final isThinking = status == SessionStatus.thinking;

    Color orbColor = AppTheme.border;
    if (isSpeaking) {
      orbColor = AppTheme.success;
    } else if (isThinking) {
      orbColor = AppTheme.warning;
    } else if (micActive) {
      orbColor = AppTheme.accent;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.config.targetLanguage.name} · ${widget.config.level.label}'),
        actions: [
          TextButton(
            onPressed: _endSession,
            child: const Text('End', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
              ),
              child: Text(_error!, style: const TextStyle(fontSize: 13)),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _session.transcript.length +
                  (_partialUser.isNotEmpty ? 1 : 0) +
                  (_partialAssistant.isNotEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                final transcriptLen = _session.transcript.length;
                if (index < transcriptLen) {
                  final line = _session.transcript[index];
                  final isUser = line.role == 'user';
                  return _bubble(line.text, isUser: isUser);
                }
                if (_partialUser.isNotEmpty && index == transcriptLen) {
                  return _bubble(_partialUser, isUser: true, isPartial: true);
                }
                return _bubble(
                  _partialAssistant,
                  isUser: false,
                  isPartial: true,
                );
              },
            ),
          ),
          if (_session.corrections.isNotEmpty || _session.vocabulary.isNotEmpty)
            Container(
              height: 120,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView(
                children: [
                  ..._session.corrections.take(3).map((c) => _correctionCard(c)),
                  ..._session.vocabulary.take(3).map((v) => _vocabCard(v)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _helperButton('Slower', () => _session.sendHelper('say that again slower')),
                _helperButton('Hint', () => _session.sendHelper('give me a hint')),
                _helperButton('Meaning?', () => _session.sendHelper('what does that mean')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                Text(
                  _statusLabel(status, micActive, isPushToTalk),
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTapDown: (_) => _onMicDown(),
                  onTapUp: (_) => _onMicUp(),
                  onTapCancel: _onMicUp,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: orbColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: orbColor.withOpacity(0.4),
                          blurRadius: micActive ? 20 : 8,
                          spreadRadius: micActive ? 4 : 0,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.mic, color: Colors.white, size: 40),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(SessionStatus status, bool micActive, bool pushToTalk) {
    return switch (status) {
      SessionStatus.connecting => 'Connecting...',
      SessionStatus.thinking => 'Tutor is thinking...',
      SessionStatus.speaking => 'Tutor is speaking...',
      SessionStatus.listening => 'Listening...',
      SessionStatus.error => 'Error — check connection',
      _ when pushToTalk && micActive => 'Hold to speak',
      _ when pushToTalk => 'Hold mic button to speak',
      _ when micActive => 'Listening...',
      _ => 'Tap mic to start listening',
    };
  }

  Widget _bubble(String text, {required bool isUser, bool isPartial = false}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppTheme.accent.withOpacity(isPartial ? 0.7 : 1)
              : AppTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: isUser
              ? null
              : Border.all(
                  color: isPartial ? AppTheme.warning : AppTheme.border,
                ),
        ),
        child: Text(
          isPartial ? '$text…' : text,
          style: TextStyle(
            fontSize: 15,
            fontStyle: isPartial ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }

  Widget _helperButton(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey,
          side: const BorderSide(color: AppTheme.border),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _correctionCard(Correction c) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
        ),
        child: Text(
          '${c.original} → ${c.corrected}\n${c.explanation}',
          style: const TextStyle(fontSize: 12),
        ),
      );

  Widget _vocabCard(VocabEntry v) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.success.withOpacity(0.3)),
        ),
        child: Text(
          '${v.word} — ${v.meaning}\n${v.example}',
          style: const TextStyle(fontSize: 12),
        ),
      );
}
