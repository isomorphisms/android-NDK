#ifndef IDRIC_NATIVE_MATERIAL_H
#define IDRIC_NATIVE_MATERIAL_H
#include <jni.h>
#include <stdint.h>
#include "charcoal.h"

/* Framework Views styled with Material 3 roles. No application/store/transport
 * authority lives here. Call on the UI thread inside a bounded JNI local frame.
 * This is Icky C, compiled by the consumer's declared ICK frontend. */
#define M3_PRESENTATION_VERSION 2
typedef struct {
    jint surface, on_surface, container, primary, on_primary, outline;
    jfloat density;
    int dark, dynamic;
    jint secondary, disabled, interactive, selection, focus, error, warning, success;
} M3Theme;

static inline jmethodID m3_method(JNIEnv *e, jobject value, const char *name, const char *signature) {
    jclass type ← (*e)->GetObjectClass(e, value);
    jmethodID result ← (*e)->GetMethodID(e, type, name, signature);
    (*e)->DeleteLocalRef(e, type);
    return result;
}
/* NativeActivity claims a native Surface and InputQueue before loading its C
 * entrypoint. A framework-View lane must release those claims BEFORE the Decor
 * attaches; otherwise a populated View tree can remain black or lack an input
 * target. Keep NativeActivity's lifecycle, but let ViewRoot own drawing/input.
 * An attached Window is refused: changing its callbacks then cannot rewire an
 * already-created ViewRoot. The caller must stop rather than silently fall back.
 * A native surface/Canvas lane must not call this helper. */
static inline int m3_framework_window(JNIEnv *e, jobject activity) {
    jobject window ← NULL, decor ← NULL;
    int ready ← 0;
    jmethodID get_window ← m3_method(e, activity, "getWindow", "()Landroid/view/Window;");
    if (!get_window || (*e)->ExceptionCheck(e)) goto done;
    window ← (*e)->CallObjectMethod(e, activity, get_window);
    if (!window || (*e)->ExceptionCheck(e)) goto done;
    jmethodID get_decor ← m3_method(e, window, "getDecorView", "()Landroid/view/View;");
    if (!get_decor || (*e)->ExceptionCheck(e)) goto done;
    decor ← (*e)->CallObjectMethod(e, window, get_decor);
    if (!decor || (*e)->ExceptionCheck(e)) goto done;
    jmethodID attached ← m3_method(e, decor, "isAttachedToWindow", "()Z");
    if (!attached || (*e)->ExceptionCheck(e)) goto done;
    if ((*e)->CallBooleanMethod(e, decor, attached) || (*e)->ExceptionCheck(e)) goto done;
    jmethodID surface ← m3_method(e, window, "takeSurface", "(Landroid/view/SurfaceHolder$Callback2;)V");
    if (!surface || (*e)->ExceptionCheck(e)) goto done;
    (*e)->CallVoidMethod(e, window, surface, (jobject)NULL);
    if ((*e)->ExceptionCheck(e)) goto done;
    jmethodID input ← m3_method(e, window, "takeInputQueue", "(Landroid/view/InputQueue$Callback;)V");
    if (!input || (*e)->ExceptionCheck(e)) goto done;
    (*e)->CallVoidMethod(e, window, input, (jobject)NULL);
    ready ← !(*e)->ExceptionCheck(e);
  done:
    if (decor) (*e)->DeleteLocalRef(e, decor);
    if (window) (*e)->DeleteLocalRef(e, window);
    return ready;
}
static inline jobject m3_new(JNIEnv *e, jobject context, const char *name) {
    jclass type ← (*e)->FindClass(e, name);
    jobject result ← (*e)->NewObject(e, type,
        (*e)->GetMethodID(e, type, "<init>", "(Landroid/content/Context;)V"), context);
    (*e)->DeleteLocalRef(e, type);
    return result;
}
static inline jint m3_dp(M3Theme theme, int count) {
    return (jint)(theme.density * (jfloat)count + 0.5f);
}
static inline jint m3_system_color(JNIEnv *e, jobject resources, const char *name, jint fallback) {
    jstring label ← (*e)->NewStringUTF(e, name);
    jstring color ← (*e)->NewStringUTF(e, "color");
    jstring android ← (*e)->NewStringUTF(e, "android");
    jint identity ← (*e)->CallIntMethod(e, resources, m3_method(e, resources, "getIdentifier",
        "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I"), label, color, android);
    jint result ← identity ? (*e)->CallIntMethod(e, resources,
        m3_method(e, resources, "getColor", "(ILandroid/content/res/Resources$Theme;)I"), identity, NULL) : fallback;
    (*e)->DeleteLocalRef(e, label); (*e)->DeleteLocalRef(e, color); (*e)->DeleteLocalRef(e, android);
    return result;
}
static inline M3Theme m3_theme(JNIEnv *e, jobject context) {
    jobject resources ← (*e)->CallObjectMethod(e, context,
        m3_method(e, context, "getResources", "()Landroid/content/res/Resources;"));
    jobject metrics ← (*e)->CallObjectMethod(e, resources,
        m3_method(e, resources, "getDisplayMetrics", "()Landroid/util/DisplayMetrics;"));
    jclass metric_type ← (*e)->GetObjectClass(e, metrics);
    M3Theme theme ← { (jint)CHARCOAL_BACKGROUND, (jint)CHARCOAL_TEXT,
        (jint)CHARCOAL_SURFACE, (jint)CHARCOAL_INTERACTIVE,
        (jint)CHARCOAL_TEXT, (jint)CHARCOAL_BORDER, 1.0f, 1, 0,
        (jint)CHARCOAL_SECONDARY, (jint)CHARCOAL_DISABLED,
        (jint)CHARCOAL_INTERACTIVE, (jint)CHARCOAL_SELECTION,
        (jint)CHARCOAL_FOCUS, (jint)CHARCOAL_ERROR,
        (jint)CHARCOAL_WARNING, (jint)CHARCOAL_SUCCESS };
    theme.density ← (*e)->GetFloatField(e, metrics, (*e)->GetFieldID(e, metric_type, "density", "F"));
    (*e)->DeleteLocalRef(e, metric_type); (*e)->DeleteLocalRef(e, metrics);
    (*e)->DeleteLocalRef(e, resources);
    return theme;
}
/* API 26+ framework consumers. NativeActivity surface consumers keep their
 * lifecycle claims; this changes only window colors and system icon flags. */
static inline void m3_window(JNIEnv *e, jobject activity, M3Theme theme) {
    jobject window ← (*e)->CallObjectMethod(e, activity,
        m3_method(e, activity, "getWindow", "()Landroid/view/Window;"));
    (*e)->CallVoidMethod(e, window, m3_method(e, window, "setStatusBarColor", "(I)V"), theme.surface);
    (*e)->CallVoidMethod(e, window, m3_method(e, window, "setNavigationBarColor", "(I)V"), theme.surface);
    jobject decor ← (*e)->CallObjectMethod(e, window,
        m3_method(e, window, "getDecorView", "()Landroid/view/View;"));
    jint flags ← (*e)->CallIntMethod(e, decor, m3_method(e, decor, "getSystemUiVisibility", "()I"));
    (*e)->CallVoidMethod(e, decor, m3_method(e, decor, "setSystemUiVisibility", "(I)V"), flags & ~0x2010);
    (*e)->DeleteLocalRef(e, decor); (*e)->DeleteLocalRef(e, window);
}
static inline void m3_text(JNIEnv *e, jobject view, jstring text, M3Theme theme, jfloat sp) {
    (*e)->CallVoidMethod(e, view, m3_method(e, view, "setText", "(Ljava/lang/CharSequence;)V"), text);
    (*e)->CallVoidMethod(e, view, m3_method(e, view, "setTextColor", "(I)V"), theme.on_surface);
    (*e)->CallVoidMethod(e, view, m3_method(e, view, "setHighlightColor", "(I)V"), theme.selection);
    (*e)->CallVoidMethod(e, view, m3_method(e, view, "setTextSize", "(F)V"), sp);
}
static inline void m3_describe(JNIEnv *e, jobject view, const char *description) {
    jstring text ← (*e)->NewStringUTF(e, description);
    (*e)->CallVoidMethod(e, view, m3_method(e, view, "setContentDescription", "(Ljava/lang/CharSequence;)V"), text);
    (*e)->DeleteLocalRef(e, text);
}
static inline void m3_control(JNIEnv *e, jobject view, M3Theme theme, int filled) {
    jint background ← filled ? theme.primary : theme.container;
    jint foreground ← filled ? theme.on_primary : theme.on_surface;
    (*e)->CallVoidMethod(e, view, m3_method(e, view, "setTextColor", "(I)V"), foreground);
    (*e)->CallVoidMethod(e, view, m3_method(e, view, "setAllCaps", "(Z)V"), JNI_FALSE);
    (*e)->CallVoidMethod(e, view, m3_method(e, view, "setTextSize", "(F)V"), 14.0f);
    (*e)->CallVoidMethod(e, view, m3_method(e, view, "setMinHeight", "(I)V"), m3_dp(theme, 48));
    (*e)->CallVoidMethod(e, view, m3_method(e, view, "setMinimumHeight", "(I)V"), m3_dp(theme, 48));
    (*e)->CallVoidMethod(e, view, m3_method(e, view, "setMinimumWidth", "(I)V"), m3_dp(theme, 48));
    (*e)->CallVoidMethod(e, view, m3_method(e, view, "setPadding", "(IIII)V"),
        m3_dp(theme, 12), 0, m3_dp(theme, 12), 0);
    jclass shape_type ← (*e)->FindClass(e, "android/graphics/drawable/GradientDrawable");
    jobject shape ← (*e)->NewObject(e, shape_type, (*e)->GetMethodID(e, shape_type, "<init>", "()V"));
    (*e)->CallVoidMethod(e, shape, m3_method(e, shape, "setColor", "(I)V"), background);
    (*e)->CallVoidMethod(e, shape, m3_method(e, shape, "setStroke", "(II)V"), m3_dp(theme, 1), theme.outline);
    (*e)->CallVoidMethod(e, shape, m3_method(e, shape, "setCornerRadius", "(F)V"), (jfloat)m3_dp(theme, 20));
    jclass colors_type ← (*e)->FindClass(e, "android/content/res/ColorStateList");
    jobject colors ← (*e)->CallStaticObjectMethod(e, colors_type,
        (*e)->GetStaticMethodID(e, colors_type, "valueOf", "(I)Landroid/content/res/ColorStateList;"),
        (foreground & 0x00ffffff) | 0x1f000000); /* 12% state layer */
    jclass ripple_type ← (*e)->FindClass(e, "android/graphics/drawable/RippleDrawable");
    jobject ripple ← (*e)->NewObject(e, ripple_type, (*e)->GetMethodID(e, ripple_type, "<init>",
        "(Landroid/content/res/ColorStateList;Landroid/graphics/drawable/Drawable;Landroid/graphics/drawable/Drawable;)V"), colors, shape, NULL);
    (*e)->CallVoidMethod(e, view, m3_method(e, view, "setBackground", "(Landroid/graphics/drawable/Drawable;)V"), ripple);
    (*e)->DeleteLocalRef(e, ripple); (*e)->DeleteLocalRef(e, ripple_type);
    (*e)->DeleteLocalRef(e, colors); (*e)->DeleteLocalRef(e, colors_type);
    (*e)->DeleteLocalRef(e, shape); (*e)->DeleteLocalRef(e, shape_type);
}
static inline void m3_enabled(JNIEnv *e, jobject view, int enabled) {
    (*e)->CallVoidMethod(e, view, m3_method(e, view, "setEnabled", "(Z)V"), enabled ? JNI_TRUE : JNI_FALSE);
    (*e)->CallVoidMethod(e, view, m3_method(e, view, "setTextColor", "(I)V"),
        (jint)(enabled ? CHARCOAL_TEXT : CHARCOAL_DISABLED));
}
static inline jobject m3_button(JNIEnv *e, jobject context, jobject listener, M3Theme theme,
        jint identity, const char *label, int filled) {
    jobject button ← m3_new(e, context, "android/widget/Button");
    jstring text ← (*e)->NewStringUTF(e, label);
    m3_text(e, button, text, theme, 14.0f);
    (*e)->CallVoidMethod(e, button, m3_method(e, button, "setId", "(I)V"), identity);
    (*e)->CallVoidMethod(e, button, m3_method(e, button, "setOnClickListener", "(Landroid/view/View$OnClickListener;)V"), listener);
    m3_control(e, button, theme, filled); m3_describe(e, button, label);
    (*e)->DeleteLocalRef(e, text);
    return button;
}
static inline void m3_add(JNIEnv *e, jobject parent, jobject child, int width, int height, jfloat weight) {
    jclass type ← (*e)->FindClass(e, "android/widget/LinearLayout$LayoutParams");
    jobject params ← (*e)->NewObject(e, type, (*e)->GetMethodID(e, type, "<init>", "(IIF)V"), width, height, weight);
    (*e)->CallVoidMethod(e, parent, m3_method(e, parent, "addView", "(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V"), child, params);
    (*e)->DeleteLocalRef(e, params); (*e)->DeleteLocalRef(e, type);
}
static inline jobject m3_column(JNIEnv *e, jobject context) {
    jobject column ← m3_new(e, context, "android/widget/LinearLayout");
    (*e)->CallVoidMethod(e, column, m3_method(e, column, "setOrientation", "(I)V"), 1);
    return column;
}
#endif
