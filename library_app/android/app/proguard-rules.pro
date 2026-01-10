# Flutter secure storage / Google Tink crypto library rules
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn com.google.api.client.http.**
-dontwarn org.joda.time.**

# Keep Google Tink classes
-keep class com.google.crypto.tink.** { *; }

# Keep all annotations
-keepattributes *Annotation*
