module Float32ContractCheck

import Backend.DEX.Foreign
import Backend.DEX.IR
import Backend.DEX.ManagedBoundary
import Core.CompileExpr
import Core.Name
import Data.List
import System

%default covering

fail : String -> IO value
fail reason = do
  putStrLn ("FAIL checked Float32 contract: " ++ reason)
  exitFailure

check : String -> Bool -> IO ()
check _ True = pure ()
check label False = fail label

refuse : String -> Either String value -> IO ()
refuse _ (Left _) = pure ()
refuse label (Right _) = fail (label ++ " accepted")

domain : CFType
domain = CFUser (UN (Basic "Float32")) []

other_domain : CFType
other_domain = CFUser (UN (Basic "Unrelated")) []

accept : String -> List CFType -> CFType -> IO DEXForeign
accept convention arguments result =
  case parse_dex_foreign convention arguments result of
    Left reason => fail reason
    Right accepted => pure accepted

has_invocation : String -> List Instruction -> Bool
has_invocation wanted = any (\instruction => case instruction of
  InvokeMethod invocation => invocation.method.name == wanted
  _ => False)

main : IO ()
main = do
  imported <- accept "dex:virtual:Landroid/view/MotionEvent;:getX:()F"
    [CFUser (UN (Basic "MotionEvent")) [], CFWorld] (CFIORes domain)
  check "platform F remains distinct from Double"
    (foreign_target_result imported == ExistingValue FloatValue)
  case foreign_reference_constraints imported of
    Left reason => fail reason
    Right constraints => check "F32 domain requires the exact boxed Float class"
      (lookup (UN (Basic "Float32")) constraints == Just (MkTypeReference "Ljava/lang/Float;"))
  subtraction <- accept "dex:float32:subtract" [domain, domain] domain
  case managed_foreign_bridge "checked_subtraction" subtraction of
    Left reason => fail reason
    Right plan => do
      check "both operands unbox as Float32"
        (length (filter (\instruction => case instruction of
          InvokeMethod invocation => invocation.method.name == "floatValue"
          _ => False) plan.instructions) == 2)
      check "checked subtraction uses exactly one true Float32 operation"
        (length (filter (\instruction => case instruction of
          Binary32Binary SubtractBinary32 _ _ _ => True
          _ => False) plan.instructions) == 1)
      check "result is boxed without widening" (has_invocation "valueOf" plan.instructions)
      check "no implicit Float-to-Double conversion" (not (has_invocation "doubleValue" plan.instructions))
  effectful <- accept "dex:float32:subtract" [domain, domain, CFWorld] (CFIORes domain)
  check "explicit PrimIO world is retained" (effectful.effect == PrimitiveIOForeign)
  refuse "Double signature cannot claim Float32 arithmetic"
    (parse_dex_foreign "dex:float32:subtract" [CFDouble, CFDouble] CFDouble)
  refuse "arithmetic domains cannot be mixed"
    (parse_dex_foreign "dex:float32:subtract" [domain, other_domain] domain)
  refuse "arithmetic result domain cannot change"
    (parse_dex_foreign "dex:float32:subtract" [domain, domain] other_domain)
  refuse "arithmetic arity must be exact"
    (parse_dex_foreign "dex:float32:subtract" [domain] domain)
  refuse "unknown Float32 arithmetic refuses"
    (parse_dex_foreign "dex:float32:pow" [domain, domain] domain)
  refuse "missing IO World refuses"
    (parse_dex_foreign "dex:float32:subtract" [domain, domain] (CFIORes domain))
  refuse "Double cannot silently import a platform F result"
    (parse_dex_foreign "dex:virtual:Landroid/view/MotionEvent;:getX:()F"
      [CFUser (UN (Basic "MotionEvent")) [], CFWorld] (CFIORes CFDouble))
  refuse "Double cannot silently export a platform F argument"
    (parse_dex_foreign "dex:static:Ljava/lang/Float;:floatToRawIntBits:(F)I" [CFDouble] CFInt32)
  refuse "Float32 arrays remain unsupported"
    (parse_method_descriptor "([F)V")
  putStrLn "PASS checked Float32 domains, arithmetic and preserved refusals"
