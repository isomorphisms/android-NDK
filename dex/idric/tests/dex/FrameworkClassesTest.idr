module FrameworkClassesTest

import Backend.DEX.FrameworkClasses
import System

%default covering

private
reject : String -> List FrameworkClass -> IO ()
reject expected classes = case encode_framework_classes classes of
  Left observed => if observed == expected then pure () else do
    putStrLn ("FAIL: expected " ++ expected ++ ", observed " ++ observed)
    exitFailure
  Right _ => do
    putStrLn ("FAIL: accepted " ++ expected)
    exitFailure

main : IO ()
main = do
  let callback = Callback "answer" "I" ["I", "Ljava/lang/String;"]
  let valid = Subclass "Lexample/Callback;" "Ljava/lang/Object;" (Just "callback") [callback]
  reject "No framework classes" []
  reject "Duplicate framework class" [valid, valid]
  reject "Invalid class/superclass descriptor"
    [Subclass "Lbad.name;" "Ljava/lang/Object;" Nothing []]
  reject "Duplicate native callback signature"
    [Subclass "Lexample/Callback;" "Ljava/lang/Object;" Nothing [callback, callback]]
  reject "Invalid native callback signature"
    [Subclass "Lexample/Callback;" "Ljava/lang/Object;" Nothing [Callback "answer" "I" ["V"]]]
  reject "Invalid native callback signature"
    [Subclass "Lexample/Callback;" "Ljava/lang/Object;" Nothing [Callback "<init>" "V" []]]
  reject "Invalid native library name"
    [Subclass "Lexample/Callback;" "Ljava/lang/Object;" (Just "../bad") []]
  reject "App-defined superclass dependencies are unsupported"
    [Subclass "Lexample/One;" "Lexample/Two;" Nothing [],
     Subclass "Lexample/Two;" "Lexample/One;" Nothing []]
  case encode_framework_classes [valid] of
    Left problem => do
      putStrLn problem
      exitFailure
    Right first => case encode_framework_classes [valid] of
      Right second => if first == second then do
        result <- write_framework_classes [valid] "build/framework-test.dex"
        case result of
          Left problem => do
            putStrLn problem
            exitFailure
          Right () => putStrLn "PASS: class encoder, deterministic output, eight rejection cases"
        else exitFailure
      Left _ => exitFailure
