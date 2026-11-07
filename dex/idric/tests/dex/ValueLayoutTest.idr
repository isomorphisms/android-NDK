module ValueLayoutTest

import Backend.DEX.ValueLayout
import Backend.DEX.IR
import Data.List
import System

%default covering

private
fail : String -> IO a
fail message = do
  putStrLn ("FAIL: " ++ message)
  exitFailure

private
check : String -> Bool -> IO ()
check _ True = pure ()
check message False = fail message

private
refuses : String -> Either String a -> IO ()
refuses _ (Left _) = pure ()
refuses message (Right _) = fail message

main : IO ()
main = do
  empty <- case checked_constructor_layout "Empty" 0 of
    Left error => fail error
    Right plan => pure plan
  pair <- case checked_constructor_layout "Pair" 2 of
    Left error => fail error
    Right plan => pure plan
  closure <- case checked_closure_layout "join" 2 1 1 of
    Left error => fail error
    Right plan => pure plan
  check "tag occupies the first slot" (managed_tag_slot == 0)
  check "empty constructor retains only its tag" (managed_node_slots empty == 1 && null (managed_field_slots empty))
  check "pair fields project in construction order" (managed_field_slots pair == [1, 2])
  check "closure retains one capture and one missing argument"
    (closure.payload_count == 1 && closure.remaining_arity == 1 && closure.total_arity == 2)
  check "capture storage includes the target identity" (managed_node_slots closure == 2)
  check "record storage retains erased reference descriptors" (length (managed_payload_storage_types pair) == 2)
  case checked_closure_layout "wideClosure" 14 13 1 of
    Left error => fail error
    Right wide => check "layout imposes no scratch-register arity ceiling" (wide.total_arity == 14)
  case checked_node_fields pair ["left", "right"] of
    Left error => fail error
    Right ordered => check "payload checking preserves field order" (ordered == ["left", "right"])
  refuses "accepted an empty constructor identity" (checked_constructor_layout "" 1)
  refuses "accepted an empty closure target" (checked_closure_layout "" 2 1 1)
  refuses "accepted a zero-arity closure target" (checked_closure_layout "zero" 0 0 1)
  refuses "accepted a negative-arity closure target" (checked_closure_layout "negative" (-1) 0 1)
  refuses "accepted an already saturated partial application" (checked_closure_layout "join" 2 2 0)
  refuses "accepted capture and missing counts inconsistent with target" (checked_closure_layout "join" 2 2 1)
  refuses "accepted truncated record payload" (checked_node_fields pair ["left"])
  refuses "accepted extra record payload" (checked_node_fields pair ["left", "right", "extra"])
  refuses "accepted a closure payload inconsistent with capture count" (checked_node_fields closure ["left", "right"])
  putStrLn "PASS: checked managed value layout laws and refusal controls"
