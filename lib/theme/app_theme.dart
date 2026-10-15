import 'package:flutter/material.dart';

/// Cores da marca do cliente. O vinho (#900038) é a cor principal do app.
class AppCores {
  static const Color vinho = Color(0xFF900038);
  static const Color vinhoEscuro = Color(0xFF6B0029);

  static const Color fundo = Color(0xFFF7F3F1);
  static const Color borda = Color(0xFFE4D9D6);
  static const Color texto = Color(0xFF2A1D21);
  static const Color textoSuave = Color(0xFF75666B);
}

class AppTheme {
  static ThemeData get tema {
    final esquema = ColorScheme.fromSeed(seedColor: AppCores.vinho).copyWith(
      primary: AppCores.vinho,
      onPrimary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: AppCores.fundo,
      appBarTheme: const AppBarThemeData(
        backgroundColor: AppCores.vinho,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppCores.vinho,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFD9CBCF),
          disabledForegroundColor: const Color(0xFF8A7B7F),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppCores.vinho,
        foregroundColor: Colors.white,
      ),
    );
  }
}
