/* A native-boundary fixture, not application implementation.
 * Build on the host/cross-build lane with the maintained compiler and JNI headers.
 * Arguments are borrowed local references. No pointer/reference escapes return.
 */
#include <jni.h>
#include <stdio.h>

JNIEXPORT jstring JNICALL
Java_Idric_Generated_identity(JNIEnv *environment, jclass owner, jstring text) {
    jobject retained;
    jstring result;
    (void) owner;
    if (text == NULL) {
        fputs("native identity received null\n", stderr);
        return NULL;
    }
    /* Retention is scoped to this call. Both allocation failure paths preserve
     * the pending exception and release any successfully acquired global ref. */
    if ((*environment)->ExceptionCheck(environment)) return NULL;
    retained = (*environment)->NewGlobalRef(environment, text);
    if (retained == NULL) return NULL;
    result = (jstring) (*environment)->NewLocalRef(environment, retained);
    (*environment)->DeleteGlobalRef(environment, retained);
    return result;
}

JNIEXPORT jstring JNICALL
Java_Idric_Generated_nullResult(JNIEnv *environment, jclass owner) {
    (void) environment;
    (void) owner;
    return NULL;
}

JNIEXPORT jstring JNICALL
Java_Idric_Generated_nullArgument(JNIEnv *environment, jclass owner) {
    (void) environment;
    (void) owner;
    return NULL;
}

JNIEXPORT jstring JNICALL
Java_Idric_Generated_throwFailure(JNIEnv *environment, jclass owner) {
    jclass exception_type;
    (void) owner;
    exception_type = (*environment)->FindClass(environment, "java/lang/IllegalStateException");
    if (exception_type == NULL) return NULL; /* propagate the pending lookup exception */
    (*environment)->ThrowNew(environment, exception_type, "native contract fixture failure");
    (*environment)->DeleteLocalRef(environment, exception_type);
    return NULL; /* pending exception must unwind; no adapter success result */
}

JNIEXPORT jint JNICALL
Java_Idric_Generated_narrow(JNIEnv *environment, jclass owner, jint number) {
    (void) environment;
    (void) owner;
    fputs("native narrow invoked\n", stderr);
    return number;
}
