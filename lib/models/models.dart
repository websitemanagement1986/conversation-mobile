enum CefrLevel { a1, a2, b1, b2, c1, c2 }

extension CefrLevelExt on CefrLevel {
  String get label {
    switch (this) {
      case CefrLevel.a1:
        return 'A1';
      case CefrLevel.a2:
        return 'A2';
      case CefrLevel.b1:
        return 'B1';
      case CefrLevel.b2:
        return 'B2';
      case CefrLevel.c1:
        return 'C1';
      case CefrLevel.c2:
        return 'C2';
    }
  }

  static CefrLevel fromLabel(String label) {
    return CefrLevel.values.firstWhere(
      (l) => l.label == label,
      orElse: () => CefrLevel.a1,
    );
  }
}

enum CorrectionStyle { inline, endOfTurn, off }

enum SpeakingPace { slow, normal, fast }

enum MicMode { openMic, pushToTalk }

class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.speechCode,
  });

  final String code;
  final String name;
  final String nativeName;
  final String speechCode;
}

class SituationPreset {
  const SituationPreset({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
}

class SessionConfig {
  const SessionConfig({
    required this.targetLanguage,
    required this.nativeLanguage,
    required this.level,
    required this.situation,
    required this.correctionStyle,
    required this.pace,
    required this.micMode,
  });

  final LanguageOption targetLanguage;
  final LanguageOption nativeLanguage;
  final CefrLevel level;
  final String situation;
  final CorrectionStyle correctionStyle;
  final SpeakingPace pace;
  final MicMode micMode;
}

class Correction {
  Correction({
    required this.id,
    required this.original,
    required this.corrected,
    required this.explanation,
  });

  final String id;
  final String original;
  final String corrected;
  final String explanation;
}

class VocabEntry {
  VocabEntry({
    required this.id,
    required this.word,
    required this.meaning,
    required this.example,
  });

  final String id;
  final String word;
  final String meaning;
  final String example;
}

class TranscriptLine {
  TranscriptLine({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
  });

  final String id;
  final String role;
  final String text;
  final DateTime timestamp;
}

class SessionRecap {
  SessionRecap({
    required this.id,
    required this.config,
    required this.startedAt,
    required this.endedAt,
    required this.corrections,
    required this.vocabulary,
    required this.transcript,
    required this.performanceNote,
  });

  final String id;
  final SessionConfig config;
  final DateTime startedAt;
  final DateTime endedAt;
  final List<Correction> corrections;
  final List<VocabEntry> vocabulary;
  final List<TranscriptLine> transcript;
  final String performanceNote;
}
