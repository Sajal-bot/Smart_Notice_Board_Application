# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Firebase (BoM-managed)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Kotlin coroutines (common with Firebase KTX)
-dontwarn kotlinx.coroutines.**

# Keep annotations
-keepattributes *Annotation*

# If using WorkManager/notifications, these are generally safe:
-dontwarn androidx.work.**
-dontwarn androidx.core.**
