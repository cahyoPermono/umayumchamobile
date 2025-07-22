
# Add rules for the file_saver plugin to prevent code shrinking issues.
# This might be necessary if R8 (or ProGuard) is stripping classes
# that are dynamically accessed by the plugin.

-keep class com.example.file_saver.** { *; }
-keep class io.flutter.plugins.file_saver.** { *; }
-keep class dev.flutter.plugins.file_saver.** { *; }
