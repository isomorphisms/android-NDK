module Backend.DEX.ManagedIORef

import Compiler.ANF
import Core.Name
import Core.Name.Namespace

%default total

||| Only the pinned base library's checked, sequential cell primitives.
||| This is a private managed value facility, not an external cell ABI.
public export
data ManagedIORefOperation = NewCell | ReadCell | WriteCell

public export
managed_ioref_operation : Name -> Maybe ManagedIORefOperation
managed_ioref_operation name =
  if name == NS (mkNamespace "Data.IORef") (UN (Basic "prim__newIORef")) then Just NewCell
  else if name == NS (mkNamespace "Data.IORef") (UN (Basic "prim__readIORef")) then Just ReadCell
  else if name == NS (mkNamespace "Data.IORef") (UN (Basic "prim__writeIORef")) then Just WriteCell
  else Nothing

||| ANF retains the erased polymorphic argument and the explicit World token.
||| Keep the payload/cell arguments in source order; the World is sequenced by
||| checked IO bindings and does not become mutable platform state.
public export
checked_ioref_arguments : Name -> List Administrative_Normal_Form_Variable ->
  Either String (ManagedIORefOperation, List Administrative_Normal_Form_Variable)
checked_ioref_arguments name arguments = case (managed_ioref_operation name, arguments) of
  (Just NewCell, [Administrative_Normal_Form_Erased_Variable, value, world]) =>
    Right (NewCell, [value, world])
  (Just ReadCell, [Administrative_Normal_Form_Erased_Variable, cell, world]) =>
    Right (ReadCell, [cell, world])
  (Just WriteCell, [Administrative_Normal_Form_Erased_Variable, cell, value, world]) =>
    Right (WriteCell, [cell, value, world])
  (Nothing, _) => Left ("Managed DEX unsupported checked external primitive " ++ show name)
  _ => Left ("Managed DEX malformed checked IORef primitive " ++ show name)
