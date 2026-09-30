#include "idric_binder_ndk.h"

#include <android/binder_ibinder.h>
#include <android/binder_parcel.h>
#include <android/binder_status.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>

struct idric_binder_handle {
    AIBinder *value;
};

struct idric_binder_transaction {
    AIBinder *target;
    AParcel *input;
    AParcel *output;
    binder_status_t status;
    int sent;
};

struct idric_binder_class_entry {
    char *descriptor;
    AIBinder_Class *clazz;
    struct idric_binder_class_entry *next;
};

static pthread_mutex_t class_lock = PTHREAD_MUTEX_INITIALIZER;
static struct idric_binder_class_entry *classes = NULL;

static binder_status_t bad_value(void) {
    return STATUS_BAD_VALUE;
}

static void *client_class_on_create(void *args) {
    return args;
}

static void client_class_on_destroy(void *user_data) {
    (void)user_data;
}

static binder_status_t client_class_on_transact(AIBinder *binder,
                                                transaction_code_t code,
                                                const AParcel *input,
                                                AParcel *output) {
    (void)binder;
    (void)code;
    (void)input;
    (void)output;
    return STATUS_UNKNOWN_TRANSACTION;
}

static char *copy_text(const char *text) {
    size_t length;
    char *copy;
    if (text == NULL) return NULL;
    length = strlen(text) + 1;
    copy = (char *)malloc(length);
    if (copy != NULL) memcpy(copy, text, length);
    return copy;
}

static const AIBinder_Class *class_for_descriptor(const char *descriptor) {
    struct idric_binder_class_entry *entry;
    struct idric_binder_class_entry *created;
    AIBinder_Class *clazz;
    char *owned_descriptor;

    if (descriptor == NULL || descriptor[0] == '\0') return NULL;

    if (pthread_mutex_lock(&class_lock) != 0) return NULL;
    for (entry = classes; entry != NULL; entry = entry->next) {
        if (strcmp(entry->descriptor, descriptor) == 0) {
            clazz = entry->clazz;
            pthread_mutex_unlock(&class_lock);
            return clazz;
        }
    }

    owned_descriptor = copy_text(descriptor);
    if (owned_descriptor == NULL) {
        pthread_mutex_unlock(&class_lock);
        return NULL;
    }

    created = (struct idric_binder_class_entry *)malloc(sizeof(*created));
    if (created == NULL) {
        free(owned_descriptor);
        pthread_mutex_unlock(&class_lock);
        return NULL;
    }

    clazz = AIBinder_Class_define(owned_descriptor,
                                  client_class_on_create,
                                  client_class_on_destroy,
                                  client_class_on_transact);
    if (clazz == NULL) {
        free(created);
        free(owned_descriptor);
        pthread_mutex_unlock(&class_lock);
        return NULL;
    }
    created->descriptor = owned_descriptor;
    created->clazz = clazz;
    created->next = classes;
    classes = created;

    pthread_mutex_unlock(&class_lock);
    return clazz;
}

static idric_binder_handle *wrap_owned_binder(AIBinder *binder) {
    idric_binder_handle *handle;
    if (binder == NULL) return NULL;
    handle = (idric_binder_handle *)malloc(sizeof(*handle));
    if (handle == NULL) {
        AIBinder_decStrong(binder);
        return NULL;
    }
    handle->value = binder;
    return handle;
}

int idric_binder_get_calling_uid(void) {
    return (int)AIBinder_getCallingUid();
}

int idric_binder_get_calling_pid(void) {
    return (int)AIBinder_getCallingPid();
}

void idric_binder_release(idric_binder_handle *binder) {
    if (binder == NULL) return;
    if (binder->value != NULL) AIBinder_decStrong(binder->value);
    binder->value = NULL;
    free(binder);
}

int idric_binder_ping(const idric_binder_handle *binder) {
    if (binder == NULL || binder->value == NULL) return (int)bad_value();
    return (int)AIBinder_ping(binder->value);
}

int idric_binder_associate_descriptor(idric_binder_handle *binder,
                                      const char *descriptor) {
    const AIBinder_Class *clazz;
    if (binder == NULL || binder->value == NULL) return (int)bad_value();
    clazz = class_for_descriptor(descriptor);
    if (clazz == NULL) return STATUS_NO_MEMORY;
    return AIBinder_associateClass(binder->value, clazz) ? STATUS_OK : STATUS_BAD_TYPE;
}

idric_binder_transaction *idric_binder_transaction_new(idric_binder_handle *binder) {
    idric_binder_transaction *transaction;
    if (binder == NULL || binder->value == NULL) return NULL;

    transaction = (idric_binder_transaction *)calloc(1, sizeof(*transaction));
    if (transaction == NULL) return NULL;

    transaction->target = binder->value;
    AIBinder_incStrong(transaction->target);
    transaction->status = AIBinder_prepareTransaction(transaction->target,
                                                      &transaction->input);
    return transaction;
}

void idric_binder_transaction_delete(idric_binder_transaction *transaction) {
    if (transaction == NULL) return;
    if (transaction->input != NULL) AParcel_delete(transaction->input);
    if (transaction->output != NULL) AParcel_delete(transaction->output);
    if (transaction->target != NULL) AIBinder_decStrong(transaction->target);
    transaction->input = NULL;
    transaction->output = NULL;
    transaction->target = NULL;
    free(transaction);
}

int idric_binder_transaction_status(const idric_binder_transaction *transaction) {
    if (transaction == NULL) return (int)bad_value();
    return (int)transaction->status;
}

static binder_status_t ready_to_write(const idric_binder_transaction *transaction) {
    if (transaction == NULL || transaction->input == NULL || transaction->sent) {
        return bad_value();
    }
    return transaction->status;
}

static binder_status_t ready_to_read(const idric_binder_transaction *transaction) {
    if (transaction == NULL || transaction->output == NULL || !transaction->sent) {
        return bad_value();
    }
    return transaction->status;
}

int idric_binder_transaction_write_int32(idric_binder_transaction *transaction,
                                         int value) {
    binder_status_t status = ready_to_write(transaction);
    if (status != STATUS_OK) return (int)status;
    transaction->status = AParcel_writeInt32(transaction->input, (int32_t)value);
    return (int)transaction->status;
}

int idric_binder_transaction_write_binder(idric_binder_transaction *transaction,
                                          const idric_binder_handle *binder) {
    binder_status_t status = ready_to_write(transaction);
    if (status != STATUS_OK) return (int)status;
    transaction->status = AParcel_writeStrongBinder(
        transaction->input, binder == NULL ? NULL : binder->value);
    return (int)transaction->status;
}

int idric_binder_transaction_write_fd(idric_binder_transaction *transaction,
                                      int fd) {
    binder_status_t status = ready_to_write(transaction);
    if (status != STATUS_OK) return (int)status;
    transaction->status = AParcel_writeParcelFileDescriptor(transaction->input, fd);
    return (int)transaction->status;
}

int idric_binder_transaction_send(idric_binder_transaction *transaction,
                                  uint32_t code, uint32_t flags) {
    binder_status_t status;
    if (transaction == NULL || transaction->target == NULL ||
        transaction->input == NULL || transaction->sent) {
        return (int)bad_value();
    }
    if (transaction->status != STATUS_OK) return (int)transaction->status;

    status = AIBinder_transact(transaction->target, code,
                              &transaction->input, &transaction->output, flags);
    /* AIBinder_transact takes ownership of the input parcel. */
    transaction->input = NULL;
    transaction->sent = 1;
    transaction->status = status;
    return (int)status;
}

int idric_binder_transaction_read_int32(idric_binder_transaction *transaction) {
    int32_t value = 0;
    binder_status_t status = ready_to_read(transaction);
    if (status != STATUS_OK) {
        if (transaction != NULL) transaction->status = status;
        return 0;
    }
    transaction->status = AParcel_readInt32(transaction->output, &value);
    return transaction->status == STATUS_OK ? (int)value : 0;
}

idric_binder_handle *idric_binder_transaction_read_binder(
    idric_binder_transaction *transaction) {
    AIBinder *binder = NULL;
    binder_status_t status = ready_to_read(transaction);
    if (status != STATUS_OK) {
        if (transaction != NULL) transaction->status = status;
        return NULL;
    }
    transaction->status = AParcel_readStrongBinder(transaction->output, &binder);
    if (transaction->status != STATUS_OK) return NULL;
    return wrap_owned_binder(binder);
}

int idric_binder_transaction_read_fd(idric_binder_transaction *transaction) {
    int fd = -1;
    binder_status_t status = ready_to_read(transaction);
    if (status != STATUS_OK) {
        if (transaction != NULL) transaction->status = status;
        return -1;
    }
    transaction->status = AParcel_readParcelFileDescriptor(transaction->output, &fd);
    return transaction->status == STATUS_OK ? fd : -1;
}

int idric_binder_pointer_is_null(const void *pointer) {
    return pointer == NULL ? 1 : 0;
}
