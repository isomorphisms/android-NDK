module Backend.DEX.ManagedExceptions

import Backend.DEX.IR

%default total

private
object_value : FrameworkValueType
object_value = ExistingValue ObjectValue

private
apply_action : Register -> Register -> Register -> Instruction
apply_action action argument result = InvokeMethod (Invoke InvokeStatic
  (MkMethodReference (MkTypeReference "LIdric/Generated;") "__idricApply"
    [object_value, object_value] object_value)
  [action, argument] (Just result))

||| The handler receives the actual JVM Throwable, then its actual IO closure
||| is applied to this call's World. Handler exceptions are outside the region.
public export
managed_catch_io_unit : String -> MethodPlan
managed_catch_io_unit method = MkMethodPlan "checked IO Unit catch" method
  3 [object_value, object_value, object_value] object_value 8
  [ Mark (MkLabel 0)
  , apply_action (MkRegister 5) (MkRegister 7) (MkRegister 0)
  , Mark (MkLabel 1)
  , ReturnObject (MkRegister 0)
  , Mark (MkLabel 2)
  , MoveException (MkRegister 1)
  , apply_action (MkRegister 6) (MkRegister 1) (MkRegister 2)
  , apply_action (MkRegister 2) (MkRegister 7) (MkRegister 0)
  , ReturnObject (MkRegister 0)
  , CatchRegion (MkTypeReference "Ljava/lang/Throwable;") (MkLabel 0) (MkLabel 1) (MkLabel 2)
  ]

||| Ordinary finally semantics: cleanup runs once. If both actions throw, the
||| cleanup exception replaces the first; resource suppression is source-owned.
public export
managed_finally_io_unit : String -> MethodPlan
managed_finally_io_unit method = MkMethodPlan "checked IO Unit finally" method
  3 [object_value, object_value, object_value] object_value 8
  [ Mark (MkLabel 0)
  , apply_action (MkRegister 5) (MkRegister 7) (MkRegister 0)
  , Mark (MkLabel 1)
  , apply_action (MkRegister 6) (MkRegister 7) (MkRegister 0)
  , ReturnObject (MkRegister 0)
  , Mark (MkLabel 2)
  , MoveException (MkRegister 1)
  , apply_action (MkRegister 6) (MkRegister 7) (MkRegister 0)
  , ThrowObject (MkRegister 1)
  , CatchRegion (MkTypeReference "Ljava/lang/Throwable;") (MkLabel 0) (MkLabel 1) (MkLabel 2)
  ]

public export
managed_throw_throwable : String -> MethodPlan
managed_throw_throwable method = MkMethodPlan "checked Throwable rethrow" method
  2 [object_value, object_value] object_value 3
  [ CheckCast (MkRegister 1) (MkTypeReference "Ljava/lang/Throwable;")
  , ThrowObject (MkRegister 1)
  ]
