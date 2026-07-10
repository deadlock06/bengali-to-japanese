import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('ja')
  ];

  /// App display name
  ///
  /// In en, this message translates to:
  /// **'Bhasago'**
  String get appTitle;

  /// Kana grid screen title
  ///
  /// In en, this message translates to:
  /// **'Kana'**
  String get kanaTitle;

  /// Bottom nav: learn tab
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get navLearn;

  /// Bottom nav: speak tab
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get navSpeak;

  /// Bottom nav: pitch accent tab
  ///
  /// In en, this message translates to:
  /// **'Pitch'**
  String get pitchTitle;

  /// Bottom nav: review tab
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get navReview;

  /// Review screen reveal button
  ///
  /// In en, this message translates to:
  /// **'Show answer'**
  String get showAnswer;

  /// Review screen completion message
  ///
  /// In en, this message translates to:
  /// **'All done!'**
  String get reviewDone;

  /// FSRS rating: again
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get rAgain;

  /// FSRS rating: hard
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get rHard;

  /// FSRS rating: good
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get rGood;

  /// FSRS rating: easy
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get rEasy;

  /// Skip button label
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipLabel;

  /// Hint button label
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get hintLabel;

  /// Quit button label
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get quitLabel;

  /// Lesson start button
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startLesson;

  /// Next step button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextLabel;

  /// Audio play button
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listenLabel;

  /// Microphone record button
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get recordLabel;

  /// Lesson completion heading
  ///
  /// In en, this message translates to:
  /// **'Lesson complete'**
  String get lessonComplete;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return SBn();
    case 'en':
      return SEn();
    case 'ja':
      return SJa();
  }

  throw FlutterError(
      'S.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
