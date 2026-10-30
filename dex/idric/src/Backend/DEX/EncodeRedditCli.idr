module Backend.DEX.EncodeRedditCli

import Backend.DEX.Encode
import Backend.DEX.IR

%default covering

-- The historical application adapter remains consumer-specific. It shares the
-- generic metadata and opcode writer rather than maintaining a second encoder.
private
reddit_plan : FilePlan
reddit_plan =
  let owner = MkTypeReference "Lorg/isomorphisms/reddit/RedditCli;"
      system = MkTypeReference "Ljava/lang/System;"
      text = ExistingValue TextValue
      arguments = ReferenceValue (MkTypeReference "[Ljava/lang/String;")
      native = MkBoundMethodPlan "Reddit JNI declaration" "run" 1 [arguments]
                 VoidValue 0 [] NativeStaticMethod
      entry = MkMethodPlan "Reddit command boundary" "main" 1 [arguments]
                VoidValue 2
                [ TextConstant (MkRegister 0) "reddit.library"
                , InvokeMethod (Invoke InvokeStatic
                    (MkMethodReference system "getProperty" [text] text)
                    [MkRegister 0] (Just (MkRegister 0)))
                , InvokeMethod (Invoke InvokeStatic
                    (MkMethodReference system "load" [text] VoidValue)
                    [MkRegister 0] Nothing)
                , InvokeMethod (Invoke InvokeStatic
                    (MkMethodReference owner "run" [arguments] VoidValue)
                    [MkRegister 1] Nothing)
                , ReturnVoid ]
  in { access_flags := 1 } (MkFilePlan owner.descriptor [entry, native])

public export
encode_reddit_cli_dex : Either String (List Int)
encode_reddit_cli_dex = encode_dex reddit_plan

public export
write_reddit_cli_dex : String -> IO (Either String ())
write_reddit_cli_dex path = case encode_reddit_cli_dex of
  Left explanation => pure (Left explanation)
  Right bytes => write_dex path bytes
