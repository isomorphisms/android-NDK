ANDROID_NDK_HOME ?=
API ?= 29
ABI ?= armeabi-v7a
BUILD_DIR ?= build/$(ABI)

ifeq ($(ABI),armeabi-v7a)
TARGET := armv7a-linux-androideabi
else ifeq ($(ABI),arm64-v8a)
TARGET := aarch64-linux-android
else ifeq ($(ABI),x86)
TARGET := i686-linux-android
else ifeq ($(ABI),x86_64)
TARGET := x86_64-linux-android
else
$(error Unsupported ABI $(ABI))
endif

HOST_TAG ?= linux-x86_64
CC := $(ANDROID_NDK_HOME)/toolchains/llvm/prebuilt/$(HOST_TAG)/bin/$(TARGET)$(API)-clang
OUTPUT := $(BUILD_DIR)/libidric_android_binder.so

.PHONY: all clean

all: $(OUTPUT)

$(OUTPUT): idric_binder_ndk.c idric_binder_ndk.h
	@test -n "$(ANDROID_NDK_HOME)" || { echo 'ANDROID_NDK_HOME is required'; exit 1; }
	@test -x "$(CC)" || { echo 'NDK clang not found: $(CC)'; exit 1; }
	mkdir -p $(BUILD_DIR)
	$(CC) -std=c11 -O2 -fPIC -shared -Wall -Wextra -Wpedantic -Werror \
		-pthread -I. idric_binder_ndk.c -lbinder_ndk -o $(OUTPUT)

clean:
	rm -rf build
