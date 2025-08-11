# Keep Sceneform classes
-keep class com.google.ar.sceneform.** { *; }
-keep class com.google.devtools.build.android.desugar.runtime.** { *; }

# Suppress warnings for missing Sceneform classes (generated automatically)
-dontwarn com.google.ar.sceneform.animation.AnimationEngine
-dontwarn com.google.ar.sceneform.animation.AnimationLibraryLoader
-dontwarn com.google.ar.sceneform.assets.Loader
-dontwarn com.google.ar.sceneform.assets.ModelData
-dontwarn com.google.devtools.build.android.desugar.runtime.ThrowableExtension

# Keep ARCore classes
-keep class com.google.ar.core.** { *; }

# Keep all annotation processing
-keepattributes *Annotation*

# Keep serialization related
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep line numbers for crash reports
-keepattributes LineNumberTable,SourceFile
