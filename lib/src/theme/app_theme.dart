import 'package:flutter/material.dart';

/// Identidade visual do Babymodile.
///
/// Paleta oficial: verde menta como cor principal, azul céu como secundária,
/// amarelo e laranja para destaques, lavanda como complementar e fundo creme
/// para dar conforto visual.
class AppTheme {
  // ---- Paleta oficial ----
  /// Verde menta — cor principal da marca.
  static const green = Color(0xFF75D9B0);

  /// Verde escuro — textos, contornos e áreas de alto contraste.
  static const mintDark = Color(0xFF315E55);

  /// Azul céu — elementos secundários.
  static const blue = Color(0xFF72BDEB);

  /// Amarelo — destaques.
  static const yellow = Color(0xFFFFD66E);

  /// Laranja — destaques quentes.
  static const orange = Color(0xFFFFAB79);

  /// Lavanda — elementos complementares.
  static const lavender = Color(0xFFB9A4F4);

  /// Fundo creme do aplicativo.
  static const cream = Color(0xFFFFF9E9);

  /// Texto secundário.
  static const textSecondary = Color(0xFF789087);

  /// Vermelho amigável para encerrar ligação e excluir itens.
  static const danger = Color(0xFFE96A6A);

  // ---- Variações suaves (teclado, cards e fundos) ----
  static const greenSoft = Color(0xFFDCF5EA);
  static const blueSoft = Color(0xFFD9EEFB);
  static const yellowSoft = Color(0xFFFFF0C9);
  static const lavenderSoft = Color(0xFFE7E0FD);
  static const orangeSoft = Color(0xFFFFE3D3);

  // ---- Papéis de uso ----
  static const background = cream;
  static const shell = Colors.white;
  static const ink = mintDark;

  /// Sombra padrão dos cards.
  static const cardShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 5)),
  ];

  static ThemeData buildTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: green,
        brightness: Brightness.light,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w800, color: ink),
        titleLarge: TextStyle(fontWeight: FontWeight.w800, color: ink),
        bodyMedium: TextStyle(color: ink),
      ),
    );
  }
}
