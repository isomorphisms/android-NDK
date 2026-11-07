module Backend.DEX.Capabilities

import Backend.DEX.IR
import Compiler.ANF
import Core.CompileExpr
import Core.Name
import Data.List
import Data.String

%default covering

||| A receipt describes source requirements, not a promise that every primitive
||| in a family is supported. Lowering still validates each checked operation.
public export
record RuntimeRequirement where
  constructor RequiresRuntime
  facility : String
  requested_by : String

private
require : String -> Name -> List RuntimeRequirement
require facility name = [RequiresRuntime facility (show name)]

mutual
  private
  expression_requirements : Name -> Administrative_Normal_Form -> List RuntimeRequirement
  expression_requirements name (Administrative_Normal_Form_Binding _ _ value body) =
    expression_requirements name value ++ expression_requirements name body
  expression_requirements name (Administrative_Normal_Form_Constructor_Value {}) = require "managed-values" name
  expression_requirements name (Administrative_Normal_Form_Partial_Application {}) = require "closures" name
  expression_requirements name (Administrative_Normal_Form_Closure_Application {}) = require "closures" name
  expression_requirements name (Administrative_Normal_Form_Constructor_Case _ _ alternatives fallback) =
    require "managed-values" name ++ concatMap (constructor_requirements name) alternatives ++
    maybe [] (expression_requirements name) fallback
  expression_requirements name (Administrative_Normal_Form_Constant_Case _ _ alternatives fallback) =
    concatMap (constant_requirements name) alternatives ++ maybe [] (expression_requirements name) fallback
  expression_requirements name _ = []

  private
  constructor_requirements : Name -> Administrative_Normal_Form_Constructor_Alternative -> List RuntimeRequirement
  constructor_requirements name (Make_Administrative_Normal_Form_Constructor_Alternative _ _ _ _ body) =
    expression_requirements name body

  private
  constant_requirements : Name -> Administrative_Normal_Form_Constant_Alternative -> List RuntimeRequirement
  constant_requirements name (Make_Administrative_Normal_Form_Constant_Alternative _ body) =
    expression_requirements name body

private
foreign_requirements : Name -> List String -> List RuntimeRequirement
foreign_requirements name conventions =
  if elem "C:idris2_getArgCount, libidris2_support, idris_support.h" conventions ||
     elem "C:idris2_getArg, libidris2_support, idris_support.h" conventions
    then require "arguments" name
  else if elem "C:idris2_putStr, libidris2_support, idris_support.h" conventions
    then require "standard-output" name
  else if elem "C:exit, libc 6" conventions then require "process-exit" name
  else if elem "scheme:string-unpack" conventions then require "unicode-unpack" name
  else if elem "scheme:string-pack" conventions then require "unicode-pack" name
  else require "foreign-boundary" name

public export
checked_runtime_requirements : List (Name, Administrative_Normal_Form_Definition) -> List RuntimeRequirement
checked_runtime_requirements = concatMap requirements
  where
    requirements : (Name, Administrative_Normal_Form_Definition) -> List RuntimeRequirement
    requirements (name, Make_Administrative_Normal_Form_Function _ body) = expression_requirements name body
    requirements (name, Make_Administrative_Normal_Form_Foreign_Function conventions _ _) =
      foreign_requirements name conventions
    requirements _ = []

mutual
  private
  captured_targets : Administrative_Normal_Form -> List Name
  captured_targets (Administrative_Normal_Form_Partial_Application _ name _ _) = [name]
  captured_targets (Administrative_Normal_Form_Binding _ _ value body) = captured_targets value ++ captured_targets body
  captured_targets (Administrative_Normal_Form_Constructor_Case _ _ alternatives fallback) =
    concatMap captured_constructor_targets alternatives ++ maybe [] captured_targets fallback
  captured_targets (Administrative_Normal_Form_Constant_Case _ _ alternatives fallback) =
    concatMap captured_constant_targets alternatives ++ maybe [] captured_targets fallback
  captured_targets _ = []

  private
  captured_constructor_targets : Administrative_Normal_Form_Constructor_Alternative -> List Name
  captured_constructor_targets (Make_Administrative_Normal_Form_Constructor_Alternative _ _ _ _ body) = captured_targets body

  private
  captured_constant_targets : Administrative_Normal_Form_Constant_Alternative -> List Name
  captured_constant_targets (Make_Administrative_Normal_Form_Constant_Alternative _ body) = captured_targets body

||| Managed heap values cannot enter through the public scalar/opaque ABI.
||| Every admitted closure therefore originates in a checked partial application.
||| Inspect all reachable branches, not only branches executed on the host.
public export
checked_closure_targets : List (Name, Administrative_Normal_Form_Definition) -> List Name
checked_closure_targets definitions = nub (concatMap targets definitions)
  where
    targets : (Name, Administrative_Normal_Form_Definition) -> List Name
    targets (_, Make_Administrative_Normal_Form_Function _ body) = captured_targets body
    targets _ = []

public export
needs_runtime_arguments : List RuntimeRequirement -> Bool
needs_runtime_arguments = any (\requirement => requirement.facility == "arguments")

private
instruction_targets : String -> Instruction -> List String
instruction_targets owner (InvokeMethod invocation) =
  if invocation.method.owner.descriptor == owner then [invocation.method.name] else []
instruction_targets _ _ = []

||| A helper omitted from the library is a compile-time error, never a missing
||| generated method discovered only when ART links an otherwise valid file.
public export
validate_runtime_dependencies : String -> List MethodPlan -> Either String ()
validate_runtime_dependencies owner methods = traverse_ validate methods
  where
    validate : MethodPlan -> Either String ()
    validate method = traverse_ (check_target method.method_name)
      (concatMap (instruction_targets owner) method.instructions)
      where
        check_target : String -> String -> Either String ()
        check_target caller target =
          if any (\candidate => candidate.method_name == target) methods then Right ()
            else Left ("Runtime dependency " ++ caller ++ " -> " ++ target ++ " has no generated method")

||| Traverse generated calls as well as source calls. This retains transitive
||| dependencies such as Char -> checked narrowing; unknown external owners are
||| never rewritten or used as evidence to remove their runtime dependencies.
public export
retain_reachable_methods : String -> List String -> List MethodPlan -> List MethodPlan
retain_reachable_methods owner roots methods =
  let retained = walk roots [] in filter (\method => elem method.method_name retained) methods
  where
    walk : List String -> List String -> List String
    walk [] visited = visited
    walk (name :: pending) visited =
      if elem name visited then walk pending visited else
      case find (\method => method.method_name == name) methods of
        Nothing => walk pending (name :: visited)
        Just method => walk (pending ++ concatMap (instruction_targets owner) method.instructions) (name :: visited)

public export
render_runtime_requirements : String -> List RuntimeRequirement -> List MethodPlan -> String
render_runtime_requirements route requirements methods =
  "route\t" ++ route ++ "\n" ++
  unlines (nub (map (\requirement => "capability\t" ++ requirement.facility ++ "\t" ++ requirement.requested_by) requirements)) ++
  concatMap (\method => "method\t" ++ method.method_name ++ "\n") methods
