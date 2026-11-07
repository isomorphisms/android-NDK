module Backend.DEX.ValueLayout

import Backend.DEX.IR
import Data.List

%default total

||| Private managed storage layouts. These do not describe an external ABI or
||| recover source field types which checked ANF has already erased.
public export
data ManagedValueKind = ConstructorNode | ClosureNode

public export
record ManagedValueLayout where
  constructor MakeManagedValueLayout
  value_kind : ManagedValueKind
  identity : String
  payload_count : Nat
  total_arity : Nat
  remaining_arity : Nat

public export
managed_node_type : TypeReference
managed_node_type = MkTypeReference "Ljava/util/ArrayList;"

public export
managed_tag_slot : Int
managed_tag_slot = 0

public export
managed_node_slots : ManagedValueLayout -> Int
managed_node_slots layout = 1 + cast layout.payload_count

||| All payloads in this ANF slice are erased managed references. This makes
||| the storage decision explicit without inventing source primitive fields.
public export
managed_payload_storage_types : ManagedValueLayout -> List FrameworkValueType
managed_payload_storage_types layout = replicate layout.payload_count (ExistingValue ObjectValue)

||| Payload order is shared by constructor creation and case projection.
public export
managed_field_slots : ManagedValueLayout -> List Int
managed_field_slots layout = map ((+ 1) . cast) (indices layout.payload_count)
  where
    indices : Nat -> List Nat
    indices Z = []
    indices (S count) = 0 :: map S (indices count)

public export
checked_constructor_layout : String -> Nat -> Either String ManagedValueLayout
checked_constructor_layout tag count =
  if tag == "" then Left "Managed DEX constructor identity is empty"
    else Right (MakeManagedValueLayout ConstructorNode tag count 0 0)

public export
checked_closure_layout : String -> Int -> Nat -> Nat -> Either String ManagedValueLayout
checked_closure_layout target arity captured missing =
  if target == "" then Left "Managed DEX closure target is empty"
    else if arity <= 0 then Left "Managed DEX closure target has no parameters"
    else if missing == 0 then Left "Managed DEX partial application has no missing arguments"
    else if cast (captured + missing) /= arity
      then Left ("Managed DEX closure arity mismatch " ++ target)
      else Right (MakeManagedValueLayout ClosureNode target captured (cast arity) missing)

||| Validate the actual emission inputs, rather than trusting a separately
||| calculated payload count. The returned list keeps the checked input order.
public export
checked_node_fields : ManagedValueLayout -> List a -> Either String (List a)
checked_node_fields layout fields =
  if length fields == layout.payload_count then Right fields
    else Left ("Managed DEX payload count mismatch " ++ layout.identity)
