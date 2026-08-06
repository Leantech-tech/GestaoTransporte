import 'package:flutter/services.dart';

class AppInputFormatters {
  static TextInputFormatter cnpj() => _CnpjFormatter();

  static TextInputFormatter telefone() => _TelefoneFormatter();

  static TextInputFormatter cpf() => _CpfFormatter();

  static TextInputFormatter cep() => _CepFormatter();

  static TextInputFormatter moeda() => _MoedaFormatter();

  static TextInputFormatter placa() => _PlacaFormatter();

  static String formatCep(String value) {
    return _CepFormatter().formatEditUpdate(
      const TextEditingValue(),
      TextEditingValue(text: value),
    ).text;
  }

  static String cepRaw(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  static String placaRaw(String value) => value.replaceAll(RegExp(r'[^A-Z0-9]'), '').toUpperCase();

  static bool placaValida(String value) {
    final placa = placaRaw(value);
    return RegExp(r'^[A-Z]{3}[0-9]{4}$').hasMatch(placa) ||
        RegExp(r'^[A-Z]{3}[0-9][A-Z][0-9]{2}$').hasMatch(placa);
  }

  static String formatTelefone(String value) {
    return _TelefoneFormatter().formatEditUpdate(
      const TextEditingValue(),
      TextEditingValue(text: value),
    ).text;
  }

  static String formatCpf(String value) {
    return _CpfFormatter().formatEditUpdate(
      const TextEditingValue(),
      TextEditingValue(text: value),
    ).text;
  }

  static String formatCnpj(String value) {
    return _CnpjFormatter().formatEditUpdate(
      const TextEditingValue(),
      TextEditingValue(text: value),
    ).text;
  }

  static String cnpjRaw(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  static String telefoneRaw(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  static String cpfRaw(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  static String moedaRaw(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static double moedaDouble(String value) {
    final raw = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) return 0.0;
    return double.parse(raw) / 100;
  }

  static String moedaText(double value) {
    final centavos = (value * 100).round();
    final reais = centavos ~/ 100;
    final c = centavos % 100;
    final reaisFormatted = reais.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return 'R\$ $reaisFormatted,${c.toString().padLeft(2, '0')}';
  }
}

class _CnpjFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 14) digits = digits.substring(0, 14);

    String formatted = '';
    if (digits.isNotEmpty) formatted = digits.substring(0, digits.length < 2 ? digits.length : 2);
    if (digits.length >= 3) formatted += '.${digits.substring(2, digits.length < 5 ? digits.length : 5)}';
    if (digits.length >= 6) formatted += '.${digits.substring(5, digits.length < 8 ? digits.length : 8)}';
    if (digits.length >= 9) formatted += '/${digits.substring(8, digits.length < 12 ? digits.length : 12)}';
    if (digits.length >= 13) formatted += '-${digits.substring(12, digits.length)}';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _TelefoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 11) digits = digits.substring(0, 11);

    String formatted = '';
    if (digits.length >= 2) {
      formatted = '(${digits.substring(0, 2)})';
      final rest = digits.substring(2);
      if (rest.isNotEmpty) {
        if (digits.length <= 10) {
          // (XX) XXXX-XXXX
          if (rest.length <= 4) {
            formatted += ' $rest';
          } else {
            formatted += ' ${rest.substring(0, 4)}-${rest.substring(4)}';
          }
        } else {
          // (XX) XXXXX-XXXX
          formatted += ' ${rest.substring(0, 5)}-${rest.substring(5)}';
        }
      }
    } else {
      formatted = digits;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _CpfFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 11) digits = digits.substring(0, 11);

    String formatted = '';
    if (digits.length >= 4) {
      formatted = '${digits.substring(0, 3)}.';
      if (digits.length > 3) formatted += digits.substring(3, digits.length < 6 ? digits.length : 6);
      if (digits.length >= 6) formatted += '.${digits.substring(6, digits.length < 9 ? digits.length : 9)}';
      if (digits.length >= 9) formatted += '-${digits.substring(9)}';
    } else {
      formatted = digits;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _PlacaFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var placa = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (placa.length > 7) placa = placa.substring(0, 7);

    String formatted = placa;
    if (placa.length > 3 && RegExp(r'^[A-Z]{3}[0-9]+$').hasMatch(placa)) {
      formatted = '${placa.substring(0, 3)}-${placa.substring(3)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _MoedaFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: 'R\$ 0,00',
        selection: TextSelection.collapsed(offset: 6),
      );
    }

    if (digits.length > 12) digits = digits.substring(0, 12);

    final value = double.parse(digits) / 100;
    final centavos = (value * 100).round();
    final reais = centavos ~/ 100;
    final c = centavos % 100;
    final reaisFormatted = reais.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    final formatted = 'R\$ $reaisFormatted,${c.toString().padLeft(2, '0')}';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _CepFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 8) digits = digits.substring(0, 8);

    String formatted = digits;
    if (digits.length > 5) {
      formatted = '${digits.substring(0, 5)}-${digits.substring(5)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
