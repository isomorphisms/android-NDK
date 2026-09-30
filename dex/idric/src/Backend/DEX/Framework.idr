module Backend.DEX.Framework

import Backend.DEX.IR

%default total

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
  = NeedsInvokeMethod
  | NeedsMoveResult
  | NeedsMoveResultObject
  | NeedsMoveResultWide
  | NeedsMoveWide
  | NeedsCatchAllHandler
  | NeedsMoveException
  | NeedsThrowException

public export
shizuku_forwarding_requirements : List RequiredInstructionFamily
shizuku_forwarding_requirements =
  [ NeedsInvokeMethod
  , NeedsMoveResult
  , NeedsMoveResultObject
  , NeedsMoveResultWide
  , NeedsMoveWide
  , NeedsCatchAllHandler
  , NeedsMoveException
  , NeedsThrowException
  ]

||| clearCallingIdentity returns an opaque Java long token. It is a two-register
||| target value, not permission to widen Idriç's ordinary numeric semantics.
||| The first broker slice only has to retain it unchanged until
||| restoreCallingIdentity consumes it.
public export
data CallingIdentityTokenUse
  = PreserveOpaqueLong

||| Death recipients require generated callback/interface objects and are a
||| later class-model slice, not a reason to make the first forwarding patch
||| unbounded.
public export
data LaterBinderRequirement
  = GeneratedBinderSubclass
  | GeneratedDeathRecipient
  | InstanceField
  | ConstructorCall
