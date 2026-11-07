module Backend.DEX.EncodeCallbackShell

import Backend.DEX.FrameworkClasses as Shared
import Data.List

%default covering

||| Compatibility facade for the retained WebView callback plans. All
||| identifier tables, method code and metadata use the canonical writer.
public export
record NativeCallback where
  constructor MkNativeCallback
  name : String
  result : String
  parameter_types : List String

private
object_type : String -> Bool
object_type descriptor =
  length (unpack descriptor) <= 512 &&
  isPrefixOf ['L'] (unpack descriptor) && isSuffixOf [';'] (unpack descriptor)

private
bounded_value : String -> Bool
bounded_value value = elem value ["Z", "I"] || object_type value

public export
encode_callback_shell : String -> String -> String -> List Backend.DEX.EncodeCallbackShell.NativeCallback -> Either String (List Int)
encode_callback_shell owner parent library callbacks = do
  if object_type owner && object_type parent then Right ()
    else Left "Invalid callback shell class descriptor"
  if all (\callback => (callback.result == "V" || bounded_value callback.result) &&
                       all bounded_value callback.parameter_types) callbacks
    then Right () else Left "Unsupported callback value type"
  Shared.encode_framework_classes
    [Shared.Subclass owner parent (Just library)
      (map (\callback => Shared.Callback callback.name callback.result callback.parameter_types) callbacks)]
