# Proguard / R8 rules for Track Free Habit Tracker

# Flutter Framework & Engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Sqflite
-keep class com.tekartik.sqflite.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
# The plugin stores scheduled notifications with Gson; without these, R8
# strips generic type info and reminders fail to restore after a reboot.
-keep class com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type

# Google Sign-In & Play Services
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# Native AppWidget Provider
-keep class co.trackfree.solforge.HabitWidgetProvider { *; }

# Desugaring & Reflection
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Prevent warnings for optional dependencies
# Flutter's deferred-components support references Play Core, which this app
# doesn't ship (no deferred components); without this R8 fails the build.
-dontwarn com.google.android.play.core.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
