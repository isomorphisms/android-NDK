module Backend.DEX.ManagedRunnable

import Backend.DEX.IR

%default total

private
object_value : FrameworkValueType
object_value = ExistingValue ObjectValue

public export
managed_runnable_type : TypeReference
managed_runnable_type = MkTypeReference "LIdric/Generated$CapturedRunnable;"

private
closure_field : FieldReference
closure_field = MkFieldReference managed_runnable_type "__idric_action" object_value

private
constructor_reference : MethodReference
constructor_reference = MkMethodReference managed_runnable_type "<init>" [object_value] VoidValue

||| A checked IO Unit value has already become a private managed World closure.
||| Keep it per instance; creating the platform callback never executes it.
public export
managed_runnable_factory : String -> MethodPlan
managed_runnable_factory method = MkMethodPlan "checked captured IO Unit Runnable factory"
  method 2 [object_value, object_value] object_value 4
  [ NewObject (MkRegister 0) managed_runnable_type
  , InvokeMethod (Invoke InvokeDirect constructor_reference [MkRegister 0, MkRegister 2] Nothing)
  , ReturnObject (MkRegister 0)
  ]

||| Compiler-private storage and platform dispatch. The action's ordinary ADT,
||| Text and list captures stay in the checked closure representation.
public export
managed_runnable_class : FilePlan
managed_runnable_class = MkFieldClassFilePlan managed_runnable_type.descriptor
  [ MkBoundMethodPlan "captured checked action constructor" "<init>" 1 [object_value] VoidValue 3
      [ InvokeMethod (Invoke InvokeDirect
          (MkMethodReference (MkTypeReference "Ljava/lang/Object;") "<init>" [] VoidValue)
          [MkRegister 1] Nothing)
      , InstancePutObject (MkRegister 2) (MkRegister 1) closure_field
      , ReturnVoid
      ] ConstructorMethod
  , MkBoundMethodPlan "later platform dispatch of captured checked IO Unit" "run" 0 [] VoidValue 4
      [ InstanceGetObject (MkRegister 0) (MkRegister 3) closure_field
      , NullReference (MkRegister 1)
      , InvokeMethod (Invoke InvokeStatic
          (MkMethodReference (MkTypeReference "LIdric/Generated;") "__idricApply"
            [object_value, object_value] object_value)
          [MkRegister 0, MkRegister 1] (Just (MkRegister 2)))
      , ReturnVoid
      ] InstanceMethod
  ]
  [MkFieldPlan "__idric_action" object_value 0x12]
  [MkTypeReference "Ljava/lang/Runnable;"] (MkTypeReference "Ljava/lang/Object;") 0x11
