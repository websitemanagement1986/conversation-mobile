import '../models/models.dart';

const languages = <LanguageOption>[
  LanguageOption(code: 'es', name: 'Spanish', nativeName: 'Español', speechCode: 'es-ES'),
  LanguageOption(code: 'fr', name: 'French', nativeName: 'Français', speechCode: 'fr-FR'),
  LanguageOption(code: 'de', name: 'German', nativeName: 'Deutsch', speechCode: 'de-DE'),
  LanguageOption(code: 'it', name: 'Italian', nativeName: 'Italiano', speechCode: 'it-IT'),
  LanguageOption(code: 'pt', name: 'Portuguese', nativeName: 'Português', speechCode: 'pt-PT'),
  LanguageOption(code: 'ja', name: 'Japanese', nativeName: '日本語', speechCode: 'ja-JP'),
  LanguageOption(code: 'ko', name: 'Korean', nativeName: '한국어', speechCode: 'ko-KR'),
  LanguageOption(code: 'zh', name: 'Chinese', nativeName: '中文', speechCode: 'zh-CN'),
  LanguageOption(code: 'ar', name: 'Arabic', nativeName: 'العربية', speechCode: 'ar-AR'),
  LanguageOption(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', speechCode: 'hi-IN'),
  LanguageOption(code: 'ru', name: 'Russian', nativeName: 'Русский', speechCode: 'ru-RU'),
  LanguageOption(code: 'nl', name: 'Dutch', nativeName: 'Nederlands', speechCode: 'nl-NL'),
  LanguageOption(code: 'en', name: 'English', nativeName: 'English', speechCode: 'en-US'),
];

const situationPresets = <SituationPreset>[
  SituationPreset(id: 'coffee', title: 'Ordering coffee', description: "You're at a café ordering drinks", icon: '☕'),
  SituationPreset(id: 'restaurant', title: 'At a restaurant', description: 'Making a reservation and ordering a meal', icon: '🍽️'),
  SituationPreset(id: 'directions', title: 'Asking for directions', description: "You're lost and need help", icon: '🗺️'),
  SituationPreset(id: 'shopping', title: 'Shopping', description: 'Buying clothes, asking about prices', icon: '🛍️'),
  SituationPreset(id: 'hotel', title: 'Hotel check-in', description: 'Checking in and asking about amenities', icon: '🏨'),
  SituationPreset(id: 'doctor', title: 'At the doctor', description: 'Describing symptoms', icon: '🏥'),
  SituationPreset(id: 'job-interview', title: 'Job interview', description: 'A formal interview', icon: '💼'),
  SituationPreset(id: 'small-talk', title: 'Small talk', description: 'Casual conversation', icon: '💬'),
  SituationPreset(id: 'travel', title: 'At the airport', description: 'Checking in and boarding', icon: '✈️'),
  SituationPreset(id: 'custom', title: 'Custom situation', description: 'Describe your own scenario', icon: '✏️'),
];

const cefrLevels = CefrLevel.values;

const levelDescriptions = <CefrLevel, String>{
  CefrLevel.a1: 'Beginner — basic phrases, present tense, very slow pace',
  CefrLevel.a2: 'Elementary — simple sentences, everyday topics',
  CefrLevel.b1: 'Intermediate — most travel situations, moderate pace',
  CefrLevel.b2: 'Upper intermediate — abstract topics, normal pace',
  CefrLevel.c1: 'Advanced — nuanced expression and idioms',
  CefrLevel.c2: 'Mastery — near-native fluency',
};

LanguageOption languageByCode(String code) {
  return languages.firstWhere(
    (l) => l.code == code,
    orElse: () => languages.first,
  );
}

String buildInstructions(SessionConfig config) {
  final level = config.level.label;
  final native = config.nativeLanguage.name;
  final target = config.targetLanguage.name;

  final correctionStyle = switch (config.correctionStyle) {
    CorrectionStyle.inline =>
      'When the student makes a mistake, briefly correct inline and note it.',
    CorrectionStyle.endOfTurn =>
      'Wait until the student finishes, then give corrections before continuing.',
    CorrectionStyle.off => 'Do not correct unless the student asks.',
  };

  final pace = switch (config.pace) {
    SpeakingPace.slow => 'Speak slowly with clear pauses.',
    SpeakingPace.normal => 'Speak at a natural conversational pace.',
    SpeakingPace.fast => 'Speak at a brisk, native-like pace.',
  };

  return '''
You are a friendly language tutor helping a student practice $target.

Target language: $target (${config.targetLanguage.nativeName})
Student native language: $native
CEFR level: $level — ${levelDescriptions[config.level]}
Situation: ${config.situation}
Speaking pace: $pace

Stay in character for the situation. Speak primarily in $target.
Only switch to $native when the student is clearly stuck.

Correction style: $correctionStyle

When you notice a mistake, append a line: [CORRECTION: original | corrected | explanation]
When you introduce useful vocabulary, append: [VOCAB: word | meaning | example]

Keep responses concise (1-3 sentences for lower levels, up to 4 for higher).
Greet the student in $target and set the scene, then ask an opening question.

If the student says "say that again slower", repeat more slowly.
If they say "give me a hint", provide a word or phrase they could use.
If they say "what does that mean", explain in $native.
''';
}

String buildPerformanceNote(int corrections, int vocabulary, int minutes) {
  if (corrections == 0 && vocabulary > 0) {
    return 'Great session! You learned $vocabulary new words in $minutes minutes with no major mistakes.';
  }
  if (corrections <= 2) {
    return 'Solid practice — only $corrections correction(s) in $minutes minutes. You picked up $vocabulary new words.';
  }
  if (corrections <= 5) {
    return 'Good effort! $corrections areas to review. Focus on the corrections below.';
  }
  return 'Keep practicing! Review the $corrections corrections and try again tomorrow.';
}
