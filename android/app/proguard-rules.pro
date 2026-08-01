-keep class com.hiennv.flutter_callkit_incoming.** { *; }

# Preserve native/plugin entry points that are resolved by reflection or
# platform callbacks while still allowing R8 to shrink the rest of the app.
-keep class io.flutter.plugins.firebase.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**

-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

-keep class io.flutter.plugins.inapppurchase.** { *; }
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.**

-keepattributes *Annotation*,InnerClasses,EnclosingMethod,Signature
