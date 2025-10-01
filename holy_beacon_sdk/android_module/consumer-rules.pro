-keep class com.holybeacon.core.** { *; }
-keep interface com.holybeacon.core.** { *; }

# Keep enum classes
-keepclassmembers enum com.holybeacon.core.** {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep UUID processor methods
-keep class com.holybeacon.core.UuidProcessor {
    public static *;
}