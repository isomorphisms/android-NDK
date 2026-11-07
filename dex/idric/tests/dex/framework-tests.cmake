cmake_minimum_required(VERSION 3.22)
foreach(required IDRIC IDRIC_SUPPORT SCHEME)
  if(NOT DEFINED ${required} OR NOT EXISTS "${${required}}")
    message(FATAL_ERROR "Missing ${required}")
  endif()
endforeach()
set(environment "IDRIS2_PATH=${CMAKE_CURRENT_SOURCE_DIR}/build/ttc:${IDRIC_SUPPORT}/libs/prelude/build/ttc:${IDRIC_SUPPORT}/libs/base/build/ttc"
  "IDRIS2_DATA=${IDRIC_SUPPORT}/support" "IDRIS2_LIBS=${IDRIC_SUPPORT}/support/chez" "CHEZ=${SCHEME}"
  "LD_LIBRARY_PATH=${IDRIC_SUPPORT}/support/c")
function(run)
  execute_process(COMMAND ${ARGV} RESULT_VARIABLE result)
  if(NOT result EQUAL 0)
    message(FATAL_ERROR "Framework class verification failed: ${ARGV}")
  endif()
endfunction()
file(MAKE_DIRECTORY build)
file(REMOVE build/exec/framework-class-test build/framework-test.dex)
run("${CMAKE_COMMAND}" -E env ${environment} "${IDRIC}" --source-dir src
  --check src/Backend/DEX/FrameworkClasses.idr)
run("${CMAKE_COMMAND}" -E env ${environment} "${IDRIC}" --source-dir tests/dex
  tests/dex/FrameworkClassesTest.idr -o framework-class-test)
run("${CMAKE_COMMAND}" -E env ${environment} build/exec/framework-class-test)
file(REMOVE build/exec/framework-interfaces-test build/framework-interface.dex)
run("${CMAKE_COMMAND}" -E env ${environment} "${IDRIC}" --source-dir tests/dex
  tests/dex/FrameworkInterfacesTest.idric -o framework-interfaces-test)
run("${CMAKE_COMMAND}" -E env ${environment} build/exec/framework-interfaces-test)
file(DOWNLOAD https://github.com/baksmali/smali/releases/download/3.0.10/baksmali-3.0.10-fat-release.jar
  build/baksmali-3.0.10.jar
  EXPECTED_HASH SHA256=37ae4a41a8886e15c20b8362fa4250f96bbdb55e1a608199ad8b5dff068b588f)
file(REMOVE_RECURSE build/framework-test-disassembly)
run(java -jar build/baksmali-3.0.10.jar disassemble build/framework-test.dex -o build/framework-test-disassembly)
file(READ build/framework-test-disassembly/example/Callback.smali disassembly)
foreach(required ".super Ljava/lang/Object;" ".method public constructor <init>()V"
    ".method static constructor <clinit>()V" ".method public native answer(ILjava/lang/String;)I"
    "Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V")
  string(FIND "${disassembly}" "${required}" found)
  if(found EQUAL -1)
    message(FATAL_ERROR "Independent DEX decode missing ${required}")
  endif()
endforeach()
run(java -jar build/baksmali-3.0.10.jar disassemble build/framework-interface.dex -o build/framework-interface-disassembly)
file(READ build/framework-interface-disassembly/example/Listener.smali interface_disassembly)
foreach(required ".implements Landroid/view/View$OnClickListener;" ".method public native onClick(Landroid/view/View;)V")
  string(FIND "${interface_disassembly}" "${required}" found)
  if(found EQUAL -1)
    message(FATAL_ERROR "Independent interface DEX decode missing ${required}")
  endif()
endforeach()
file(SHA256 build/framework-test.dex digest)
file(WRITE build/framework-class-receipt.txt
  "typed_class_plan PASS\ndeterministic_output PASS\nnegative_cases 8 PASS\nindependent_decode PASS\nDEX_SHA256 ${digest}\nART NOT_RUN\nphysical_device NOT_RUN\n")
