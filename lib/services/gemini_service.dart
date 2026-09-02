import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/app_config.dart';
import '../models/models.dart';

class ParsedResponse {
  ParsedResponse({
    required this.text,
    required this.corrections,
    required this.vocabulary,
  });

  final String text;
  final List<Correction> corrections;
  final List<VocabEntry> vocabulary;
}

class GeminiService {
  GeminiService(this.apiKey);

  final String apiKey;
  GenerativeModel? _model;
  ChatSession? _chat;

  static final _generationConfig = GenerationConfig(
    maxOutputTokens: 280,
    temperature: 0.8,
  );

  void beginSession(SessionConfig config) {
    _model = GenerativeModel(
      model: geminiModelName,
      apiKey: apiKey,
      systemInstruction: Content.system(buildInstructions(config)),
      generationConfig: _generationConfig,
    );
    _chat = _model!.startChat();
  }

  Future<ParsedResponse> startConversation(SessionConfig config) async {
    beginSession(config);
    final response = await _chat!.sendMessage(
      Content.text(
        'Start now. Greet the student in ${config.targetLanguage.name} and set the scene in 1-2 short sentences.',
      ),
    );
    return parseResponse(response.text ?? '');
  }

  Future<ParsedResponse> chat(String userMessage) async {
    final response = await _chat!.sendMessage(Content.text(userMessage));
    return parseResponse(response.text ?? '');
  }

  Stream<String> chatStream(String userMessage) async* {
    final stream = _chat!.sendMessageStream(Content.text(userMessage));
    await for (final chunk in stream) {
      final text = chunk.text;
      if (text != null && text.isNotEmpty) {
        yield text;
      }
    }
  }

  ParsedResponse parseResponse(String raw) {
    final corrections = <Correction>[];
    final vocabulary = <VocabEntry>[];
    var text = raw;

    final correctionRegex = RegExp(
      r'\[CORRECTION:\s*([^|]+)\s*\|\s*([^|]+)\s*\|\s*([^\]]+)\]',
      caseSensitive: false,
    );
    for (final match in correctionRegex.allMatches(raw)) {
      corrections.add(Correction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        original: match.group(1)!.trim(),
        corrected: match.group(2)!.trim(),
        explanation: match.group(3)!.trim(),
      ));
    }
    text = text.replaceAll(correctionRegex, '').trim();

    final vocabRegex = RegExp(
      r'\[VOCAB:\s*([^|]+)\s*\|\s*([^|]+)\s*\|\s*([^\]]+)\]',
      caseSensitive: false,
    );
    for (final match in vocabRegex.allMatches(raw)) {
      vocabulary.add(VocabEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        word: match.group(1)!.trim(),
        meaning: match.group(2)!.trim(),
        example: match.group(3)!.trim(),
      ));
    }
    text = text.replaceAll(vocabRegex, '').trim();

    return ParsedResponse(
      text: text,
      corrections: corrections,
      vocabulary: vocabulary,
    );
  }
}
