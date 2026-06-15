import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:ryvo_admin/configs/const.dart';

class PasswordResetSession {
  const PasswordResetSession({required this.email, this.resetToken});

  final String email;
  final String? resetToken;

  Map<String, dynamic> toJson() => {
        'email': email,
        if (resetToken != null) 'resetToken': resetToken,
      };

  factory PasswordResetSession.fromJson(Map<String, dynamic> json) {
    return PasswordResetSession(
      email: json['email']?.toString() ?? '',
      resetToken: json['resetToken']?.toString(),
    );
  }
}

Future<PasswordResetSession?> getPasswordResetSession() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(AppConst.storagePasswordReset);
  if (raw == null || raw.isEmpty) return null;
  try {
    final json = jsonDecode(raw);
    if (json is! Map) return null;
    return PasswordResetSession.fromJson(Map<String, dynamic>.from(json));
  } catch (_) {
    return null;
  }
}

Future<void> setPasswordResetSession(PasswordResetSession session) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    AppConst.storagePasswordReset,
    jsonEncode(session.toJson()),
  );
}

Future<void> clearPasswordResetSession() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(AppConst.storagePasswordReset);
}
