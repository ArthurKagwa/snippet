# flutter_local_notifications serialises scheduled notifications with Gson,
# which needs generic type info that R8 would otherwise strip.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
