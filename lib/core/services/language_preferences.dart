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

    final bool isBM = baseLanguage == BaseLanguage.bm;

    switch (chineseLevel) {
      case ChineseLevel.mathTerms:
        sb.writeln(
          'CHINESE BRIDGE (Math Terms Only): You MUST add Chinese (中文) translations in parentheses '
          'for every KEY MATH TERM. '
          '${isBM ? 'Examples: "sebutan serupa (同类项)", "kembangkan (展开)", "permudahkan (简化)", '
                    '"luas (面积)", "perimeter (周长)", "kuasa dua (平方)", "punca kuasa dua (平方根)".' : 'Examples: "like terms (同类项)", "expand (展开)", "simplify (简化)", '
                    '"area (面积)", "perimeter (周长)", "square (平方)", "square root (平方根)".'}'
          ' Do NOT translate casual words.',
        );
        break;
      case ChineseLevel.termsAndSteps:
        sb.writeln(
          'CHINESE BRIDGE (Terms + Steps): You MUST add Chinese (中文) translations in parentheses '
          'for ALL of the following: '
          '${isBM ? '1. Math terms — "sebutan serupa (同类项)", "pekali (系数)", "kembangkan (展开)". '
                    '2. Conceptual phrases — "sebutan berbeza (项不同)", "tidak boleh digabungkan (不能合并)". '
                    '3. Math verbs — "kira (计算)", "darab (乘)", "tambah (加)", "cari (求)". ' : '1. Math terms — "like terms (同类项)", "coefficient (系数)", "expand (展开)". '
                    '2. Conceptual phrases — "terms are different (项不同)", "cannot be combined (不能合并)". '
                    '3. Math verbs — "calculate (计算)", "multiply (乘)", "add (加)", "find (求)". '}'
          'Do NOT translate casual words. Every sentence MUST have at least one Chinese translation.',
        );
        break;
      case ChineseLevel.fullBilingual:
        sb.writeln(
          'CHINESE BRIDGE (Full Bilingual): You MUST add Chinese (中文) translations for ALMOST EVERY '
          'meaningful word. Translate aggressively — math terms, concepts, verbs, nouns, and descriptions. '
          '${isBM ? 'Examples: "sebutan (项)", "kuasa dua sempurna (完全平方)", "tanda tolak (减号)", '
                    '"kembangkan (展开)", "permudahkan (简化)", "darab (乘)", "tambah (加)", '
                    '"tidak boleh (不能)", "kena guna (必须用)", "tukarkan (转换)", "cara betul (正确方法)". ' : 'Examples: "terms (项)", "perfect square (完全平方)", "minus sign (减号)", '
                    '"expand (展开)", "simplify (简化)", "multiply (乘)", "add (加)", '
                    '"cannot (不能)", "must use (必须用)", "convert (转换)", "correct method (正确方法)". '}'
          'ONLY skip: "hey bro", "eh", pronouns, and simple connectors like "and/dan", "but/tapi". '
          'Target: at least 3-5 Chinese translations per sentence.',
        );
        break;
      case ChineseLevel.off:
        break;
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
