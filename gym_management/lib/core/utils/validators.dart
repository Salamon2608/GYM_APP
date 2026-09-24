class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    // Optional: Add complexity checks (uppercase, numbers, etc.)
    // For now, keep it simple as per common user expectations
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().split(' ').length < 2) {
      return 'Please enter your full name (first and last name)';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\d{10}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the OTP';
    }
    if (value.length < 6) {
      return 'OTP must be at least 6 digits';
    }
    final otpRegex = RegExp(r'^\d+$');
    if (!otpRegex.hasMatch(value)) {
      return 'OTP must contain only numbers';
    }
    return null;
  }

  static String? validatePositiveInteger(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Enter a valid number for $fieldName';
    }
    if (intValue <= 0) {
      return '$fieldName must be greater than zero';
    }
    return null;
  }

  static String? validatePositiveDouble(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    final doubleValue = double.tryParse(value);
    if (doubleValue == null) {
      return 'Enter a valid number for $fieldName';
    }
    if (doubleValue <= 0) {
      return '$fieldName must be greater than zero';
    }
    return null;
  }

  static String? validateNonNegativeInteger(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Enter a valid number for $fieldName';
    }
    if (intValue < 0) {
      return '$fieldName cannot be negative';
    }
    return null;
  }
}
