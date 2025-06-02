# Mantener todas las clases de TensorFlow Lite y GPU Delegate
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

# Si usas Flutter plugins nativos (recomendado para todos)
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# No obfuscar clases de Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
# Evita eliminar clases necesarias para los componentes diferidos
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Compatibilidad con componentes Flutter
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
# https://github.com/flutter/flutter/issues/78625#issuecomment-804164524
#-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
#-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }