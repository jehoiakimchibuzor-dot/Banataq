import 'dart:ui';

enum AccentTheme { royalBlue, champagneGold, lightGreen, premiumGrey, rose, teal, purple }
enum AccentIntensity { soft, balanced, vibrant }

class AccentTokens {
  final Color primary, secondary, bright, soft, glow, gradientStart, gradientEnd;
  final Color darkBg, darkSurface, darkCard;
  final Color lightBg, lightSurface, lightCard;
  const AccentTokens({
    required this.primary, required this.secondary, required this.bright, required this.soft, required this.glow, required this.gradientStart, required this.gradientEnd,
    required this.darkBg, required this.darkSurface, required this.darkCard,
    required this.lightBg, required this.lightSurface, required this.lightCard,
  });
}

const Map<AccentTheme, AccentTokens> kAccentTokens = {
  AccentTheme.royalBlue: AccentTokens(
    primary: Color(0xFFD4AF5A), secondary: Color(0xFFE2C477), bright: Color(0xFFF4D98B), soft: Color(0xFFA9C1FF), glow: Color(0xFFD4AF5A),
    gradientStart: Color(0xFFC89B3C), gradientEnd: Color(0xFFE2C477),
    darkBg: Color(0xFF060B14), darkSurface: Color(0xFF070B14), darkCard: Color(0xFF070B14),
    lightBg: Color(0xFFF8FAFC), lightSurface: Color(0xFFFFFFFF), lightCard: Color(0xFFFFFFFF),
  ),
  AccentTheme.champagneGold: AccentTokens(
    primary: Color(0xFFD4AF5A), secondary: Color(0xFFE2C477), bright: Color(0xFFF4D98B), soft: Color(0xFFF8E9B8), glow: Color(0xFFD4AF5A),
    gradientStart: Color(0xFFC89B3C), gradientEnd: Color(0xFFF4D98B),
    darkBg: Color(0xFF0A0A09), darkSurface: Color(0xFF151411), darkCard: Color(0xFF1C1A15),
    lightBg: Color(0xFFFFFBEB), lightSurface: Color(0xFFFFFFFF), lightCard: Color(0xFFFFFFFF),
  ),
  AccentTheme.lightGreen: AccentTokens(
    primary: Color(0xFF35B879), secondary: Color(0xFF55D698), bright: Color(0xFF7AE6B2), soft: Color(0xFFB8F3D1), glow: Color(0xFF35B879),
    gradientStart: Color(0xFF35B879), gradientEnd: Color(0xFF7AE6B2),
    darkBg: Color(0xFF06110C), darkSurface: Color(0xFF0C1B14), darkCard: Color(0xFF10251B),
    lightBg: Color(0xFFF0FDF4), lightSurface: Color(0xFFFFFFFF), lightCard: Color(0xFFFFFFFF),
  ),
  AccentTheme.premiumGrey: AccentTokens(
    primary: Color(0xFF64748B), secondary: Color(0xFF94A3B8), bright: Color(0xFFCBD5E1), soft: Color(0xFFE2E8F0), glow: Color(0xFF64748B),
    gradientStart: Color(0xFF475569), gradientEnd: Color(0xFFCBD5E1),
    darkBg: Color(0xFF0A0A0B), darkSurface: Color(0xFF141518), darkCard: Color(0xFF1C1E22),
    lightBg: Color(0xFFF8FAFC), lightSurface: Color(0xFFFFFFFF), lightCard: Color(0xFFFFFFFF),
  ),
  AccentTheme.rose: AccentTokens(
    primary: Color(0xFFE05A83), secondary: Color(0xFFF0789C), bright: Color(0xFFFF9FBA), soft: Color(0xFFFFD0DC), glow: Color(0xFFE05A83),
    gradientStart: Color(0xFFD94670), gradientEnd: Color(0xFFFF8EAB),
    darkBg: Color(0xFF0F070A), darkSurface: Color(0xFF1A0F14), darkCard: Color(0xFF25151D),
    lightBg: Color(0xFFFFF1F5), lightSurface: Color(0xFFFFFFFF), lightCard: Color(0xFFFFFFFF),
  ),
  AccentTheme.teal: AccentTokens(
    primary: Color(0xFF0EA5A4), secondary: Color(0xFF2DD4BF), bright: Color(0xFF5EEAD4), soft: Color(0xFF99F6E4), glow: Color(0xFF0EA5A4),
    gradientStart: Color(0xFF0F8F8D), gradientEnd: Color(0xFF2DD4BF),
    darkBg: Color(0xFF061111), darkSurface: Color(0xFF0B1C1C), darkCard: Color(0xFF102626),
    lightBg: Color(0xFFF0FDFA), lightSurface: Color(0xFFFFFFFF), lightCard: Color(0xFFFFFFFF),
  ),
  AccentTheme.purple: AccentTokens(
    primary: Color(0xFF8B5CF6), secondary: Color(0xFFA78BFA), bright: Color(0xFFC4B5FD), soft: Color(0xFFDDD6FE), glow: Color(0xFF8B5CF6),
    gradientStart: Color(0xFF7C3AED), gradientEnd: Color(0xFFA78BFA),
    darkBg: Color(0xFF0A0614), darkSurface: Color(0xFF120D28), darkCard: Color(0xFF1A1433),
    lightBg: Color(0xFFFAF5FF), lightSurface: Color(0xFFFFFFFF), lightCard: Color(0xFFFFFFFF),
  ),
};

extension AccentThemeLabel on AccentTheme {
  String get label => switch(this){
    AccentTheme.royalBlue => 'Royal Blue',
    AccentTheme.champagneGold => 'Champagne Gold',
    AccentTheme.lightGreen => 'Light Green',
    AccentTheme.premiumGrey => 'Premium Grey',
    AccentTheme.rose => 'Rose',
    AccentTheme.teal => 'Teal',
    AccentTheme.purple => 'Purple',
  };
  String get emoji => switch(this){
    AccentTheme.royalBlue => '🔵', AccentTheme.champagneGold => '🟡', AccentTheme.lightGreen => '🟢',
    AccentTheme.premiumGrey => '⚪', AccentTheme.rose => '🌹', AccentTheme.teal => '🩵', AccentTheme.purple => '🟣',
  };
}
