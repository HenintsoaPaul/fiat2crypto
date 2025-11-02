import 'package:flutter/material.dart';
import 'package:flutter_fiat2crypto/l10n/app_localizations.dart';
import 'package:hooks_riverpod/legacy.dart';

/// Provider
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);

/// Notifier
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(Locale('en'));

  void changeLocale(Locale locale) {
    if (state != locale && AppLocalizations.supportedLocales.contains(locale)) {
      state = locale;
    }
  }
}
