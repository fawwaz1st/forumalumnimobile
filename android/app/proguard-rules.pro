# Flutter & common libs keep rules
# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Gson / JSON annotations (if used)
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# OkHttp / Okio
-dontwarn okhttp3.**
-dontwarn okio.**

# Sentry
-dontwarn io.sentry.**
-keep class io.sentry.** { *; }

# Keep models with json_serializable (if needed)
-keep class **$$JsonSerializable { *; }
-keep class **.models.** { *; }

# Prevent stripping of Service/Receiver used by notifications
-keep class com.dexterous.** { *; }
