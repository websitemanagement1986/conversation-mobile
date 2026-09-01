import 'package:flutter_tts/flutter_tts.dart';
import '../models/models.dart';

class SpeechService {
  SpeechService();

  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> init() async {
    await _tts.setSharedInstance(true);
    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setCancelHandler(() => _isSpeaking = false);
    _tts.setErrorHandler((_) => _isSpeaking = false);
  }

  Future<void> speak(String text, LanguageOption language, SpeakingPace pace) async {
    await _tts.stop();
    await _tts.setLanguage(language.speechCode);
    final rate = switch (pace) {
      SpeakingPace.slow => 0.45,
      SpeakingPace.normal => 0.5,
      SpeakingPace.fast => 0.6,
    };
    await _tts.setSpeechRate(rate);
    _isSpeaking = true;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  void dispose() {
    _tts.stop();
  }
}
