# ==============================================
# REGLAS PARA FLUTTER (¡ESENCIALES!)
# ==============================================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# ==============================================
# TU MAINACTIVITY Y FLUTTERFRAGMENTACTIVITY
# ==============================================
-keep public class com.opole.app.MainActivity
-keep class io.flutter.embedding.android.FlutterFragmentActivity { *; }

# ==============================================
# MÉTODOS NATIVOS (JNI)
# ==============================================
-keepclasseswithmembernames class * {
    native <methods>;
}

# ==============================================
# PARCELABLE Y SERIALIZABLE
# ==============================================
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ==============================================
# FIREBASE CRASHLYTICS
# ==============================================
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# ==============================================
# GOOGLE PLAY SERVICES
# ==============================================
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ==============================================
# TUS REGLAS DE ZEGO
# ==============================================
-keep class **.zego.**  { *; }
-keep class **.**.zego_zpns.** { *; }

# ==============================================
# TUS REGLAS DE DEEP AR
# ==============================================
-keepclassmembers class ai.deepar.ar.DeepAR { *; }
-keepclassmembers class ai.deepar.ar.core.videotexture.VideoTextureAndroidJava { *; }
-keep class ai.deepar.ar.core.videotexture.VideoTextureAndroidJava

# ==============================================
# TUS REGLAS DE JAVASCRIPTINTERFACE
# ==============================================
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*

# ==============================================
# TUS REGLAS DE RAZORPAY
# ==============================================
-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}
-optimizations !method/inlining/*
-keepclasseswithmembers class * {
    public void onPayment*(...);
}

# ==============================================
# REGLAS ADICIONALES PARA EXOPLAYER
# ==============================================
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# ==============================================
# REGLAS PARA ANDROIDX Y DESUGARING
# ==============================================
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**