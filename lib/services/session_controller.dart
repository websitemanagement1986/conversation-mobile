import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import '../models/models.dart';
import 'gemini_service.dart';
import 'speech_service.dart';

enum SessionStatus { idle, connecting, connected, listening, speaking, error, ended }

class SessionController {
  SessionController({
    required this.apiKey,
    required this.config,
  });

  final String apiKey;
  final SessionConfig config;
  final _uuid = const Uuid();

  final SpeechService speech = SpeechService();
  late final GeminiService _gemini = GeminiService(apiKey);
  final SpeechToText _stt = SpeechToText();

  final _statusController = StreamController<SessionStatus>.broadcast();
  final _transcriptController = StreamController<TranscriptLine>.broadcast();
  final _correctionController = StreamController<Correction>.broadcast();
  final _vocabController = StreamController<VocabEntry>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<SessionStatus> get statusStream => _statusController.stream;
  Stream<TranscriptLine> get transcriptStream => _transcriptController.stream;
  Stream<Correction> get correctionStream => _correctionController.stream;
  Stream<VocabEntry> get vocabStream => _vocabController.stream;
  Stream<String> get errorStream => _errorController.stream;

  final List<TranscriptLine> transcript = [];
  final List<Correction> corrections = [];
  final List<VocabEntry> vocabulary = [];
  final List<Content> _history = [];

  SessionStatus status = SessionStatus.idle;
  bool _listening = false;
  bool _disposed = false;
  DateTime? startedAt;

  Future<bool> start() async {
    _setStatus(SessionStatus.connecting);
    startedAt = DateTime.now();

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      _emitError('Microphone permission is required.');
      _setStatus(SessionStatus.error);
      return false;
    }

    await speech.init();

    final available = await _stt.initialize(
      onError: (e) => _emitError(e.errorMsg),
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          if (_listening && config.micMode == MicMode.openMic) {
            _restartListening();
          }
        }
      },
    );

    if (!available) {
      _emitError('Speech recognition is not available on this device.');
      _setStatus(SessionStatus.error);
      return false;
    }

    try {
      final opening = await _gemini.startConversation(config);
      _history.add(Content.model([TextPart(opening.text)]));
      _addAssistantMessage(opening.text, opening);
      await speech.speak(
        opening.text,
        config.targetLanguage,
        config.pace,
      );
      _setStatus(SessionStatus.connected);

      if (config.micMode == MicMode.openMic) {
        await setListening(true);
      }
      return true;
    } catch (e) {
      _emitError('Failed to connect: $e');
      _setStatus(SessionStatus.error);
      return false;
    }
  }

  Future<void> setListening(bool enabled) async {
    _listening = enabled;
    if (enabled) {
      await _startListening();
    } else {
      await _stt.stop();
      _setStatus(SessionStatus.connected);
    }
  }

  Future<void> _startListening() async {
    if (_disposed || speech.isSpeaking) return;
    _setStatus(SessionStatus.listening);
    await _stt.listen(
      localeId: config.targetLanguage.speechCode,
      listenMode: ListenMode.confirmation,
      onResult: (result) async {
        if (!result.finalResult) return;
        final text = result.recognizedWords.trim();
        if (text.isEmpty) return;
        await _handleUserMessage(text);
      },
    );
  }

  Future<void> _restartListening() async {
    if (_disposed || !_listening || speech.isSpeaking) return;
    await Future.delayed(const Duration(milliseconds: 300));
    if (_listening && !_disposed) {
      await _startListening();
    }
  }

  Future<void> _handleUserMessage(String text) async {
    await _stt.stop();
    _setStatus(SessionStatus.connecting);

    _history.add(Content.text(text));
    _transcript.add(TranscriptLine(
      id: _uuid.v4(),
      role: 'user',
      text: text,
      timestamp: DateTime.now(),
    ));
    _transcriptController.add(_transcript.last);

    try {
      final response = await _gemini.chat(
        config: config,
        history: _history.sublist(0, _history.length - 1),
        userMessage: text,
      );
      _history.add(Content.model([TextPart(response.text)]));
      _addAssistantMessage(response.text, response);
      _setStatus(SessionStatus.speaking);
      await speech.speak(
        response.text,
        config.targetLanguage,
        config.pace,
      );
      _setStatus(SessionStatus.connected);
      if (_listening) {
        await _restartListening();
      }
    } catch (e) {
      _emitError('Failed to get response: $e');
      _setStatus(SessionStatus.error);
      if (_listening) await _restartListening();
    }
  }

  void _addAssistantMessage(String text, ParsedResponse parsed) {
    _transcript.add(TranscriptLine(
      id: _uuid.v4(),
      role: 'assistant',
      text: text,
      timestamp: DateTime.now(),
    ));
    _transcriptController.add(_transcript.last);

    for (final c in parsed.corrections) {
      corrections.add(c);
      _correctionController.add(c);
    }
    for (final v in parsed.vocabulary) {
      vocabulary.add(v);
      _vocabController.add(v);
    }
  }

  Future<void> sendHelper(String text) async {
    await _handleUserMessage(text);
  }

  SessionRecap buildRecap() {
    final end = DateTime.now();
    final start = startedAt ?? end;
    final minutes = (end.difference(start).inMinutes).clamp(1, 9999);
    return SessionRecap(
      id: _uuid.v4(),
      config: config,
      startedAt: start,
      endedAt: end,
      corrections: List.from(corrections),
      vocabulary: List.from(vocabulary),
      transcript: List.from(transcript),
      performanceNote: buildPerformanceNote(
        corrections.length,
        vocabulary.length,
        minutes,
      ),
    );
  }

  Future<void> dispose() async {
    _disposed = true;
    _listening = false;
    await _stt.stop();
    await speech.stop();
    speech.dispose();
    await _statusController.close();
    await _transcriptController.close();
    await _correctionController.close();
    await _vocabController.close();
    await _errorController.close();
    _setStatus(SessionStatus.ended);
  }

  void _setStatus(SessionStatus s) {
    status = s;
    if (!_statusController.isClosed) {
      _statusController.add(s);
    }
  }

  void _emitError(String msg) {
    if (!_errorController.isClosed) {
      _errorController.add(msg);
    }
  }
}
