IDRIC ?= idris2
IDRIC_REPO ?= $(CURDIR)/Idric
IDRIC_COMPILER_REF ?= Idriç

BACKEND_SOURCES := $(wildcard src/Backend/DEX/*.idr) backend.ipkg
DRIVER := build/exec/idric-dex
IDRIC_RUNTIME_LIBRARY ?= $(dir $(IDRIC))idris2_app/libidris2_support.so
DEX_SOURCE := examples/DexArithmetic.idric
DEX_FILE := build/exec/classes.dex
DEX_CHECKED_ANF := build/exec/classes.checked.anf
DEX_PLAN := build/exec/classes.dex.plan
DEX_SMALI := build/exec/classes.smali
DEX_REPEAT_FILE := build/exec/classes-repeat.dex
DEX_TEXT_SOURCE := examples/DexText.idric
DEX_TEXT_FILE := build/exec/text.dex
DEX_TEXT_CHECKED_ANF := build/exec/text.checked.anf
DEX_TEXT_PLAN := build/exec/text.dex.plan
DEX_TEXT_SMALI := build/exec/text.smali
DEX_FOREIGN_SOURCE := examples/DexForeign.idric
DEX_FOREIGN_FILE := build/exec/foreign.dex
DEX_FOREIGN_CHECKED_ANF := build/exec/foreign.checked.anf
DEX_FOREIGN_PLAN := build/exec/foreign.dex.plan
DEX_FOREIGN_SMALI := build/exec/foreign.smali
DEX_FOREIGN_DISASSEMBLY := build/exec/baksmali-foreign/Idric/Generated.smali
DEX_SELFTEST := build/exec/dex-encoder-selftest
DEX_FRAMEWORK_PLAN_TEST := build/exec/dex-framework-plan-test
DEX_FRAMEWORK_INVOKE_TEST := build/exec/dex-framework-invoke-test
DEX_FOREIGN_SPEC_TEST := build/exec/dex-foreign-spec-test
DEX_FRAMEWORK_GEN := build/exec/dex-framework-gen
DEX_FRAMEWORK_FILE := build/exec/framework.dex
DEX_FRAMEWORK_DISASSEMBLY := build/exec/baksmali-framework/Idric/FrameworkProbe.smali
DEX_INVALID_LOG := build/exec/invalid-dex-int.log
DEX_INVALID_ARTIFACT := build/exec/invalid-dex-int.dex
DEX_HEADER_CHECK := tests/dex/check_dex.py
DEX_ORACLE_DIR := build/oracles
BAKSMALI_JAR := $(DEX_ORACLE_DIR)/baksmali-3.0.10.jar
SMALI_JAR := $(DEX_ORACLE_DIR)/smali-3.0.10.jar
BAKSMALI_SHA256 := 37ae4a41a8886e15c20b8362fa4250f96bbdb55e1a608199ad8b5dff068b588f
SMALI_SHA256 := 32fa0e88a6c397b3922201adf5f3e534fbaed5a663c71d0c558c3ddce0af844a
DEX_CANDIDATE_DISASSEMBLY := build/exec/baksmali-candidate/Idric/Generated.smali
DEX_TEXT_DISASSEMBLY := build/exec/baksmali-text/Idric/Generated.smali
DEX_ORACLE_FILE := build/exec/oracle-classes.dex
DEX_ORACLE_DISASSEMBLY := build/exec/baksmali-oracle/Idric/Generated.smali
DEX_MALFORMED_FILE := build/exec/malformed-magic.dex
DEX_VALIDATION_RECEIPT := build/exec/dex-validation-receipt.txt

.PHONY: check-compiler check driver dex-fixture dex-text-fixture \
	dex-text-validation dex-foreign-validation dex-encoder-selftest dex-framework-plan-test \
	dex-framework-invoke-test dex-foreign-spec-test dex-framework-validation dex-determinism dex-reject \
	dex-header-validation dex-parser-validation dex-oracle-validation \
	dex-malformed-test dex-test dex-device test verify clean

check-compiler:
	@$(IDRIC) --version
	@git -C "$(IDRIC_REPO)" rev-parse --verify HEAD >/dev/null

check: check-compiler
	$(IDRIC) --typecheck backend.ipkg

driver: $(DRIVER)

$(DRIVER): $(BACKEND_SOURCES)
	$(IDRIC) --build backend.ipkg
	@test -f "$(IDRIC_RUNTIME_LIBRARY)" || { \
		echo "Missing Idriç host runtime library $(IDRIC_RUNTIME_LIBRARY)"; \
		exit 1; \
	}
	cp "$(IDRIC_RUNTIME_LIBRARY)" build/exec/idric-dex_app/

$(DEX_FILE) $(DEX_CHECKED_ANF) $(DEX_PLAN) $(DEX_SMALI) &: $(DRIVER) $(DEX_SOURCE)
	IDRIS2_PATH="$(CURDIR)/build/ttc:$${IDRIS2_PATH}" \
		./$(DRIVER) --cg dex --source-dir examples $(DEX_SOURCE) -o classes

dex-fixture: $(DEX_FILE) $(DEX_CHECKED_ANF) $(DEX_PLAN) $(DEX_SMALI)
	grep -q '^export DexArithmetic.add as add$$' $(DEX_CHECKED_ANF)
	grep -q 'Prelude.EqOrd.<' $(DEX_CHECKED_ANF)
	grep -q '^method add$$' $(DEX_PLAN)
	grep -q 'add-int' $(DEX_PLAN)
	grep -q 'sub-int' $(DEX_PLAN)
	grep -q 'mul-int' $(DEX_PLAN)
	grep -q 'if-lt' $(DEX_PLAN)
	grep -q 'if-eq' $(DEX_PLAN)
	grep -q 'goto' $(DEX_PLAN)
	grep -q 'const v0, -2147483648' $(DEX_PLAN)
	grep -q 'const v0, 2147483647' $(DEX_PLAN)

$(DEX_TEXT_FILE) $(DEX_TEXT_CHECKED_ANF) $(DEX_TEXT_PLAN) $(DEX_TEXT_SMALI) &: $(DRIVER) $(DEX_TEXT_SOURCE)
	IDRIS2_PATH="$(CURDIR)/build/ttc:$${IDRIS2_PATH}" \
		./$(DRIVER) --cg dex --source-dir examples $(DEX_TEXT_SOURCE) -o text

dex-text-fixture: $(DEX_TEXT_FILE) $(DEX_TEXT_CHECKED_ANF) $(DEX_TEXT_PLAN) $(DEX_TEXT_SMALI)
	grep -q '^export DexText.echo_text as echo_text$$' $(DEX_TEXT_CHECKED_ANF)
	grep -q '^export DexText.icu_word as icu_word$$' $(DEX_TEXT_CHECKED_ANF)
	grep -q '^export DexText.text_equal as text_equal$$' $(DEX_TEXT_CHECKED_ANF)
	grep -q '^method echo_text$$' $(DEX_TEXT_PLAN)
	grep -q '^parameters: \[Text\]$$' $(DEX_TEXT_PLAN)
	grep -q '^result: Text$$' $(DEX_TEXT_PLAN)
	grep -q '^method text_equal$$' $(DEX_TEXT_PLAN)
	grep -q 'text-equal' $(DEX_TEXT_PLAN)
	grep -q 'move-object' $(DEX_TEXT_PLAN)
	grep -q 'const-string' $(DEX_TEXT_PLAN)
	grep -q 'return-object' $(DEX_TEXT_PLAN)

$(DEX_FOREIGN_FILE) $(DEX_FOREIGN_CHECKED_ANF) $(DEX_FOREIGN_PLAN) $(DEX_FOREIGN_SMALI) &: $(DRIVER) $(DEX_FOREIGN_SOURCE)
	IDRIS2_PATH="$(CURDIR)/build/ttc:$${IDRIS2_PATH}" \
		./$(DRIVER) --cg dex --source-dir examples $(DEX_FOREIGN_SOURCE) -o foreign

dex-foreign-fixture: $(DEX_FOREIGN_FILE) $(DEX_FOREIGN_CHECKED_ANF) $(DEX_FOREIGN_PLAN) $(DEX_FOREIGN_SMALI)
	grep -q '^export DexForeign.count_bits as count_bits$$' $(DEX_FOREIGN_CHECKED_ANF)
	grep -q 'java_integer_bit_count' $(DEX_FOREIGN_CHECKED_ANF)
	grep -q '^method count_bits$$' $(DEX_FOREIGN_PLAN)
	grep -q 'Ljava/lang/Integer;->bitCount(I)I' $(DEX_FOREIGN_PLAN)
	grep -q 'invoke-static' $(DEX_FOREIGN_PLAN)

$(DEX_SELFTEST): $(DRIVER) tests/dex/EncoderSelfTest.idr
	IDRIS2_PATH="$(CURDIR)/build/ttc:$${IDRIS2_PATH}" \
		$(IDRIC) --source-dir tests/dex tests/dex/EncoderSelfTest.idr \
		-o dex-encoder-selftest
	cp "$(IDRIC_RUNTIME_LIBRARY)" build/exec/dex-encoder-selftest_app/

dex-encoder-selftest: $(DEX_SELFTEST)
	LD_LIBRARY_PATH="$(dir $(IDRIC_RUNTIME_LIBRARY)):$${LD_LIBRARY_PATH}" \
		./$(DEX_SELFTEST)

$(DEX_FRAMEWORK_PLAN_TEST): $(DRIVER) tests/dex/FrameworkPlanTest.idr
	IDRIS2_PATH="$(CURDIR)/build/ttc:$${IDRIS2_PATH}" \
		$(IDRIC) --source-dir tests/dex tests/dex/FrameworkPlanTest.idr \
		-o dex-framework-plan-test
	cp "$(IDRIC_RUNTIME_LIBRARY)" build/exec/dex-framework-plan-test_app/

dex-framework-plan-test: $(DEX_FRAMEWORK_PLAN_TEST)
	LD_LIBRARY_PATH="$(dir $(IDRIC_RUNTIME_LIBRARY)):$${LD_LIBRARY_PATH}" \
		./$(DEX_FRAMEWORK_PLAN_TEST)

$(DEX_FRAMEWORK_INVOKE_TEST): $(DRIVER) tests/dex/FrameworkInvokeTest.idr
	IDRIS2_PATH="$(CURDIR)/build/ttc:$${IDRIS2_PATH}" \
		$(IDRIC) --source-dir tests/dex tests/dex/FrameworkInvokeTest.idr \
		-o dex-framework-invoke-test
	cp "$(IDRIC_RUNTIME_LIBRARY)" build/exec/dex-framework-invoke-test_app/

dex-framework-invoke-test: $(DEX_FRAMEWORK_INVOKE_TEST)
	LD_LIBRARY_PATH="$(dir $(IDRIC_RUNTIME_LIBRARY)):${LD_LIBRARY_PATH}" \
		./$(DEX_FRAMEWORK_INVOKE_TEST)

$(DEX_FOREIGN_SPEC_TEST): $(DRIVER) tests/dex/ForeignSpecTest.idr
	IDRIS2_PATH="$(CURDIR)/build/ttc:${IDRIS2_PATH}" \
		$(IDRIC) --source-dir tests/dex tests/dex/ForeignSpecTest.idr \
		-o dex-foreign-spec-test
	cp "$(IDRIC_RUNTIME_LIBRARY)" build/exec/dex-foreign-spec-test_app/

dex-foreign-spec-test: $(DEX_FOREIGN_SPEC_TEST)
	LD_LIBRARY_PATH="$(dir $(IDRIC_RUNTIME_LIBRARY)):${LD_LIBRARY_PATH}" \
		./$(DEX_FOREIGN_SPEC_TEST)

$(DEX_FRAMEWORK_GEN): $(DRIVER) tests/dex/FrameworkDexGen.idr
	IDRIS2_PATH="$(CURDIR)/build/ttc:$${IDRIS2_PATH}" \
		$(IDRIC) --source-dir tests/dex tests/dex/FrameworkDexGen.idr \
		-o dex-framework-gen
	cp "$(IDRIC_RUNTIME_LIBRARY)" build/exec/dex-framework-gen_app/

$(DEX_FRAMEWORK_FILE): $(DEX_FRAMEWORK_GEN)
	LD_LIBRARY_PATH="$(dir $(IDRIC_RUNTIME_LIBRARY)):$${LD_LIBRARY_PATH}" \
		./$(DEX_FRAMEWORK_GEN)

$(DEX_FRAMEWORK_DISASSEMBLY): $(DEX_FRAMEWORK_FILE) $(BAKSMALI_JAR)
	rm -rf build/exec/baksmali-framework
	mkdir -p build/exec/baksmali-framework
	java -jar $(BAKSMALI_JAR) disassemble $(DEX_FRAMEWORK_FILE) \
		-o build/exec/baksmali-framework

dex-framework-validation: $(DEX_FRAMEWORK_DISASSEMBLY)
	python3 $(DEX_HEADER_CHECK) $(DEX_FRAMEWORK_FILE)
	grep -q '^\.method public static calling_identity_round_trip()I$' $(DEX_FRAMEWORK_DISASSEMBLY)
	grep -q 'invoke-static {}, Landroid/os/Binder;->clearCallingIdentity()J' $(DEX_FRAMEWORK_DISASSEMBLY)
	grep -q 'move-result-wide v0' $(DEX_FRAMEWORK_DISASSEMBLY)
	grep -q 'move-wide v2, v0' $(DEX_FRAMEWORK_DISASSEMBLY)
	grep -q 'invoke-static {v2, v3}, Landroid/os/Binder;->restoreCallingIdentity(J)V' $(DEX_FRAMEWORK_DISASSEMBLY)
	grep -q 'invoke-static {}, Landroid/os/Binder;->getCallingUid()I' $(DEX_FRAMEWORK_DISASSEMBLY)
	grep -q '^\.method public static get_package_service(Ljava/lang/String;)Ljava/lang/Object;$' $(DEX_FRAMEWORK_DISASSEMBLY)
	grep -q 'Landroid/os/ServiceManager;->getService(Ljava/lang/String;)Landroid/os/IBinder;' $(DEX_FRAMEWORK_DISASSEMBLY)
	grep -q '^\.method public static binder_transaction_probe()I$' $(DEX_FRAMEWORK_DISASSEMBLY)
	grep -q 'Landroid/os/Parcel;->obtain()Landroid/os/Parcel;' $(DEX_FRAMEWORK_DISASSEMBLY)
	grep -q 'invoke-interface {v1, v4, v2, v3, v5}, Landroid/os/IBinder;->transact(ILandroid/os/Parcel;Landroid/os/Parcel;I)Z' $(DEX_FRAMEWORK_DISASSEMBLY)
	grep -q '\.catchall' $(DEX_FRAMEWORK_DISASSEMBLY)
	grep -q 'move-exception v9' $(DEX_FRAMEWORK_DISASSEMBLY)
	grep -q 'throw v9' $(DEX_FRAMEWORK_DISASSEMBLY)
	grep -q 'Landroid/os/Parcel;->recycle()V' $(DEX_FRAMEWORK_DISASSEMBLY)

$(DEX_REPEAT_FILE): $(DRIVER) $(DEX_SOURCE)
	IDRIS2_PATH="$(CURDIR)/build/ttc:$${IDRIS2_PATH}" \
		./$(DRIVER) --cg dex --source-dir examples $(DEX_SOURCE) -o classes-repeat

dex-determinism: $(DEX_FILE) $(DEX_REPEAT_FILE)
	cmp $(DEX_FILE) $(DEX_REPEAT_FILE)

dex-reject: $(DRIVER) tests/source/InvalidDexInt.idric
	@set -e; \
	test ! -e $(DEX_INVALID_ARTIFACT) || { \
		echo 'Remove stale $(DEX_INVALID_ARTIFACT) before rejection test'; \
		exit 1; \
	}; \
	IDRIS2_PATH="$(CURDIR)/build/ttc:$${IDRIS2_PATH}" \
		./$(DRIVER) --cg dex --source-dir tests/source \
		tests/source/InvalidDexInt.idric -o invalid-dex-int \
		>$(DEX_INVALID_LOG) 2>&1 || true
	grep -q 'dex rejected source ABI' $(DEX_INVALID_LOG)
	grep -q 'Int32' $(DEX_INVALID_LOG)
	test ! -e $(DEX_INVALID_ARTIFACT)

dex-header-validation: $(DEX_FILE) $(DEX_HEADER_CHECK)
	python3 $(DEX_HEADER_CHECK) $(DEX_FILE)

$(BAKSMALI_JAR):
	mkdir -p $(DEX_ORACLE_DIR)
	curl -fL --retry 3 \
		https://github.com/baksmali/smali/releases/download/3.0.10/baksmali-3.0.10-fat-release.jar \
		-o $@
	echo '$(BAKSMALI_SHA256)  $@' | sha256sum -c -

$(SMALI_JAR):
	mkdir -p $(DEX_ORACLE_DIR)
	curl -fL --retry 3 \
		https://github.com/baksmali/smali/releases/download/3.0.10/smali-3.0.10-fat-release.jar \
		-o $@
	echo '$(SMALI_SHA256)  $@' | sha256sum -c -

$(DEX_FOREIGN_DISASSEMBLY): $(DEX_FOREIGN_FILE) $(BAKSMALI_JAR)
	rm -rf build/exec/baksmali-foreign
	mkdir -p build/exec/baksmali-foreign
	java -jar $(BAKSMALI_JAR) disassemble $(DEX_FOREIGN_FILE) \
		-o build/exec/baksmali-foreign

dex-foreign-validation: dex-foreign-fixture $(DEX_FOREIGN_DISASSEMBLY)
	python3 $(DEX_HEADER_CHECK) $(DEX_FOREIGN_FILE)
	grep -q '^\.method public static count_bits(I)I$$' $(DEX_FOREIGN_DISASSEMBLY)
	grep -q 'invoke-static {p0}, Ljava/lang/Integer;->bitCount(I)I' $(DEX_FOREIGN_DISASSEMBLY)
	grep -q 'move-result v0' $(DEX_FOREIGN_DISASSEMBLY)
	grep -q 'return v0' $(DEX_FOREIGN_DISASSEMBLY)

$(DEX_CANDIDATE_DISASSEMBLY): $(DEX_FILE) $(BAKSMALI_JAR)
	mkdir -p build/exec/baksmali-candidate
	java -jar $(BAKSMALI_JAR) disassemble $(DEX_FILE) \
		-o build/exec/baksmali-candidate

dex-parser-validation: dex-header-validation $(DEX_CANDIDATE_DISASSEMBLY)
	grep -q '^\.method public static add(II)I$$' $(DEX_CANDIDATE_DISASSEMBLY)
	grep -q 'add-int v0, p0, p1' $(DEX_CANDIDATE_DISASSEMBLY)
	grep -q 'sub-int v0, p0, p1' $(DEX_CANDIDATE_DISASSEMBLY)
	grep -q 'mul-int v0, p0, p1' $(DEX_CANDIDATE_DISASSEMBLY)
	grep -q 'if-lt p0, p1' $(DEX_CANDIDATE_DISASSEMBLY)
	grep -q 'move v0, p0' $(DEX_CANDIDATE_DISASSEMBLY)
	grep -q 'const/4 v0, -0x8' $(DEX_CANDIDATE_DISASSEMBLY)
	grep -q 'const/4 v0, 0x7' $(DEX_CANDIDATE_DISASSEMBLY)
	grep -q 'const/16 v0, -0x8000' $(DEX_CANDIDATE_DISASSEMBLY)
	grep -q 'const/16 v0, 0x7fff' $(DEX_CANDIDATE_DISASSEMBLY)
	grep -q 'const v0, -0x8001' $(DEX_CANDIDATE_DISASSEMBLY)
	grep -q 'const v0, 0x8000' $(DEX_CANDIDATE_DISASSEMBLY)
	grep -q 'const v0, -0x80000000' $(DEX_CANDIDATE_DISASSEMBLY)
	grep -q 'const v0, 0x7fffffff' $(DEX_CANDIDATE_DISASSEMBLY)

$(DEX_TEXT_DISASSEMBLY): $(DEX_TEXT_FILE) $(BAKSMALI_JAR)
	mkdir -p build/exec/baksmali-text
	java -jar $(BAKSMALI_JAR) disassemble $(DEX_TEXT_FILE) \
		-o build/exec/baksmali-text

dex-text-validation: dex-text-fixture $(DEX_TEXT_DISASSEMBLY)
	python3 $(DEX_HEADER_CHECK) $(DEX_TEXT_FILE)
	grep -q '^\.method public static echo_text(Ljava/lang/String;)Ljava/lang/String;$$' $(DEX_TEXT_DISASSEMBLY)
	grep -q '^\.method public static icu_word()Ljava/lang/String;$$' $(DEX_TEXT_DISASSEMBLY)
	grep -q '^\.method public static text_equal(Ljava/lang/String;Ljava/lang/String;)I$$' $(DEX_TEXT_DISASSEMBLY)
	grep -q 'move-object v0, p0' $(DEX_TEXT_DISASSEMBLY)
	grep -q 'const-string v0, "icu"' $(DEX_TEXT_DISASSEMBLY)
	grep -q 'invoke-virtual {p0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z' $(DEX_TEXT_DISASSEMBLY)
	grep -q 'move-result' $(DEX_TEXT_DISASSEMBLY)
	grep -q 'return-object v0' $(DEX_TEXT_DISASSEMBLY)

$(DEX_ORACLE_FILE): $(DEX_SMALI) $(SMALI_JAR)
	mkdir -p build/exec/smali-oracle-source
	cp $(DEX_SMALI) build/exec/smali-oracle-source/Generated.smali
	java -jar $(SMALI_JAR) assemble build/exec/smali-oracle-source -o $@

$(DEX_ORACLE_DISASSEMBLY): $(DEX_ORACLE_FILE) $(BAKSMALI_JAR)
	mkdir -p build/exec/baksmali-oracle
	java -jar $(BAKSMALI_JAR) disassemble $(DEX_ORACLE_FILE) \
		-o build/exec/baksmali-oracle

dex-oracle-validation: $(DEX_CANDIDATE_DISASSEMBLY) $(DEX_ORACLE_DISASSEMBLY)
	cmp $(DEX_CANDIDATE_DISASSEMBLY) $(DEX_ORACLE_DISASSEMBLY)

$(DEX_MALFORMED_FILE): $(DEX_FILE)
	cp $(DEX_FILE) $@
	printf '\000' | dd of=$@ bs=1 seek=0 count=1 conv=notrunc status=none

dex-malformed-test: $(DEX_MALFORMED_FILE) $(BAKSMALI_JAR)
	@if python3 $(DEX_HEADER_CHECK) $(DEX_MALFORMED_FILE) >/dev/null 2>&1; then \
		echo 'Independent header validator accepted malformed DEX'; \
		exit 1; \
	fi
	@if java -jar $(BAKSMALI_JAR) disassemble $(DEX_MALFORMED_FILE) \
		-o build/exec/baksmali-malformed >/dev/null 2>&1; then \
		echo 'baksmali accepted malformed DEX magic'; \
		exit 1; \
	fi

dex-test: check dex-fixture dex-text-validation dex-encoder-selftest \
	dex-framework-plan-test dex-framework-invoke-test dex-framework-validation \
	dex-determinism dex-reject dex-parser-validation dex-oracle-validation dex-malformed-test
	@{ \
		echo 'source checked        PASS'; \
		echo 'checked ANF retained  PASS'; \
		echo 'Text ABI encoded       PASS'; \
		echo 'Text equality encoded  PASS'; \
		echo 'Binder type plan       PASS'; \
		echo 'Binder invoke 35c      PASS'; \
		echo 'Binder DEX metadata    PASS'; \
		echo 'Binder DEX parsed      PASS'; \
		echo 'Binder catch-all       PASS'; \
		echo 'DEX generated         PASS'; \
		echo 'DEX parser validation PASS'; \
		echo 'oracle comparison     PASS'; \
		echo 'deterministic output  PASS'; \
		echo 'ART loaded             SKIP prerequisite=device_or_emulator'; \
		echo 'ART executed           SKIP prerequisite=ART_loaded'; \
		echo 'result checked         SKIP prerequisite=ART_executed'; \
		echo 'compiler requested ref $(IDRIC_COMPILER_REF)'; \
		printf 'compiler resolved SHA  '; git -C "$(IDRIC_REPO)" rev-parse HEAD; \
		printf 'compiler dirty state   '; if git -C "$(IDRIC_REPO)" status --porcelain | grep -q .; then echo dirty; else echo clean; fi; \
		printf 'compiler revision      '; $(IDRIC) --version | head -n 1; \
		printf 'backend requested ref  %s\n' "$${GITHUB_HEAD_REF:-$${GITHUB_REF_NAME:-local}}"; \
		printf 'backend revision       '; git rev-parse HEAD; \
		printf 'backend dirty state    '; if git status --porcelain | grep -q .; then echo dirty; else echo clean; fi; \
		printf 'classes.dex SHA-256    '; sha256sum $(DEX_FILE) | cut -d' ' -f1; \
		printf 'text.dex SHA-256       '; sha256sum $(DEX_TEXT_FILE) | cut -d' ' -f1; \
		printf 'framework.dex SHA-256  '; sha256sum $(DEX_FRAMEWORK_FILE) | cut -d' ' -f1; \
		echo 'checked form           $(DEX_CHECKED_ANF)'; \
		echo 'Text checked form      $(DEX_TEXT_CHECKED_ANF)'; \
		echo 'DEX plan               $(DEX_PLAN)'; \
		echo 'Text DEX plan          $(DEX_TEXT_PLAN)'; \
	} >$(DEX_VALIDATION_RECEIPT)
	@cat $(DEX_VALIDATION_RECEIPT)

dex-device: dex-test $(SMALI_JAR)
	SMALI_JAR="$(CURDIR)/$(SMALI_JAR)" tests/dex/device-acceptance.sh $(DEX_FILE)

test: dex-test

verify: dex-test

clean:
	rm -rf build
