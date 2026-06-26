# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**
-keep class com.google.gson.** { *; }
-keepattributes *Annotation*

# Supabase
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# HTTP
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
