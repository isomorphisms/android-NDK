module FrameworkPlanTest

import Backend.DEX.Framework
import Backend.DEX.IR
import System

%default covering

private
fail : String -> IO a
fail message = do
  putStrLn ("FAIL: " ++ message)
  exitFailure

private
expect : String -> Bool -> IO ()
expect label True = pure ()
expect label False = fail label

main : IO ()
main = do
  expect "Binder UID returns Int32"
    (framework_descriptor get_calling_uid.result == "I")
  expect "Binder PID returns Int32"
    (framework_descriptor get_calling_pid.result == "I")
  expect "clearCallingIdentity returns long"
    (framework_descriptor clear_calling_identity.result == "J")
  expect "long occupies a register pair"
    (register_width LongValue == Just RegisterPair)
  expect "restoreCallingIdentity consumes long"
    (map framework_descriptor restore_calling_identity.parameters == ["J"])
  expect "ServiceManager.getService returns IBinder"
    (framework_descriptor service_manager_get_service.result ==
      "Landroid/os/IBinder;")
  expect "IBinder.transact returns boolean"
    (framework_descriptor binder_transact.result == "Z")
  expect "forwarding requirement includes wide result"
    (elem MoveResultWide shizuku_forwarding_requirements)
  expect "forwarding requirement includes cleanup"
    (elem TryFinally shizuku_forwarding_requirements)
  putStrLn "PASS: DEX framework/Binder type-plan test"
