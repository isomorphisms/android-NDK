module FrameworkInvokeTest

import Backend.DEX.Framework
import Backend.DEX.Invoke
import Backend.DEX.IR
import System

%default covering

private
fail : String -> IO a
fail message = do
  putStrLn ("FAIL: " ++ message)
  exitFailure

private
expect_equal : Eq value => Show value => String -> value -> value -> IO ()
expect_equal label expected actual =
  if expected == actual
    then pure ()
    else fail (label ++ ": expected " ++ show expected ++ ", got " ++ show actual)

private
expect_left : String -> Either String value -> IO ()
expect_left label (Left explanation) = pure ()
expect_left label (Right value) = fail (label ++ ": invalid invocation was accepted")

private
calling_uid : InvocationPlan
calling_uid =
  Invoke InvokeStatic get_calling_uid [] (Just (MkRegister 3))

private
clear_identity : InvocationPlan
clear_identity =
  Invoke InvokeStatic clear_calling_identity [] (Just (MkRegister 4))

private
restore_identity : InvocationPlan
restore_identity =
  Invoke InvokeStatic restore_calling_identity [MkRegister 2] Nothing

private
transact : InvocationPlan
transact =
  Invoke InvokeInterface binder_transact
    [ MkRegister 0
    , MkRegister 1
    , MkRegister 2
    , MkRegister 3
    , MkRegister 4
    ]
    (Just (MkRegister 5))

private
bad_wide : InvocationPlan
bad_wide =
  Invoke InvokeStatic restore_calling_identity [MkRegister 15] Nothing

main : IO ()
main = do
  expect_equal "invoke-static getCallingUid + move-result"
    [0x71, 0x00, 0x23, 0x01, 0x00, 0x00, 0x0a, 0x03]
    !(pure (either (const []) id (encode_invoke_35c 0x0123 calling_uid)))

  expect_equal "invoke-static clearCallingIdentity + move-result-wide"
    [0x71, 0x00, 0x24, 0x01, 0x00, 0x00, 0x0b, 0x04]
    !(pure (either (const []) id (encode_invoke_35c 0x0124 clear_identity)))

  expect_equal "restoreCallingIdentity expands long to two register words"
    [0x71, 0x20, 0x25, 0x01, 0x32, 0x00]
    !(pure (either (const []) id (encode_invoke_35c 0x0125 restore_identity)))

  expect_equal "IBinder.transact fills all five 35c argument words"
    [0x72, 0x54, 0x26, 0x01, 0x10, 0x32, 0x0a, 0x05]
    !(pure (either (const []) id (encode_invoke_35c 0x0126 transact)))

  expect_left "wide argument starting at v15 crosses 35c register limit"
    (encode_invoke_35c 0 bad_wide)

  expect_left "method index exceeds 16 bits"
    (encode_invoke_35c 65536 calling_uid)

  putStrLn "PASS: DEX framework invoke 35c test"
