# Project-specific R8 rules. AndroidX Room, Compose, OkHttp and kotlinx.serialization
# publish consumer rules; keep this file intentionally small and review additions with
# a release build instead of broadly disabling shrinking or obfuscation.

# ML Kit Rules
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# If using specific GMS-based ML Kit features (like code scanning)
-keep class com.google.android.gms.internal.mlkit_** { *; }
-dontwarn com.google.android.gms.internal.mlkit_**

