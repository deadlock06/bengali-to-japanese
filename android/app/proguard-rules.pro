# Flutter + plugins — keep rules for release minification (Play upload)
-keep class io.flutter.** { *; }
-keep class com.google.crypto.tink.** { *; }   # sqflite_sqlcipher / tink
-dontwarn io.flutter.**
