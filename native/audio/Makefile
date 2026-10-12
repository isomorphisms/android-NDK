ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BUILD ?= $(ROOT)/build
ICK ?=
ICK_FLAGS ?= -fno-link-libatomic
AICI_ROOT ?= $(ROOT)/../../.ai-ci-ick
SOURCES = $(ROOT)/interface/audio_result.c $(ROOT)/interface/pcm_ring.c $(ROOT)/android/aaudio_input.c
INCLUDES = -I"$(ROOT)/interface" -I"$(ROOT)/android"
WARNINGS = -std=c11 -O2 -Wall -Wextra -Werror -pedantic

.PHONY: host android
host:
	test -x "$(ICK)"
	mkdir -p "$(BUILD)"
	"$(ICK)" $(ICK_FLAGS) $(WARNINGS) $(INCLUDES) -I"$(ROOT)/tests/fake" $(SOURCES) "$(ROOT)/tests/backend_test.c" -o "$(BUILD)/backend-test"
	"$(BUILD)/backend-test"

ifneq ($(ABI),)
include $(AICI_ROOT)/ick-android/Makefile
ANDROID_API ?= 26
AUDIO_NDK_CC = $(NDK_BIN)/$(NDK_TARGET_$(ABI))$(ANDROID_API)-clang
AUDIO_OBJECTS = $(addprefix $(BUILD)/,$(addsuffix .o,$(notdir $(basename $(SOURCES)))))
vpath %.c $(ROOT)/interface $(ROOT)/android

$(BUILD)/%.s: %.c
	test "$$($(ICK_COMPILER) -dumpmachine)" = "$(GNU_TARGET)"
	test -f "$(ICK_BUILTIN_INCLUDE)/stdatomic.h"
	mkdir -p "$(BUILD)"
	"$(ICK_COMPILER)" $(ICK_EXTRA_FLAGS) $(ICK_NDK_FLAGS) -D__ANDROID_API__=$(ANDROID_API) -D__ANDROID_MIN_SDK_VERSION__=$(ANDROID_API) $(WARNINGS) $(INCLUDES) -fPIC -S "$<" -o "$@"

$(BUILD)/%.o: $(BUILD)/%.s
	"$(AUDIO_NDK_CC)" $(TARGET_FLAGS) -fPIC -c "$<" -o "$@"

android: $(AUDIO_OBJECTS)
	"$(AUDIO_NDK_CC)" -shared -Wl,--no-undefined $(AUDIO_OBJECTS) -laaudio -o "$(BUILD)/libandroid-audio-input.so"
	"$(NDK_READELF)" -h "$(BUILD)/libandroid-audio-input.so"
else
android:
	$(error set ABI, NDK and ICK_STAGE for the pinned shared producer)
endif
.DEFAULT_GOAL := host
