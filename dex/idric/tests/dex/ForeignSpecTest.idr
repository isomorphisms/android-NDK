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
    [CFWorld]
    (CFIORes CFInt32)

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
      expect "calling uid remains effectful"
        (foreign.effect == PrimitiveIOForeign)

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

  expect_left "declaring owner must be a class descriptor"
    (parse_dex_foreign "dex:static:I:hashCode:()I" [] CFInt32)

  expect_left "reference parameter rejects forbidden descriptor characters"
    (parse_dex_foreign
      "dex:static:Ljava/lang/Integer;:hashCode:(Lbad[;)I"
      [CFUser (UN (Basic "Opaque")) []] CFInt32)

  expect_left "reference result rejects forbidden descriptor characters"
    (parse_dex_foreign
      "dex:static:Ljava/lang/Object;:factory:()Lbad name;"
      [] (CFUser (UN (Basic "Opaque")) []))

  expect_left "reference descriptor rejects an empty class-name segment"
    (parse_dex_foreign
      "dex:static:Ljava/lang/Object;:factory:()Landroid//os/Parcel;"
      [] (CFUser (UN (Basic "Parcel")) []))

  expect_left "foreign method name cannot contain a class-path separator"
    (parse_dex_foreign
      "dex:static:Ljava/lang/Integer;:bad/name:()I" [] CFInt32)

  expect_left "constructor requires unsupported direct invocation"
    (parse_dex_foreign
      "dex:virtual:Ljava/lang/Object;:<init>:()V"
      [CFUser (UN (Basic "Opaque")) []] CFUnit)

  expect_left "class initializer cannot be an ordinary static invocation"
    (parse_dex_foreign
      "dex:static:Ljava/lang/Object;:<clinit>:()V" [] CFUnit)

  putStrLn "PASS: DEX foreign convention parser"
