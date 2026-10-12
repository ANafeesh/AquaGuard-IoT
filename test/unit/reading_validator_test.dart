import 'package:flutter_test/flutter_test.dart';
import 'package:aquaguard/core/utils/reading_validator.dart';

void main() {
  group('ReadingValidator - Form Validation', () {
    test('Valid form with at least one parameter succeeds', () {
      final result = ReadingValidator.validateForm(
        sourceId: 'ws-1',
        ph: 7.2,
      );
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('Valid form with all four parameters succeeds', () {
      final result = ReadingValidator.validateForm(
        sourceId: 'ws-1',
        ph: 7.4,
        temperature: 24.5,
        turbidity: 2.1,
        tdsEc: 310.0,
      );
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('Form with NO parameters fails', () {
      final result = ReadingValidator.validateForm(
        sourceId: 'ws-1',
        ph: null,
        temperature: null,
        turbidity: null,
        tdsEc: null,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('At least one water-quality parameter'));
      expect(result.fieldErrors.containsKey('parameters'), isTrue);
    });

    test('pH out of bounds (below 0.0 or above 14.0) fails', () {
      final lowResult = ReadingValidator.validateForm(
        sourceId: 'ws-1',
        ph: -0.5,
      );
      expect(lowResult.isValid, isFalse);
      expect(lowResult.fieldErrors['ph'], contains('between 0.0 and 14.0'));

      final highResult = ReadingValidator.validateForm(
        sourceId: 'ws-1',
        ph: 14.5,
      );
      expect(highResult.isValid, isFalse);
      expect(highResult.fieldErrors['ph'], contains('between 0.0 and 14.0'));
    });

    test('Temperature out of bounds (below -5.0 or above 60.0 °C) fails', () {
      final freezingResult = ReadingValidator.validateForm(
        sourceId: 'ws-1',
        temperature: -8.0,
      );
      expect(freezingResult.isValid, isFalse);
      expect(freezingResult.fieldErrors['temperature'], contains('-5.0°C and 60.0°C'));

      final boilingResult = ReadingValidator.validateForm(
        sourceId: 'ws-1',
        temperature: 65.0,
      );
      expect(boilingResult.isValid, isFalse);
      expect(boilingResult.fieldErrors['temperature'], contains('-5.0°C and 60.0°C'));
    });

    test('Turbidity cannot be negative', () {
      final negativeResult = ReadingValidator.validateForm(
        sourceId: 'ws-1',
        turbidity: -1.2,
      );
      expect(negativeResult.isValid, isFalse);
      expect(negativeResult.fieldErrors['turbidity'], contains('cannot be negative'));

      final zeroResult = ReadingValidator.validateForm(
        sourceId: 'ws-1',
        turbidity: 0.0,
      );
      expect(zeroResult.isValid, isTrue);
    });

    test('TDS/EC cannot be negative', () {
      final negativeResult = ReadingValidator.validateForm(
        sourceId: 'ws-1',
        tdsEc: -5.0,
      );
      expect(negativeResult.isValid, isFalse);
      expect(negativeResult.fieldErrors['tdsEc'], contains('cannot be negative'));

      final zeroResult = ReadingValidator.validateForm(
        sourceId: 'ws-1',
        tdsEc: 0.0,
      );
      expect(zeroResult.isValid, isTrue);
    });

    test('New source requires a valid source name', () {
      final missingName = ReadingValidator.validateForm(
        isNewSource: true,
        newSourceName: '   ',
        ph: 7.0,
      );
      expect(missingName.isValid, isFalse);
      expect(missingName.fieldErrors.containsKey('sourceName'), isTrue);

      final validNewSource = ReadingValidator.validateForm(
        isNewSource: true,
        newSourceName: 'Mountain Spring Basin',
        ph: 7.0,
      );
      expect(validNewSource.isValid, isTrue);
    });
  });

  group('ReadingValidator - Individual Field Validators', () {
    test('validatePhField evaluates correctly', () {
      expect(ReadingValidator.validatePhField(''), isNull);
      expect(ReadingValidator.validatePhField(null), isNull);
      expect(ReadingValidator.validatePhField('7.0'), isNull);
      expect(ReadingValidator.validatePhField('15.0'), isNotNull);
      expect(ReadingValidator.validatePhField('-1.0'), isNotNull);
      expect(ReadingValidator.validatePhField('abc'), isNotNull);
    });

    test('validateTempField evaluates correctly', () {
      expect(ReadingValidator.validateTempField(''), isNull);
      expect(ReadingValidator.validateTempField('25.5'), isNull);
      expect(ReadingValidator.validateTempField('-5.0'), isNull);
      expect(ReadingValidator.validateTempField('60.0'), isNull);
      expect(ReadingValidator.validateTempField('-6.0'), isNotNull);
      expect(ReadingValidator.validateTempField('61.0'), isNotNull);
    });

    test('validateTurbidityField evaluates correctly', () {
      expect(ReadingValidator.validateTurbidityField(''), isNull);
      expect(ReadingValidator.validateTurbidityField('0.0'), isNull);
      expect(ReadingValidator.validateTurbidityField('5.2'), isNull);
      expect(ReadingValidator.validateTurbidityField('-0.1'), isNotNull);
    });

    test('validateTdsField evaluates correctly', () {
      expect(ReadingValidator.validateTdsField(''), isNull);
      expect(ReadingValidator.validateTdsField('0.0'), isNull);
      expect(ReadingValidator.validateTdsField('350'), isNull);
      expect(ReadingValidator.validateTdsField('-1'), isNotNull);
    });
  });
}
