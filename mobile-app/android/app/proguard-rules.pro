# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# SharedPreferences plugin
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Speech to Text
-keep class com.csdcorp.speech_to_text.** { *; }

# Flutter TTS
-keep class com.tundralabs.fluttertts.** { *; }

# Kotlin Coroutines
-keepnames class kotlinx.coroutines.** { *; }
-keepclassmembers class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**
-dontwarn io.flutter.plugins.**
