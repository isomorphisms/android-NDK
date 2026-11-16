/* Test-only native counterparty. The compiler emits the actual candidate
 * declaration/call; this receiver checks exact mixed scalar values and writes
 * one complete fixed Int32 result without retaining the output reference. */
#include <jni.h>
#include <stdint.h>

JNIEXPORT jint JNICALL Java_Idric_Generated_renderOutput(
    JNIEnv *environment, jclass owner, jlong handle, jint width, jint height,
    jint quality, jdouble camera, jdouble yaw, jdouble pitch, jdouble zoom,
    jintArray output)
{
    (void)owner;
    if ((*environment)->ExceptionCheck(environment)) return 2;
    if (output == NULL || handle != 16777217 || width != 2 || height != 2 ||
        quality != 1 || camera != 0.4 || yaw != 0.37 || pitch != -0.19 || zoom != 1.1)
        return 2;
    if ((*environment)->GetArrayLength(environment, output) != 4) return 2;
    const jint pixels[4] = {0x12345678, -1, INT32_MIN, 17};
    (*environment)->SetIntArrayRegion(environment, output, 0, 4, pixels);
    return (*environment)->ExceptionCheck(environment) ? 2 : 0;
}
