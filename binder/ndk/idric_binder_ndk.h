#ifndef IDRIC_BINDER_NDK_H
#define IDRIC_BINDER_NDK_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct idric_binder_handle idric_binder_handle;
typedef struct idric_binder_transaction idric_binder_transaction;

/* Caller identity is meaningful while this thread is handling a Binder call. */
int idric_binder_get_calling_uid(void);
int idric_binder_get_calling_pid(void);

/* Process-wide Binder thread-pool controls. */
void idric_binder_start_thread_pool(void);
int idric_binder_set_thread_pool_max_threads(uint32_t count);
void idric_binder_join_thread_pool(void);

/* API-29 service lookup. Returned handles own one strong Binder reference. */
idric_binder_handle *idric_binder_check_service(const char *instance);
void idric_binder_release(idric_binder_handle *binder);
int idric_binder_ping(const idric_binder_handle *binder);

/*
 * AIBinder_prepareTransaction requires a class association. This associates a
 * reusable client-side class for the exact AIDL interface descriptor.
 */
int idric_binder_associate_descriptor(idric_binder_handle *binder,
                                      const char *descriptor);

/*
 * The transaction owns its input parcel until send. AIBinder_transact consumes
 * that parcel. After send, the transaction owns the output parcel until delete.
 * The most recent Binder/parcel status is retained on the transaction.
 */
idric_binder_transaction *idric_binder_transaction_new(idric_binder_handle *binder);
void idric_binder_transaction_delete(idric_binder_transaction *transaction);
int idric_binder_transaction_status(const idric_binder_transaction *transaction);

int idric_binder_transaction_write_int32(idric_binder_transaction *transaction,
                                         int value);
int idric_binder_transaction_write_binder(idric_binder_transaction *transaction,
                                          const idric_binder_handle *binder);
int idric_binder_transaction_write_fd(idric_binder_transaction *transaction,
                                      int fd);

int idric_binder_transaction_send(idric_binder_transaction *transaction,
                                  uint32_t code, uint32_t flags);

/* Read functions return the value and update transaction_status on failure. */
int idric_binder_transaction_read_int32(idric_binder_transaction *transaction);
idric_binder_handle *idric_binder_transaction_read_binder(
    idric_binder_transaction *transaction);
int idric_binder_transaction_read_fd(idric_binder_transaction *transaction);

/* FFI helper: 1 for null, 0 otherwise. */
int idric_binder_pointer_is_null(const void *pointer);

#ifdef __cplusplus
}
#endif

#endif
