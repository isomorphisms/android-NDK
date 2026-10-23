module Backend.DEX.EncodeNativeActivity

import Backend.DEX.Encode
import Backend.DEX.FrameworkClasses
import Backend.DEX.IR

%default covering

-- Compatibility adapter for the preserved Wegert JNI fixture. Application
-- behavior stays in its native library; all DEX bytes use the shared writer.
private
activity_plan : Either String FilePlan
activity_plan = do
  base <- framework_class_plan
    (Subclass "Lorg/isomorphisms/wegert/WegertActivity;"
      "Landroid/app/NativeActivity;" (Just "wegert") []) []
  let owner = MkTypeReference base.class_descriptor
  let bundle = ReferenceValue (MkTypeReference "Landroid/os/Bundle;")
  let probe = MkBoundMethodPlan "Wegert JNI declaration" "jniProbe" 0 []
                (ExistingValue IntegerValue) 0 [] NativeStaticMethod
  let create = MkBoundMethodPlan "Wegert NativeActivity callback" "onCreate"
        1 [bundle] VoidValue 2
        [ InvokeMethod (Invoke InvokeStatic
            (MkMethodReference owner "jniProbe" [] (ExistingValue IntegerValue))
            [] Nothing)
        , InvokeMethod (Invoke InvokeSuper
            (MkMethodReference base.superclass "onCreate" [bundle] VoidValue)
            [MkRegister 0, MkRegister 1] Nothing)
        , ReturnVoid ] ProtectedInstanceMethod
  Right ({ methods := base.methods ++ [probe, create] } base)

public export
encode_wegert_activity_dex : Either String (List Int)
encode_wegert_activity_dex = do
  plan <- activity_plan
  encode_dex plan

public export
write_wegert_activity_dex : String -> IO (Either String ())
write_wegert_activity_dex path = case encode_wegert_activity_dex of
  Left explanation => pure (Left explanation)
  Right bytes => write_dex path bytes
