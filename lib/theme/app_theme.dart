import 'package:flutter/material.dart';

/// Cores da marca do cliente. O vinho (#900038) é a cor principal do app.
class AppCores {
  static const Color vinho = Color(0xFF900038);
  static const Color vinhoEscuro = Color(0xFF6B0029);

  static const Color fundo = Color(0xFFF7F3F1);
  static const Color superficie = Colors.white;
  static const Color borda = Color(0xFFE4D9D6);
  static const Color texto = Color(0xFF2A1D21);
  static const Color textoSuave = Color(0xFF75666B);
  static const Color erro = Color(0xFFB3261E);

  // Cores de status (acerto, nota média, erro), em tons que combinam com o
  // vinho e continuam legíveis sobre o fundo claro.
  static const Color sucesso = Color(0xFF2E7D32);
  static const Color alerta = Color(0xFFB26A00);
}

class AppTheme {
  // Mesmo arredondamento em cards, campos, botões e diálogos.
  static const double _raio = 8;

  static ThemeData get tema {
    final esquema = ColorScheme.fromSeed(seedColor: AppCores.vinho).copyWith(
      primary: AppCores.vinho,
      onPrimary: Colors.white,
      surface: AppCores.superficie,
      onSurface: AppCores.texto,
      onSurfaceVariant: AppCores.textoSuave,
      outline: AppCores.borda,
      outlineVariant: AppCores.borda,
      error: AppCores.erro,
      // Sem isso, cards e diálogos ganham um tom rosado da cor principal.
      surfaceTint: Colors.transparent,
    );

    final bordaCampo = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_raio),
      borderSide: const BorderSide(color: AppCores.borda),
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
      cardTheme: CardThemeData(
        color: AppCores.superficie,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_raio),
          side: const BorderSide(color: AppCores.borda),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppCores.vinho,
        titleTextStyle: TextStyle(
          color: AppCores.texto,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(
          color: AppCores.textoSuave,
          fontSize: 13,
          height: 1.4,
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppCores.superficie,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: const TextStyle(color: AppCores.textoSuave),
        floatingLabelStyle: const TextStyle(color: AppCores.vinho),
        prefixIconColor: AppCores.textoSuave,
        suffixIconColor: AppCores.textoSuave,
        border: bordaCampo,
        enabledBorder: bordaCampo,
        focusedBorder: bordaCampo.copyWith(
          borderSide: const BorderSide(color: AppCores.vinho, width: 1.6),
        ),
        errorBorder: bordaCampo.copyWith(
          borderSide: const BorderSide(color: AppCores.erro),
        ),
        focusedErrorBorder: bordaCampo.copyWith(
          borderSide: const BorderSide(color: AppCores.erro, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppCores.vinho,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFD9CBCF),
          disabledForegroundColor: const Color(0xFF8A7B7F),
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_raio),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppCores.vinho,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: AppCores.vinho),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_raio),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppCores.vinho,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppCores.vinho,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_raio * 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppCores.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_raio * 1.5),
        ),
        titleTextStyle: const TextStyle(
          color: AppCores.texto,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppCores.texto,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_raio),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppCores.borda,
        thickness: 1,
        space: 1,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: AppCores.textoSuave, width: 1.5),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppCores.vinho,
      ),
    );
  }
}
