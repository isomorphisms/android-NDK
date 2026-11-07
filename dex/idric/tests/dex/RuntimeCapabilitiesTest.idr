module RuntimeCapabilitiesTest

import Backend.DEX.Capabilities
import Backend.DEX.IR
import Backend.DEX.RuntimeArgs
import Compiler.ANF
import Core.CompileExpr
import Core.Name
import Data.List
import System

%default covering

owner : String
owner = "LIdric/Generated;"

method : String -> List Instruction -> MethodPlan
method name code = MkMethodPlan name name 0 [] VoidValue 1 (code ++ [ReturnVoid])

invoke : String -> Instruction
invoke target = InvokeMethod (Invoke InvokeStatic
  (MkMethodReference (MkTypeReference owner) target [] VoidValue) [] Nothing)

foreign_definition : String -> (Name, Administrative_Normal_Form_Definition)
foreign_definition convention = (UN (Basic "unrelatedSpelling"),
  Make_Administrative_Normal_Form_Foreign_Function [convention] [CFWorld] (CFIORes CFInt))

require : String -> Bool -> IO ()
require label True = pure ()
require label False = do
  putStrLn ("FAIL runtime capabilities: " ++ label)
  exitFailure

main : IO ()
main = do
  let methods = [method "entry" [invoke "first"], method "first" [invoke "second"],
                 method "second" [invoke "first"], method "unused" []]
  require "transitive recursive generated dependencies"
    (map method_name (retain_reachable_methods owner ["entry"] methods) == ["entry", "first", "second"])
  require "missing generated dependency refusal"
    (case validate_runtime_dependencies owner [method "entry" [invoke "absent"]] of Left _ => True; Right _ => False)
  require "complete dependency graph admitted"
    (case validate_runtime_dependencies owner methods of Right () => True; Left _ => False)
  require "argument capability follows checked convention"
    (needs_runtime_arguments (checked_runtime_requirements
      [foreign_definition "C:idris2_getArgCount, libidris2_support, idris_support.h"]))
  require "unrelated declaration does not gain argv capability"
    (not (needs_runtime_arguments (checked_runtime_requirements [foreign_definition "C:user_getArgCount"])))
  case with_runtime_entry "entry" (MkFilePlan owner [method "entry" []]) of
    Left explanation => do putStrLn explanation; exitFailure
    Right plan => do
      require "no retained argument field" (null plan.fields)
      require "only command entry adapter" (map method_name plan.methods == ["entry", "main"])
  putStrLn "PASS checked runtime capabilities and dependency closure"
