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
          'Put Chinese in parentheses right after the term — e.g. "perimeter (周长)", "luas (面积)", '
          '"expand (展开)", "simplify (简化)". Do NOT translate non-math words.',
        );
        break;
      case ChineseLevel.termsAndSteps:
        sb.writeln(
          'CHINESE BRIDGE (Terms + Steps): Add Chinese (中文) translations for MATH VOCABULARY AND '
          'INSTRUCTIONAL WORDS. Translate math terms AND action words like "calculate (计算)", '
          '"find (求)", "add (加)", "multiply (乘)". Also translate key nouns like "triangle (三角形)", '
          '"rectangle (长方形)". Put Chinese in parentheses inline.',
        );
        break;
      case ChineseLevel.fullBilingual:
        sb.writeln(
          'CHINESE BRIDGE (Full Bilingual): Write in a HEAVILY bilingual style. Translate most words '
          'and phrases into Chinese inline — math terms, instructions, and connecting words. '
          'Example: "计算 (Calculate) 这个 长方形 (rectangle) 的 周长 (perimeter)：把 (add) 所有的 边 (sides) 加起来". '
          'The student should be able to understand the lesson even if they only read the Chinese.',
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
