# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.firebase.** { *; }

# SquareUp (OkHttp, Retrofit)
-dontwarn okio.**
-dontwarn javax.annotation.**

# Play Core (Fix for R8 missing classes)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Google ML Kit
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-keep class com.google_mlkit_text_recognition.** { *; }
-dontwarn com.google_mlkit_text_recognition.**
