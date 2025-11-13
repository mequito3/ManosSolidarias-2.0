import 'package:flutter/foundation.dart';

class SupabaseRedirects {
  SupabaseRedirects._();

  static const String scheme = 'supabase';
  static const String host = 'login-callback';

  static String get redirectUri => '$scheme://$host';

  static String? get oauthRedirectUri => kIsWeb ? null : redirectUri;
}
