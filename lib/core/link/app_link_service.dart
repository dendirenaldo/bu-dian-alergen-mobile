import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../../config/routes.dart';
import '../network/app_navigator.dart';

/// Menangani deep link verifikasi email & reset password.
///
/// Mendukung:
/// - `https://<domain>/verify-email?token=...`
/// - `https://<domain>/reset-password?token=...`
/// - `allergendetector://verify-email?token=...`
/// - `allergendetector://reset-password?token=...`
///
/// Navigasi memakai [appNavigatorKey] agar bisa dipanggil dari luar widget
/// tree (stream listener / cold-start initial link).
class AppLinkService {
  AppLinkService._();

  static final AppLinkService instance = AppLinkService._();

  /// Host https yang diterima (domain produksi + placeholder bila
  /// FRONTEND_URL backend belum diisi domain).
  static const List<String> httpsHosts = <String>[
    'researchcomnets.ilkom.unsri.ac.id',
    'researchcomnets.unsri.ac.id',
  ];

  /// Custom scheme aplikasi mobile (lihat APP_MOBILE_SCHEME di backend).
  static const String appScheme = 'allergendetector';

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  bool _initialized = false;

  /// Daftarkan listener link foreground + cek initial link (cold start).
  ///
  /// Aman dipanggil berkali-kali; panggilan berikutnya diabaikan.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _scheduleHandle(initial);
      }
    } catch (_) {
      // Cold-start link bersifat best-effort; abaikan kegagalan platform.
    }

    try {
      _subscription = _appLinks.uriLinkStream.listen(
        _scheduleHandle,
        onError: (_) {},
      );
    } catch (_) {
      // Listener deep link bersifat best-effort.
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }

  void _scheduleHandle(Uri uri) {
    // Tunggu navigator siap (khusus cold start dari terminated state).
    WidgetsBinding.instance.addPostFrameCallback((_) => handleLink(uri));
  }

  /// Parse [uri] lalu navigasi ke route yang sesuai.
  /// Return true bila link dikenali & dinavigasikan.
  @visibleForTesting
  bool handleLink(Uri uri) {
    final parsed = parseAppLink(uri);
    if (parsed == null) return false;
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return false;

    switch (parsed.route) {
      case AppRoutes.verifyEmail:
        navigator.pushNamed(
          AppRoutes.verifyEmail,
          arguments: <String, dynamic>{
            if (parsed.token != null && parsed.token!.isNotEmpty)
              'token': parsed.token,
          },
        );
        return true;
      case AppRoutes.resetPassword:
        navigator.pushNamed(
          AppRoutes.resetPassword,
          arguments: <String, dynamic>{
            if (parsed.token != null && parsed.token!.isNotEmpty)
              'token': parsed.token,
          },
        );
        return true;
    }
    return false;
  }

  /// Parse deep link/universal link menjadi route + token.
  /// Return null bila bukan link yang didukung.
  @visibleForTesting
  static ParsedAppLink? parseAppLink(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final token = _extractToken(uri)?.trim();

    if (scheme == appScheme) {
      // allergendetector://verify-email?token=... ; host berisi aksi.
      // Beberapa pengirim memakai allergendetector://verify-email/token atau path.
      final host = uri.host.toLowerCase();
      final firstPath =
          uri.pathSegments.isNotEmpty ? uri.pathSegments.first.toLowerCase() : '';
      final action = host.isNotEmpty ? host : firstPath;
      if (action == 'verify-email' || action == 'verify_email') {
        return ParsedAppLink(AppRoutes.verifyEmail, token);
      }
      if (action == 'reset-password' || action == 'reset_password') {
        return ParsedAppLink(AppRoutes.resetPassword, token);
      }
      // Fallback: allergendetector://<token>?  tidak didukung → abaikan.
      return null;
    }

    if (scheme == 'http' || scheme == 'https') {
      if (!httpsHosts.contains(uri.host.toLowerCase())) return null;
      final segments = uri.pathSegments.map((e) => e.toLowerCase()).toList();
      if (segments.isEmpty) return null;
      final first = segments.first;
      if (first == 'verify-email' || first == 'verify_email') {
        return ParsedAppLink(AppRoutes.verifyEmail, token);
      }
      if (first == 'reset-password' || first == 'reset_password') {
        return ParsedAppLink(AppRoutes.resetPassword, token);
      }
      return null;
    }

    return null;
  }

  /// Ambil token dari query `?token=` atau segmen path terakhir
  /// (`/verify-email/<token>`) agar tahan terhadap variasi format email.
  static String? _extractToken(Uri uri) {
    final query = uri.queryParameters['token']?.trim();
    if (query != null && query.isNotEmpty) return query;
    // Dukungan path token: /verify-email/<token> atau /reset-password/<token>.
    if (uri.pathSegments.length >= 2) {
      final first = uri.pathSegments.first.toLowerCase();
      if (first == 'verify-email' ||
          first == 'verify_email' ||
          first == 'reset-password' ||
          first == 'reset_password') {
        final last = uri.pathSegments.last.trim();
        if (last.isNotEmpty && last.toLowerCase() != first) return last;
      }
    }
    return null;
  }
}

/// Hasil parse deep link: route tujuan + token opsional.
@visibleForTesting
class ParsedAppLink {
  final String route;
  final String? token;

  const ParsedAppLink(this.route, this.token);
}
