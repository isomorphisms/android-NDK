#include <android/native_activity.h>
#include <stddef.h>

void ANativeActivity_onCreate(ANativeActivity *activity, void *savedState, size_t savedStateSize) {
    (void)activity;
    (void)savedState;
    (void)savedStateSize;
}
