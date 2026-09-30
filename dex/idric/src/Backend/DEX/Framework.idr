module Backend.DEX.Framework

import Backend.DEX.IR

%default total

||| A validated DEX type descriptor such as Landroid/os/IBinder;.
||| Validation/encoding belongs to the DEX backend; application code should use
||| semantic names above this target layer.
public export
record TypeReference where
  constructor MkTypeReference
  descriptor : String

public export
Eq TypeReference where
  (MkTypeReference left) == (MkTypeReference right) = left == right

public export
Show TypeReference where
  show reference = reference.descriptor

||| DEX register-width class. Long/double values occupy a consecutive register
||| pair even though the source language should not expose that placement.
public export
data RegisterWidth
  = SingleRegister
  | RegisterPair

public export
data FrameworkValueType
  = ExistingValue ValueType
  | ReferenceValue TypeReference
  | LongValue
  | VoidValue

public export
Eq FrameworkValueType where
  (ExistingValue left) == (ExistingValue right) = left == right
  (ReferenceValue left) == (ReferenceValue right) = left == right
  LongValue == LongValue = True
  VoidValue == VoidValue = True
  _ == _ = False

public export
register_width : FrameworkValueType -> Maybe RegisterWidth
register_width VoidValue = Nothing
register_width LongValue = Just RegisterPair
register_width _ = Just SingleRegister

public export
framework_descriptor : FrameworkValueType -> String
framework_descriptor (ExistingValue value) = value_descriptor value
framework_descriptor (ReferenceValue reference) = reference.descriptor
framework_descriptor LongValue = "J"
framework_descriptor VoidValue = "V"

private
parameter_descriptors : List FrameworkValueType -> String
parameter_descriptors [] = ""
parameter_descriptors (value :: rest) =
  framework_descriptor value ++ parameter_descriptors rest

public export
record MethodReference where
  constructor MkMethodReference
  owner : TypeReference
  name : String
  parameters : List FrameworkValueType
  result : FrameworkValueType

public export
method_descriptor : MethodReference -> String
method_descriptor method =
  "(" ++ parameter_descriptors method.parameters ++ ")" ++
  framework_descriptor method.result

public export
data InvokeKind
  = InvokeStatic
  | InvokeVirtual
  | InvokeInterface

public export
Show InvokeKind where
  show InvokeStatic = "invoke-static"
  show InvokeVirtual = "invoke-virtual"
  show InvokeInterface = "invoke-interface"

||| A target plan for one framework invocation. The ordinary checked-ANF lowerer
||| does not emit this yet; this type makes the missing target semantics
||| inspectable before encoder work starts.
public export
record InvocationPlan where
  constructor Invoke
  kind : InvokeKind
  method : MethodReference
  arguments : List Register
  result_register : Maybe Register

public export
android_binder : TypeReference
android_binder = MkTypeReference "Landroid/os/Binder;"

public export
android_ibinder : TypeReference
android_ibinder = MkTypeReference "Landroid/os/IBinder;"

public export
android_parcel : TypeReference
android_parcel = MkTypeReference "Landroid/os/Parcel;"

public export
android_service_manager : TypeReference
android_service_manager = MkTypeReference "Landroid/os/ServiceManager;"

public export
get_calling_uid : MethodReference
get_calling_uid =
  MkMethodReference android_binder "getCallingUid" []
    (ExistingValue IntegerValue)

public export
get_calling_pid : MethodReference
get_calling_pid =
  MkMethodReference android_binder "getCallingPid" []
    (ExistingValue IntegerValue)

public export
clear_calling_identity : MethodReference
clear_calling_identity =
  MkMethodReference android_binder "clearCallingIdentity" [] LongValue

public export
restore_calling_identity : MethodReference
restore_calling_identity =
  MkMethodReference android_binder "restoreCallingIdentity" [LongValue] VoidValue

public export
service_manager_get_service : MethodReference
service_manager_get_service =
  MkMethodReference android_service_manager "getService"
    [ExistingValue TextValue]
    (ReferenceValue android_ibinder)

public export
parcel_obtain : MethodReference
parcel_obtain =
  MkMethodReference android_parcel "obtain" []
    (ReferenceValue android_parcel)

public export
parcel_recycle : MethodReference
parcel_recycle =
  MkMethodReference android_parcel "recycle" [] VoidValue

public export
parcel_data_position : MethodReference
parcel_data_position =
  MkMethodReference android_parcel "dataPosition" []
    (ExistingValue IntegerValue)

public export
parcel_data_available : MethodReference
parcel_data_available =
  MkMethodReference android_parcel "dataAvail" []
    (ExistingValue IntegerValue)

public export
parcel_append_from : MethodReference
parcel_append_from =
  MkMethodReference android_parcel "appendFrom"
    [ ReferenceValue android_parcel
    , ExistingValue IntegerValue
    , ExistingValue IntegerValue
    ]
    VoidValue

public export
binder_ping : MethodReference
binder_ping =
  MkMethodReference android_ibinder "pingBinder" []
    (ExistingValue BooleanValue)

public export
binder_transact : MethodReference
binder_transact =
  MkMethodReference android_ibinder "transact"
    [ ExistingValue IntegerValue
    , ReferenceValue android_parcel
    , ReferenceValue android_parcel
    , ExistingValue IntegerValue
    ]
    (ExistingValue BooleanValue)

||| Minimum DEX instruction families required to lower the Shizuku forwarding
||| slice. This is a capability inventory, not an instruction encoding.
public export
data RequiredInstructionFamily
  = InvokeMethod
  | MoveResult
  | MoveResultObject
  | MoveResultWide
  | MoveWide
  | CatchAllHandler
  | MoveException
  | ThrowException

public export
shizuku_forwarding_requirements : List RequiredInstructionFamily
shizuku_forwarding_requirements =
  [ InvokeMethod
  , MoveResult
  , MoveResultObject
  , MoveResultWide
  , MoveWide
  , CatchAllHandler
  , MoveException
  , ThrowException
  ]

||| clearCallingIdentity returns an opaque Java long token. It is a two-register
||| target value, not permission to widen Idriç's ordinary numeric semantics.
||| The first broker slice only has to retain it unchanged until
||| restoreCallingIdentity consumes it.
public export
data CallingIdentityTokenUse
  = PreserveOpaqueLong

||| The first compiler extension should stop at this boundary. Death recipients
||| require generated callback/interface objects and are a later class-model
||| slice, not a reason to make the first forwarding patch unbounded.
public export
data LaterBinderRequirement
  = GeneratedBinderSubclass
  | GeneratedDeathRecipient
  | InstanceField
  | ConstructorCall
