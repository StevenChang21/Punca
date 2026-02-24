import 'package:shared_preferences/shared_preferences.dart';

/// Base language for lessons: BM (Malay) or DLP (English).
enum BaseLanguage { bm, dlp }

/// How much Chinese (中文) translation to weave inline.
enum ChineseLevel {
  off, // No Chinese
  mathTerms, // 数学词 — only math vocabulary
  termsAndSteps, // 词+步骤 — math terms + instructional words
  fullBilingual, // 全双语 — nearly everything translated
}

/// Manages language preferences stored locally via SharedPreferences.
class LanguagePreferences {
  static const _keyBaseLanguage = 'base_language';
  static const _keyChineseLevel = 'chinese_level';

  static SharedPreferences? _prefs;

  /// Must be called once at app startup (e.g. in main()).
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Getters ──────────────────────────────────────────────

  static BaseLanguage get baseLanguage {
    final value = _prefs?.getString(_keyBaseLanguage);
    return value == 'dlp' ? BaseLanguage.dlp : BaseLanguage.bm;
  }

  static ChineseLevel get chineseLevel {
    final value = _prefs?.getString(_keyChineseLevel);
    switch (value) {
      case 'mathTerms':
        return ChineseLevel.mathTerms;
      case 'termsAndSteps':
        return ChineseLevel.termsAndSteps;
      case 'fullBilingual':
        return ChineseLevel.fullBilingual;
      default:
        return ChineseLevel.off;
    }
  }

  // ── Setters ──────────────────────────────────────────────

  static Future<void> setBaseLanguage(BaseLanguage lang) async {
    await _prefs?.setString(_keyBaseLanguage, lang.name);
  }

  static Future<void> setChineseLevel(ChineseLevel level) async {
    await _prefs?.setString(_keyChineseLevel, level.name);
  }

  // ── Prompt helper ────────────────────────────────────────

  /// Returns a language instruction string to inject into Gemini prompts.
  static String get promptInstruction {
    final StringBuffer sb = StringBuffer();

    if (baseLanguage == BaseLanguage.bm) {
      sb.writeln(
        'LANGUAGE: Write ALL explanations, questions, and options in **Bahasa Melayu**. '
        'Use KSSM Malay math terminology (e.g. "perimeter", "luas", "segi tiga").',
      );
    } else {
      sb.writeln(
        'LANGUAGE: Write ALL explanations, questions, and options in **English**. '
        'Use KSSM English math terminology.',
      );
    }

    switch (chineseLevel) {
      case ChineseLevel.mathTerms:
        sb.writeln(
          'CHINESE BRIDGE (Math Terms Only): Add Chinese (中文) translations ONLY for KEY MATH VOCABULARY. '
          'Put Chinese in parentheses right after the term — e.g. "perimeter (周长)", "area (面积)", '
          '"expand (展开)", "simplify (简化)", "like terms (同类项)", "unlike terms (不同类项)". '
          'Do NOT translate casual phrases, verbs, or filler words.',
        );
        break;
      case ChineseLevel.termsAndSteps:
        sb.writeln(
          'CHINESE BRIDGE (Terms + Steps): Add Chinese (中文) translations for MATH VOCABULARY and '
          'KEY CONCEPTUAL PHRASES that help understanding. '
          'PRIORITY 1 — Math terms: "like terms (同类项)", "coefficient (系数)", "expand (展开)". '
          'PRIORITY 2 — Conceptual phrases: "terms are different (项不同)", "cannot be combined (不能合并)". '
          'PRIORITY 3 — Math action verbs: "calculate (计算)", "multiply (乘)", "add (加)". '
          'Do NOT translate filler words like "you", "think of", "it is like", "hey bro".',
        );
        break;
      case ChineseLevel.fullBilingual:
        sb.writeln(
          'CHINESE BRIDGE (Full Bilingual): Translate GENEROUSLY but SMARTLY. '
          'ALWAYS translate: math terms, conceptual phrases, instructional verbs, and key nouns. '
          'Examples: "like terms (同类项)", "cannot be combined (不能合并)", "different (不同)", '
          '"multiply each term (每一项都要乘)". '
          'NEVER translate: casual filler ("hey bro", "think of it like"), pronouns ("you", "we"), '
          'articles, or common connectors ("and", "but", "so"). '
          'The goal: a student who knows Chinese math vocabulary but struggles with English should '
          'understand the lesson by reading the Chinese translations alone.',
        );
        break;
      case ChineseLevel.off:
        break; // No Chinese instruction
    }

    return sb.toString();
  }

  // ── Display labels ───────────────────────────────────────

  static String chineseLevelLabel(ChineseLevel level) {
    switch (level) {
      case ChineseLevel.off:
        return 'OFF';
      case ChineseLevel.mathTerms:
        return '数学词';
      case ChineseLevel.termsAndSteps:
        return '词+步骤';
      case ChineseLevel.fullBilingual:
        return '全双语';
    }
  }
}
