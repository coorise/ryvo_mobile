class RegisterInput {
  const RegisterInput({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.fullName,
    required this.role,
  });

  final String email;
  final String password;
  final String confirmPassword;
  final String fullName;
  final String role; // client | driver
}

String? validateRegisterInput(RegisterInput input) {
  final email = input.email.trim();
  if (email.isEmpty || !email.contains('@')) return 'Valid email required';
  if (input.fullName.trim().length < 2) return 'Full name must be at least 2 characters';
  if (input.password.length < 8) return 'Minimum 8 characters';
  if (input.confirmPassword.length < 8) return 'Minimum 8 characters';
  if (input.password != input.confirmPassword) return 'Passwords must match';
  if (input.role != 'client' && input.role != 'driver') return 'Choose rider or driver';
  return null;
}
