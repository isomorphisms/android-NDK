module Backend.DEX.EncodeNativeActivityShell

import Backend.DEX.Encode
import Backend.DEX.FrameworkClasses
import Backend.DEX.IR
import Data.List

%default covering

private
ascii_metadata : String -> Either String ()
ascii_metadata value = do
  _ <- traverse check (unpack value)
  Right ()
  where
    check : Char -> Either String ()
    check character =
      if ord character >= 1 && ord character <= 127 then Right ()
      else Left ("NativeActivity DEX metadata must be non-NUL ASCII: " ++ show character)

||| Compatibility shell; NativeActivity still owns manifest-defined loading.
||| This adapter supplies declarations/instructions, never another DEX writer.
public export
encode_native_activity_shell_dex : String -> Either String (List Int)
encode_native_activity_shell_dex activity_descriptor = do
  if isPrefixOf (unpack "Lorg/") (unpack activity_descriptor) &&
     isSuffixOf (unpack ";") (unpack activity_descriptor)
    then Right ()
    else Left ("NativeActivity shell requires an Lorg/...; descriptor, got " ++ activity_descriptor)
  ascii_metadata activity_descriptor
  base <- framework_class_plan
    (Subclass activity_descriptor "Landroid/app/NativeActivity;" Nothing []) []
  let bundle = ReferenceValue (MkTypeReference "Landroid/os/Bundle;")
  let create = MkBoundMethodPlan "NativeActivity superclass callback" "onCreate"
        1 [bundle] VoidValue 2
        [ InvokeMethod (Invoke InvokeSuper
            (MkMethodReference base.superclass "onCreate" [bundle] VoidValue)
            [MkRegister 0, MkRegister 1] Nothing)
        , ReturnVoid ] ProtectedInstanceMethod
  encode_dex ({ methods := base.methods ++ [create] } base)

public export
write_native_activity_shell_dex : String -> String -> IO (Either String ())
write_native_activity_shell_dex activity_descriptor path =
  case encode_native_activity_shell_dex activity_descriptor of
    Left explanation => pure (Left explanation)
    Right bytes => write_dex path bytes
