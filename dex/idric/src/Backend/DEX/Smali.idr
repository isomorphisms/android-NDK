module Backend.DEX.Smali

import Backend.DEX.Encode
import Backend.DEX.IR
import Backend.DEX.Invoke
import Data.String

%default total

private
render_constant : Register -> Int -> String
render_constant destination value =
  if destination.number <= 15 && value >= -8 && value <= 7
    then "const/4 " ++ show destination ++ ", " ++ show value
    else if value >= -32768 && value <= 32767
      then "const/16 " ++ show destination ++ ", " ++ show value
      else "const " ++ show destination ++ ", " ++ show value

private
render_move_with : String -> Register -> Register -> String
render_move_with stem destination source =
  if destination.number <= 15 && source.number <= 15
    then stem ++ " " ++ show destination ++ ", " ++ show source
    else if destination.number <= 255
      then stem ++ "/from16 " ++ show destination ++ ", " ++ show source
      else stem ++ "/16 " ++ show destination ++ ", " ++ show source

private
hex_digit : Int -> Char
hex_digit digit = chr (if digit < 10 then ord '0' + digit else ord 'a' + digit - 10)

-- Rendering raw LF/CR/quotes here made the evidence unassemblable even
-- though the binary was valid. Preserve every currently supported ASCII
-- literal exactly, including control characters and backslashes.
private
escape_literal_character : Char -> String
escape_literal_character '\\' = "\\\\"
escape_literal_character '"' = "\\\""
escape_literal_character '\n' = "\\n"
escape_literal_character '\r' = "\\r"
escape_literal_character '\t' = "\\t"
escape_literal_character character =
  let code = ord character in
  if code < 32 || code == 127
    then pack ['\\', 'u', '0', '0', hex_digit (code `div` 16), hex_digit (code `mod` 16)]
    else strCons character ""

private
render_literal : String -> String
render_literal value = "\"" ++ concat (map escape_literal_character (unpack value)) ++ "\""

private
render_instruction : Instruction -> String
render_instruction (Move destination source) =
  render_move_with "move" destination source
render_instruction (MoveWide destination source) =
  render_move_with "move-wide" destination source
render_instruction (MoveObject destination source) =
  render_move_with "move-object" destination source
render_instruction (IntegerConstant destination value) =
  render_constant destination value
render_instruction (NullReference destination) =
  render_constant destination 0
render_instruction (TextConstant destination value) =
  "const-string " ++ show destination ++ ", " ++ render_literal value
render_instruction (CheckCast register target) =
  "check-cast " ++ show register ++ ", " ++ target.descriptor
render_instruction (IntegerBinary operation destination left right) =
  show operation ++ " " ++ show destination ++ ", " ++
  show left ++ ", " ++ show right
render_instruction (TextEqual destination left right) =
  let range = left.number > 15 || right.number > 15
      opcode = if range then "invoke-virtual/range" else "invoke-virtual"
      separator = if range then " .. " else ", "
  in opcode ++ " {" ++ show left ++ separator ++ show right ++
     "}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z\n    move-result " ++
     show destination
render_instruction (InvokeMethod invocation) =
  let registers =
        case invocation_register_words invocation of
          Left explanation => invocation.arguments
          Right words => words
      call =
        case invocation_format invocation of
          Right Format3rc =>
            show invocation.kind ++ "/range {" ++ render_range registers ++ "}, " ++
            show invocation.method
          _ =>
            show invocation.kind ++ " {" ++ render_registers registers ++ "}, " ++
            show invocation.method
  in call ++ render_result invocation.method.result invocation.result_register
  where
    render_registers : List Register -> String
    render_registers [] = ""
    render_registers [register] = show register
    render_registers (register :: rest) =
      show register ++ ", " ++ render_registers rest

    render_range : List Register -> String
    render_range [] = ""
    render_range (register :: rest) =
      show register ++ " .. v" ++ show (register.number + cast (length rest))

    render_result : FrameworkValueType -> Maybe Register -> String
    render_result result Nothing = ""
    render_result LongValue (Just register) =
      "\n    move-result-wide " ++ show register
    render_result (ExistingValue DoubleValue) (Just register) =
      "\n    move-result-wide " ++ show register
    render_result (ReferenceValue reference) (Just register) =
      "\n    move-result-object " ++ show register
    render_result (ExistingValue TextValue) (Just register) =
      "\n    move-result-object " ++ show register
    render_result (ExistingValue ObjectValue) (Just register) =
      "\n    move-result-object " ++ show register
    render_result (ExistingValue value) (Just register) =
      "\n    move-result " ++ show register
    render_result result register = " # invalid-result-plan"
render_instruction (IntegerBranch condition left right target) =
  show condition ++ " " ++ show left ++ ", " ++ show right ++ ", " ++ show target
render_instruction (Goto target) = "goto " ++ show target
render_instruction (Goto16 target) = "goto/16 " ++ show target
render_instruction (Goto32 target) = "goto/32 " ++ show target
render_instruction (Mark label) = show label
render_instruction (ReturnInteger register) = "return " ++ show register
render_instruction (ReturnObject register) = "return-object " ++ show register
render_instruction (ReturnWide register) = "return-wide " ++ show register
render_instruction ReturnVoid = "return-void"

private
parameter_descriptor : List FrameworkValueType -> String
parameter_descriptor = concat . map framework_descriptor

private
render_method : MethodPlan -> String
render_method method =
  let access = case method.mode of
        StaticMethod => "public static "
        InstanceMethod => "public "
        ConstructorMethod => "public constructor "
        ClassInitializerMethod => "static constructor "
        NativeStaticMethod => "public static native "
        NativeInstanceMethod => "public native "
        ProtectedInstanceMethod => "protected "
  in
  unlines
    ([ ".method " ++ access ++ method.method_name ++
       "(" ++ parameter_descriptor method.parameter_types ++ ")" ++
       framework_descriptor method.result_type
     ] ++ (if native_method method.mode then [] else
       ["    .registers " ++ show method.register_count, ""]) ++
     map render_line method.instructions ++
     [ ".end method", "" ])
  where
    render_line : Instruction -> String
    render_line instruction@(Mark _) = render_instruction instruction
    render_line instruction = "    " ++ render_instruction instruction

||| No placement or relaxation occurs here. The compiler passes the same
||| finalized value to this renderer, its plan writer, and binary emission.
export
render_finalized_smali : FinalizedFilePlan -> String
render_finalized_smali finalized =
  let plan = finalized_plan finalized in
  unlines
    [ (if plan.access_flags == 1 then ".class public " else ".class public final ") ++ plan.class_descriptor
    , ".super " ++ plan.superclass.descriptor
    , ""
    ] ++ unlines (map (\implemented => ".implements " ++ show implemented) plan.interfaces) ++
    concat (map render_method plan.methods)

-- Compatibility API invokes the encoder's bounded layout pass; rendering
-- an already finalized plan above remains a structurally total operation.
%default covering

public export
render_smali : FilePlan -> String
render_smali plan =
  case finalize_file_plan plan of
    Left explanation => "# Invalid DEX method plan: " ++ explanation ++ "\n"
    Right finalized => render_finalized_smali finalized
