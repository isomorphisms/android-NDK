/* Native ownership fixture for the explicit synchronous input-copy contract.
 * The qualification observer uses one calling thread. No JNI reference or
 * borrowed/pinned Java array storage survives the current native invocation.
 * This implements transport/ownership checks, not polynomial mathematics.
 */
#include <jni.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

_Static_assert(sizeof(jdouble) == sizeof(uint64_t), "binary64 JNI value required");
_Static_assert(sizeof(jlong) == sizeof(uint64_t), "64-bit JNI handle required");

struct snapshot {
    jlong handle;
    jint family_degree;
    jint offsets[5];
    jsize coefficient_count;
    jdouble *coefficients;
    jint *xyz;
    struct snapshot *next;
};

static struct snapshot *snapshots;
static jlong next_handle = 1;
static jlong entries;
static jlong last_handle;

static void fail(JNIEnv *environment, const char *type, const char *message) {
    jclass exception_type;
    if ((*environment)->ExceptionCheck(environment)) return;
    exception_type = (*environment)->FindClass(environment, type);
    if (exception_type == NULL) return;
    (*environment)->ThrowNew(environment, exception_type, message);
    (*environment)->DeleteLocalRef(environment, exception_type);
}

static int array_type(JNIEnv *environment, jobject value, const char *descriptor) {
    jclass expected;
    jboolean matches;
    if (value == NULL) {
        fail(environment, "java/lang/NullPointerException", "copySurface rejects null input array");
        return 0;
    }
    expected = (*environment)->FindClass(environment, descriptor);
    if (expected == NULL) return 0;
    matches = (*environment)->IsInstanceOf(environment, value, expected);
    (*environment)->DeleteLocalRef(environment, expected);
    if (!matches) {
        fail(environment, "java/lang/ClassCastException", "copySurface input array type mismatch");
        return 0;
    }
    return 1;
}

static void destroy_snapshot(struct snapshot *value) {
    if (value == NULL) return;
    free(value->coefficients);
    free(value->xyz);
    free(value);
}

static struct snapshot *lookup(JNIEnv *environment, jlong handle) {
    struct snapshot *value;
    for (value = snapshots; value != NULL; value = value->next)
        if (value->handle == handle) return value;
    fail(environment, "java/lang/IllegalArgumentException", "unknown or released native snapshot handle");
    return NULL;
}

JNIEXPORT jlong JNICALL
Java_Idric_Generated_copySurface(JNIEnv *environment, jclass owner,
    jint version, jint family_degree, jint offset0, jint offset1, jint offset2,
    jint offset3, jint offset4, jdoubleArray coefficients, jintArray xyz) {
    struct snapshot *value;
    jsize coefficient_count, xyz_count, index;
    jint offsets[5] = {offset0, offset1, offset2, offset3, offset4};
    (void) owner;
    if (entries < INT64_MAX) entries++;
    if ((*environment)->ExceptionCheck(environment)) return 0;
    if (!array_type(environment, coefficients, "[D") ||
        !array_type(environment, xyz, "[I")) return 0;
    coefficient_count = (*environment)->GetArrayLength(environment, coefficients);
    if ((*environment)->ExceptionCheck(environment)) return 0;
    xyz_count = (*environment)->GetArrayLength(environment, xyz);
    if ((*environment)->ExceptionCheck(environment)) return 0;
    if (version != 1 || family_degree < 0 || offset0 != 0 ||
        offset4 != coefficient_count || coefficient_count > INT32_MAX / 3 ||
        xyz_count != coefficient_count * 3) {
        fail(environment, "java/lang/IllegalArgumentException", "invalid native snapshot version, lengths or offsets");
        return 0;
    }
    for (index = 1; index < 5; index++) {
        if (offsets[index] < offsets[index - 1] || offsets[index] > coefficient_count) {
            fail(environment, "java/lang/IllegalArgumentException", "nonmonotonic native snapshot offsets");
            return 0;
        }
    }
    if ((size_t) coefficient_count > SIZE_MAX / sizeof(jdouble) ||
        (size_t) xyz_count > SIZE_MAX / sizeof(jint) || next_handle == INT64_MAX) {
        fail(environment, "java/lang/OutOfMemoryError", "native snapshot allocation size exhausted");
        return 0;
    }
    value = calloc(1, sizeof(*value));
    if (value != NULL && coefficient_count != 0) {
        value->coefficients = malloc((size_t) coefficient_count * sizeof(jdouble));
        value->xyz = malloc((size_t) xyz_count * sizeof(jint));
    }
    if (value == NULL || (coefficient_count != 0 &&
        (value->coefficients == NULL || value->xyz == NULL))) {
        destroy_snapshot(value);
        fail(environment, "java/lang/OutOfMemoryError", "native snapshot allocation failed");
        return 0;
    }
    if (coefficient_count != 0) {
        (*environment)->GetDoubleArrayRegion(environment, coefficients, 0,
            coefficient_count, value->coefficients);
        if (!(*environment)->ExceptionCheck(environment))
            (*environment)->GetIntArrayRegion(environment, xyz, 0, xyz_count, value->xyz);
        if ((*environment)->ExceptionCheck(environment)) {
            destroy_snapshot(value);
            return 0;
        }
    }
    for (index = 0; index < xyz_count; index += 3) {
        int64_t degree = (int64_t) value->xyz[index] + value->xyz[index + 1] + value->xyz[index + 2];
        if (value->xyz[index] < 0 || value->xyz[index + 1] < 0 ||
            value->xyz[index + 2] < 0 || degree > family_degree) {
            destroy_snapshot(value);
            fail(environment, "java/lang/IllegalArgumentException", "invalid native snapshot xyz powers");
            return 0;
        }
    }
    value->handle = next_handle++;
    value->family_degree = family_degree;
    memcpy(value->offsets, offsets, sizeof(offsets));
    value->coefficient_count = coefficient_count;
    value->next = snapshots;
    snapshots = value;
    last_handle = value->handle;
    return value->handle;
}

JNIEXPORT jlong JNICALL
Java_Idric_Generated_coefficientBits(JNIEnv *environment, jclass owner, jlong handle, jint index) {
    struct snapshot *value = lookup(environment, handle);
    jlong bits;
    (void) owner;
    if (value == NULL) return 0;
    if (index < 0 || index >= value->coefficient_count) {
        fail(environment, "java/lang/IndexOutOfBoundsException", "native coefficient index outside snapshot");
        return 0;
    }
    memcpy(&bits, &value->coefficients[index], sizeof(bits));
    return bits;
}

JNIEXPORT jint JNICALL
Java_Idric_Generated_exponentAt(JNIEnv *environment, jclass owner, jlong handle, jint index) {
    struct snapshot *value = lookup(environment, handle);
    (void) owner;
    if (value == NULL) return 0;
    if (index < 0 || index >= value->coefficient_count * 3) {
        fail(environment, "java/lang/IndexOutOfBoundsException", "native exponent index outside snapshot");
        return 0;
    }
    return value->xyz[index];
}

JNIEXPORT jint JNICALL
Java_Idric_Generated_coefficientCount(JNIEnv *environment, jclass owner, jlong handle) {
    struct snapshot *value = lookup(environment, handle);
    (void) owner;
    return value == NULL ? 0 : value->coefficient_count;
}

JNIEXPORT void JNICALL
Java_Idric_Generated_releaseSurface(JNIEnv *environment, jclass owner, jlong handle) {
    struct snapshot **link;
    (void) owner;
    for (link = &snapshots; *link != NULL; link = &(*link)->next) {
        struct snapshot *value = *link;
        if (value->handle == handle) {
            *link = value->next;
            if (last_handle == handle) last_handle = snapshots == NULL ? 0 : snapshots->handle;
            destroy_snapshot(value);
            return;
        }
    }
    fail(environment, "java/lang/IllegalArgumentException", "unknown or released native snapshot handle");
}

JNIEXPORT jlong JNICALL
Java_Idric_Generated_entryCount(JNIEnv *environment, jclass owner) {
    (void) environment;
    (void) owner;
    return entries;
}

JNIEXPORT jlong JNICALL
Java_Idric_Generated_lastHandle(JNIEnv *environment, jclass owner) {
    (void) environment;
    (void) owner;
    return last_handle;
}
