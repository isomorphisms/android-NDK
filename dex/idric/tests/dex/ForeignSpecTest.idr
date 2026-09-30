module ForeignSpecTest

import Backend.DEX.Foreign
import Backend.DEX.IR
import Compiler.ANF
import Core.CompileExpr
import Core.Name
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

private
expect_left : String -> Either String value -> IO ()
expect_left label (Left explanation) = pure ()
expect_left label (Right value) = fail (label ++ ": invalid foreign spec was accepted")

private
calling_uid :
  Either String DEXForeign
calling_uid =
  parse_dex_foreign
    "dex:static:Landroid/os/Binder;:getCallingUid:()I"
    []
    CFInt32

private
restore_identity :
  Either String DEXForeign
restore_identity =
  parse_dex_foreign
    "dex:static:Landroid/os/Binder;:restoreCallingIdentity:(J)V"
    [CFInt64, CFWorld]
    (CFIORes CFUnit)

private
transact :
  Either String DEXForeign
transact =
  parse_dex_foreign
    "dex:interface:Landroid/os/IBinder;:transact:(ILandroid/os/Parcel;Landroid/os/Parcel;I)Z"
    [ CFUser (UN (Basic "Binder")) []
    , CFInt32
    , CFUser (UN (Basic "Parcel")) []
    , CFUser (UN (Basic "Parcel")) []
    , CFInt32
    ]
    CFInt32

main : IO ()
main = do
  case calling_uid of
    Left explanation => fail explanation
    Right foreign => do
      expect "calling uid is static" (foreign.invocation_kind == InvokeStatic)
      expect "calling uid result descriptor"
        (method_descriptor foreign.method == "()I")
      expect "calling uid is pure declaration"
        (foreign.effect == PureForeign)

  case restore_identity of
    Left explanation => fail explanation
    Right foreign => do
      expect "restore identity descriptor"
        (method_descriptor foreign.method == "(J)V")
      expect "PrimIO world is recognized"
        (foreign.effect == PrimitiveIOForeign)

  case transact of
    Left explanation => fail explanation
    Right foreign => do
      expect "transact is interface invoke"
        (foreign.invocation_kind == InvokeInterface)
      expect "transact descriptor"
        (method_descriptor foreign.method ==
          "(ILandroid/os/Parcel;Landroid/os/Parcel;I)Z")

  expect_left "virtual call requires receiver"
    (parse_dex_foreign
      "dex:virtual:Landroid/os/Parcel;:recycle:()V"
      [CFWorld]
      (CFIORes CFUnit))

  expect_left "wide target rejects Int32 source"
    (parse_dex_foreign
      "dex:static:Landroid/os/Binder;:restoreCallingIdentity:(J)V"
      [CFInt32]
      CFUnit)

  expect_left "arrays are deliberately outside first slice"
    (parse_dex_foreign
      "dex:static:Lexample/Foo;:take:([I)V"
      [CFUser (UN (Basic "Array")) []]
      CFUnit)

  putStrLn "PASS: DEX foreign convention parser"
