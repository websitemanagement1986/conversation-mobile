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
  static const _modelName = 'gemini-2.0-flash';

  GenerativeModel _model(SessionConfig config) {
    return GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      systemInstruction: Content.system(buildInstructions(config)),
    );
  }

  Future<ParsedResponse> chat({
    required SessionConfig config,
    required List<Content> history,
    required String userMessage,
  }) async {
    final model = _model(config);
    final chat = model.startChat(history: history);
    final response = await chat.sendMessage(Content.text(userMessage));
    final raw = response.text ?? '';
    return _parseResponse(raw);
  }

  Future<ParsedResponse> startConversation(SessionConfig config) async {
    final model = _model(config);
    final response = await model.generateContent([
      Content.text(
        '[System: Start the conversation. Greet the student in ${config.targetLanguage.name} and set the scene.]',
      ),
    ]);
    final raw = response.text ?? '';
    return _parseResponse(raw);
  }

  ParsedResponse _parseResponse(String raw) {
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
