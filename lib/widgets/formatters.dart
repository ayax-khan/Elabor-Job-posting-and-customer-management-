import 'package:flutter/services.dart';

/// CNIC Input Formatter: xxxxx-xxxxxxx-x
class CnicInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 13) text = text.substring(0, 13);

    String formatted = '';
    if (text.isNotEmpty) {
      if (text.length >= 5) {
        formatted += text.substring(0, 5) + '-';
        if (text.length >= 12) {
          formatted += text.substring(5, 12) + '-';
          formatted += text.substring(12);
        } else if (text.length > 5) {
          formatted += text.substring(5);
        }
      } else {
        formatted += text;
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Phone Number Formatter: 03xx-xxxxxxx
/// - Only allows numbers starting with '03'
/// - Adds '-' automatically after 4 digits
/// - Max digits allowed: 11 (e.g. 03101234567)
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Allow empty field (so user can delete)
    if (text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Only restrict if user has typed at least 2 digits and doesn't start with '03'
    if (text.length >= 2 && !text.startsWith('03')) {
      return oldValue;
    }

    // Limit to 11 digits (0310xxxxxxx)
    if (text.length > 11) {
      text = text.substring(0, 11);
    }

    String formatted = '';
    if (text.length <= 4) {
      formatted = text;
    } else {
      formatted = '${text.substring(0, 4)}-${text.substring(4)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Regex patterns for validation (can be used for form validation)
const String cnicPattern = r'^\d{5}-\d{7}-\d$';
const String phonePattern = r'^03\d{2}-\d{7}$';
