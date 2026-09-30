module FrameworkDexGen

import Backend.DEX.Encode
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
identity_round_trip : MethodPlan
identity_round_trip =
  MkMethodPlan "framework-selftest" "calling_identity_round_trip"
    0 [] IntegerValue 5
    [ InvokeMethod
        (Invoke InvokeStatic clear_calling_identity [] (Just (MkRegister 0)))
    , MoveWide (MkRegister 2) (MkRegister 0)
    , InvokeMethod
        (Invoke InvokeStatic restore_calling_identity [MkRegister 2] Nothing)
    , InvokeMethod
        (Invoke InvokeStatic get_calling_uid [] (Just (MkRegister 4)))
    , ReturnInteger (MkRegister 4)
    ]

private
get_package_service : MethodPlan
get_package_service =
  MkMethodPlan "framework-selftest" "get_package_service"
    1 [TextValue] ObjectValue 3
    [ InvokeMethod
        (Invoke InvokeStatic service_manager_get_service
          [MkRegister 2] (Just (MkRegister 0)))
    , ReturnObject (MkRegister 0)
    ]

private
binder_transaction_probe : MethodPlan
binder_transaction_probe =
  MkMethodPlan "framework-selftest" "binder_transaction_probe"
    0 [] IntegerValue 10
    [ TextConstant (MkRegister 0) "package"
    , InvokeMethod
        (Invoke InvokeStatic service_manager_get_service
          [MkRegister 0] (Just (MkRegister 1)))
    , InvokeMethod
        (Invoke InvokeStatic parcel_obtain [] (Just (MkRegister 2)))
    , InvokeMethod
        (Invoke InvokeStatic parcel_obtain [] (Just (MkRegister 3)))
    , IntegerConstant (MkRegister 4) 1598968902
    , IntegerConstant (MkRegister 5) 0
    , InvokeMethod
        (Invoke InvokeStatic clear_calling_identity [] (Just (MkRegister 7)))
    , Mark (MkLabel 0)
    , InvokeMethod
        (Invoke InvokeInterface binder_transact
          [ MkRegister 1
          , MkRegister 4
          , MkRegister 2
          , MkRegister 3
          , MkRegister 5
          ]
          (Just (MkRegister 6)))
    , Mark (MkLabel 1)
    , InvokeMethod
        (Invoke InvokeStatic restore_calling_identity [MkRegister 7] Nothing)
    , Goto (MkLabel 3)
    , Mark (MkLabel 2)
    , MoveException (MkRegister 9)
    , InvokeMethod
        (Invoke InvokeStatic restore_calling_identity [MkRegister 7] Nothing)
    , ThrowException (MkRegister 9)
    , Mark (MkLabel 3)
    , InvokeMethod
        (Invoke InvokeVirtual parcel_recycle [MkRegister 2] Nothing)
    , InvokeMethod
        (Invoke InvokeVirtual parcel_recycle [MkRegister 3] Nothing)
    , ReturnInteger (MkRegister 6)
    , CatchAllRegion (MkLabel 0) (MkLabel 1) (MkLabel 2)
    ]

private
framework_plan : FilePlan
framework_plan =
  MkFilePlan "LIdric/FrameworkProbe;"
    [ identity_round_trip
    , get_package_service
    , binder_transaction_probe
    ]

main : IO ()
main =
  case encode_dex framework_plan of
    Left explanation => fail explanation
    Right bytes => do
      result <- write_dex "build/exec/framework.dex" bytes
      case result of
        Left explanation => fail explanation
        Right () => putStrLn "PASS: wrote typed framework-call DEX"
