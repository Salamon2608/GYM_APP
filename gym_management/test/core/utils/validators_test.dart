import 'package:flutter_test/flutter_test.dart';
import 'package:gym_management/core/utils/validators.dart';

void main() {
  group('Validators - Numeric', () {
    test('validatePositiveInteger returns error for empty value', () {
      expect(Validators.validatePositiveInteger('', 'Calories'), 'Calories is required');
      expect(Validators.validatePositiveInteger(null, 'Calories'), 'Calories is required');
    });

    test('validatePositiveInteger returns error for invalid number', () {
      expect(Validators.validatePositiveInteger('abc', 'Calories'), 'Enter a valid number for Calories');
    });

    test('validatePositiveInteger returns error for non-positive number', () {
      expect(Validators.validatePositiveInteger('0', 'Calories'), 'Calories must be greater than zero');
      expect(Validators.validatePositiveInteger('-5', 'Calories'), 'Calories must be greater than zero');
    });

    test('validatePositiveInteger returns null for valid positive integer', () {
      expect(Validators.validatePositiveInteger('100', 'Calories'), null);
    });

    test('validatePositiveDouble returns error for empty value', () {
      expect(Validators.validatePositiveDouble('', 'Weight'), 'Weight is required');
    });

    test('validatePositiveDouble returns error for invalid number', () {
      expect(Validators.validatePositiveDouble('1.2.3', 'Weight'), 'Enter a valid number for Weight');
    });

    test('validatePositiveDouble returns error for non-positive number', () {
      expect(Validators.validatePositiveDouble('0', 'Weight'), 'Weight must be greater than zero');
      expect(Validators.validatePositiveDouble('-2.5', 'Weight'), 'Weight must be greater than zero');
    });

    test('validatePositiveDouble returns null for valid positive double', () {
      expect(Validators.validatePositiveDouble('70.5', 'Weight'), null);
      expect(Validators.validatePositiveDouble('10', 'Weight'), null);
    });

    test('validateNonNegativeInteger returns error for empty value', () {
      expect(Validators.validateNonNegativeInteger('', 'Experience'), 'Experience is required');
    });

    test('validateNonNegativeInteger returns error for invalid number', () {
      expect(Validators.validateNonNegativeInteger('five', 'Experience'), 'Enter a valid number for Experience');
    });

    test('validateNonNegativeInteger returns error for negative number', () {
      expect(Validators.validateNonNegativeInteger('-1', 'Experience'), 'Experience cannot be negative');
    });

    test('validateNonNegativeInteger returns null for zero and positive integer', () {
      expect(Validators.validateNonNegativeInteger('0', 'Experience'), null);
      expect(Validators.validateNonNegativeInteger('5', 'Experience'), null);
    });
  });
}
