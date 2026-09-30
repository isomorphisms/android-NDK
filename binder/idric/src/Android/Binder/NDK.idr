module Android.Binder.NDK

%default total

private
binder_library : String -> String
binder_library name = "C:" ++ name ++ ",libidric_android_binder"

public export
record BinderStatus where
  constructor MkBinderStatus
  code : Int32

public export
Eq BinderStatus where
  (MkBinderStatus left) == (MkBinderStatus right) = left == right

public export
Show BinderStatus where
  show (MkBinderStatus value) = show value

public export
status_ok : BinderStatus
status_ok = MkBinderStatus 0

public export
is_ok : BinderStatus -> Bool
is_ok status = status == status_ok

public export
record Binder where
  constructor MkBinder
  pointer : GCAnyPtr

public export
record Transaction where
  constructor MkTransaction
  pointer : GCAnyPtr

%foreign (binder_library "idric_binder_pointer_is_null")
prim__pointer_is_null : AnyPtr -> Int32

%foreign (binder_library "idric_binder_get_calling_uid")
prim__get_calling_uid : PrimIO Int32

%foreign (binder_library "idric_binder_get_calling_pid")
prim__get_calling_pid : PrimIO Int32

%foreign (binder_library "idric_binder_from_java")
prim__from_java_binder : AnyPtr -> AnyPtr -> PrimIO AnyPtr

%foreign (binder_library "idric_binder_release")
prim__release_any : AnyPtr -> PrimIO ()

%foreign (binder_library "idric_binder_ping")
prim__ping : GCAnyPtr -> PrimIO Int32

%foreign (binder_library "idric_binder_associate_descriptor")
prim__associate_descriptor : GCAnyPtr -> String -> PrimIO Int32

%foreign (binder_library "idric_binder_transaction_new")
prim__transaction_new : GCAnyPtr -> PrimIO AnyPtr

%foreign (binder_library "idric_binder_transaction_delete")
prim__transaction_delete_any : AnyPtr -> PrimIO ()

%foreign (binder_library "idric_binder_transaction_status")
prim__transaction_status : GCAnyPtr -> PrimIO Int32

%foreign (binder_library "idric_binder_transaction_write_int32")
prim__transaction_write_int32 : GCAnyPtr -> Int32 -> PrimIO Int32

%foreign (binder_library "idric_binder_transaction_write_binder")
prim__transaction_write_binder : GCAnyPtr -> GCAnyPtr -> PrimIO Int32

%foreign (binder_library "idric_binder_transaction_write_fd")
prim__transaction_write_fd : GCAnyPtr -> Int32 -> PrimIO Int32

%foreign (binder_library "idric_binder_transaction_send")
prim__transaction_send : GCAnyPtr -> Bits32 -> Bits32 -> PrimIO Int32

%foreign (binder_library "idric_binder_transaction_read_int32")
prim__transaction_read_int32 : GCAnyPtr -> PrimIO Int32

%foreign (binder_library "idric_binder_transaction_read_binder")
prim__transaction_read_binder : GCAnyPtr -> PrimIO AnyPtr

%foreign (binder_library "idric_binder_transaction_read_fd")
prim__transaction_read_fd : GCAnyPtr -> PrimIO Int32

private
wrap_binder : AnyPtr -> IO (Maybe Binder)
wrap_binder pointer =
  if prim__pointer_is_null pointer == 1
    then pure Nothing
    else do
      managed <- onCollectAny pointer (\value => primIO $ prim__release_any value)
      pure (Just (MkBinder managed))

private
wrap_transaction : AnyPtr -> IO (Maybe Transaction)
wrap_transaction pointer =
  if prim__pointer_is_null pointer == 1
    then pure Nothing
    else do
      managed <- onCollectAny pointer (\value => primIO $ prim__transaction_delete_any value)
      pure (Just (MkTransaction managed))

private
status : Int32 -> BinderStatus
status = MkBinderStatus

public export
get_calling_uid : IO Int32
get_calling_uid = primIO prim__get_calling_uid

public export
get_calling_pid : IO Int32
get_calling_pid = primIO prim__get_calling_pid

||| Convert an android.os.IBinder jobject received at a JNI boundary into the
||| stable NDK Binder representation. Both pointers are valid only according to
||| JNI's normal lifetime/thread rules.
public export
from_java_binder : (jni_environment : AnyPtr) -> (java_binder : AnyPtr) ->
                   IO (Maybe Binder)
from_java_binder jni_environment java_binder = do
  pointer <- primIO $ prim__from_java_binder jni_environment java_binder
  wrap_binder pointer

public export
ping : Binder -> IO BinderStatus
ping (MkBinder binder) = status <$> primIO (prim__ping binder)

public export
associate_descriptor : Binder -> String -> IO BinderStatus
associate_descriptor (MkBinder binder) descriptor =
  status <$> primIO (prim__associate_descriptor binder descriptor)

public export
get_transaction_status : Transaction -> IO BinderStatus
get_transaction_status (MkTransaction transaction) =
  status <$> primIO (prim__transaction_status transaction)

public export
new_transaction : Binder -> IO (Either BinderStatus Transaction)
new_transaction (MkBinder binder) = do
  pointer <- primIO $ prim__transaction_new binder
  wrapped <- wrap_transaction pointer
  case wrapped of
    Nothing => pure (Left (MkBinderStatus (-12)))
    Just transaction => do
      transaction_status <- get_transaction_status transaction
      if is_ok transaction_status
        then pure (Right transaction)
        else pure (Left transaction_status)

public export
write_int32 : Transaction -> Int32 -> IO BinderStatus
write_int32 (MkTransaction transaction) value =
  status <$> primIO (prim__transaction_write_int32 transaction value)

public export
write_binder : Transaction -> Binder -> IO BinderStatus
write_binder (MkTransaction transaction) (MkBinder binder) =
  status <$> primIO (prim__transaction_write_binder transaction binder)

public export
write_fd : Transaction -> Int32 -> IO BinderStatus
write_fd (MkTransaction transaction) fd =
  status <$> primIO (prim__transaction_write_fd transaction fd)

public export
send : Transaction -> Bits32 -> Bits32 -> IO BinderStatus
send (MkTransaction transaction) code flags =
  status <$> primIO (prim__transaction_send transaction code flags)

public export
read_int32 : Transaction -> IO (Either BinderStatus Int32)
read_int32 transaction@(MkTransaction pointer) = do
  value <- primIO $ prim__transaction_read_int32 pointer
  transaction_status <- get_transaction_status transaction
  pure $ if is_ok transaction_status
    then Right value
    else Left transaction_status

public export
read_binder : Transaction -> IO (Either BinderStatus (Maybe Binder))
read_binder transaction@(MkTransaction pointer) = do
  binder_pointer <- primIO $ prim__transaction_read_binder pointer
  transaction_status <- get_transaction_status transaction
  if is_ok transaction_status
    then Right <$> wrap_binder binder_pointer
    else pure (Left transaction_status)

public export
read_fd : Transaction -> IO (Either BinderStatus Int32)
read_fd transaction@(MkTransaction pointer) = do
  fd <- primIO $ prim__transaction_read_fd pointer
  transaction_status <- get_transaction_status transaction
  pure $ if is_ok transaction_status
    then Right fd
    else Left transaction_status
