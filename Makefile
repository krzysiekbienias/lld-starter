# ---------------------------------------------------------------------------
# Wrapper na CMake + Ninja. Szybkie komendy do codziennej pracy:
#
#   make              -> build (Debug)
#   make run          -> zbuduj i uruchom app (ARGS="..." przekazuje argumenty)
#   make dev          -> zbuduj i uruchom dev_main
#   make test         -> zbuduj i odpal wszystkie testy (ctest)
#   make gtest        -> odpal binarkę testów bezpośrednio (FILTER="Suite.Name")
#   make release      -> build Release do build-release/
#   make format       -> clang-format na całym kodzie
#   make uml          -> wygeneruj diagram klas (clang-uml) i wstaw do README.md
#   make clean        -> usuń katalogi build*
#
# Zmienne: BUILD_TYPE=Debug|Release, GENERATOR=Ninja, ARGS="...", FILTER="..."
# ---------------------------------------------------------------------------

BUILD_TYPE ?= Debug
GENERATOR  ?= Ninja
BUILD_DIR  ?= build
ifeq ($(BUILD_TYPE),Release)
  BUILD_DIR := build-release
endif

CMAKE  ?= cmake
CTEST  ?= ctest
ARGS   ?=
FILTER ?=

# macOS: jeśli domyślne SDK nie linkuje (np. SDK 27 vs stary ld), użyj SDK z Xcode.app.
# Można wymusić ręcznie: make SYSROOT=/path/to/MacOSX.sdk
SYSROOT   ?=
XCODE_SDK := /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk

SRC_FILES := $(shell find app src header unit_tests -type f \( -name '*.cpp' -o -name '*.hpp' -o -name '*.h' \) 2>/dev/null)

UML_FILE := $(BUILD_DIR)/uml/class_diagram.mmd

.PHONY: all configure build run dev test gtest release debug format uml clean rebuild help

all: build

# --- Konfiguracja (tylko gdy brak cache) -----------------------------------
$(BUILD_DIR)/CMakeCache.txt:
	@sysroot="$(SYSROOT)"; \
	if [ -z "$$sysroot" ] && [ "$$(uname)" = Darwin ] && [ -d "$(XCODE_SDK)" ]; then \
	  if ! echo 'int main(){return 0;}' | c++ -x c++ - -o /tmp/.mk_sdk_check 2>/dev/null; then \
	    echo ">> domyślne SDK nie linkuje, używam $(XCODE_SDK)"; sysroot="$(XCODE_SDK)"; \
	  fi; rm -f /tmp/.mk_sdk_check; \
	fi; \
	set -x; $(CMAKE) -S . -B $(BUILD_DIR) -G $(GENERATOR) \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
		$${sysroot:+-DCMAKE_OSX_SYSROOT=$$sysroot}

configure: $(BUILD_DIR)/CMakeCache.txt

# --- Budowanie --------------------------------------------------------------
build: configure
	$(CMAKE) --build $(BUILD_DIR)

debug:
	$(MAKE) build BUILD_TYPE=Debug

release:
	$(MAKE) build BUILD_TYPE=Release

rebuild: clean build

# --- Uruchamianie -----------------------------------------------------------
run: configure
	$(CMAKE) --build $(BUILD_DIR) --target app
	./$(BUILD_DIR)/app $(ARGS)

dev: configure
	$(CMAKE) --build $(BUILD_DIR) --target dev_main
	./$(BUILD_DIR)/dev_main $(ARGS)

# --- Testy ------------------------------------------------------------------
test: configure
	$(CMAKE) --build $(BUILD_DIR) --target test_environment
	$(CTEST) --test-dir $(BUILD_DIR) --output-on-failure $(if $(FILTER),-R "$(FILTER)",)

gtest: configure
	$(CMAKE) --build $(BUILD_DIR) --target test_environment
	./$(BUILD_DIR)/test_environment $(if $(FILTER),--gtest_filter="$(FILTER)",) $(ARGS)

# --- Narzędzia --------------------------------------------------------------
format:
	@if [ -n "$(SRC_FILES)" ]; then clang-format -i $(SRC_FILES); echo "formatted $(words $(SRC_FILES)) files"; fi

# Diagram trafia do README.md między znaczniki <!-- uml:start --> i <!-- uml:end -->.
uml: configure
	@$(CMAKE) -S . -B $(BUILD_DIR) > /dev/null
	clang-uml -g mermaid --no-metadata --allow-empty-diagrams
	@grep -q '<!-- uml:start -->' README.md && grep -q '<!-- uml:end -->' README.md \
		|| { echo "❌ README.md nie ma znaczników <!-- uml:start --> / <!-- uml:end -->"; exit 1; }
	@awk -v f="$(UML_FILE)" ' \
		/<!-- uml:start -->/ { print; print "```mermaid"; while ((getline l < f) > 0) print l; print "```"; skip = 1; next } \
		/<!-- uml:end -->/ { skip = 0 } \
		!skip { print }' README.md > README.md.tmp && mv README.md.tmp README.md
	@echo "✅ README.md: diagram zaktualizowany"

clean:
	rm -rf build build-release

help:
	@sed -n '2,14p' $(MAKEFILE_LIST) | sed 's/^# \{0,1\}//'
