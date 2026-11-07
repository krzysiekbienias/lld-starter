#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "❌ Usage: ./generate_scaffold.sh <folder> <ClassName> [--header-only]"
  echo "   Example: ./generate_scaffold.sh states IdleState"
  echo "            ./generate_scaffold.sh enums Coin --header-only"
  exit 1
}

[[ $# -eq 2 || $# -eq 3 ]] || usage
FOLDER="$1"
NAME="$2"
HEADER_ONLY="${3:-}"
[[ -z "$HEADER_ONLY" || "$HEADER_ONLY" == "--header-only" ]] || usage

[[ -f CMakeLists.txt ]] || { echo "❌ Run from project root"; exit 1; }
[[ "$FOLDER" =~ ^[A-Za-z0-9_]+$ ]] || { echo "❌ Invalid folder name: $FOLDER"; exit 1; }
[[ "$NAME"   =~ ^[A-Za-z0-9_]+$ ]] || { echo "❌ Invalid class name: $NAME"; exit 1; }

create_if_missing() {
  local path="$1"
  local content="$2"
  mkdir -p "$(dirname "$path")"
  if [[ -e "$path" ]]; then
    echo "⚠️  SKIP (exists): $path"
  else
    printf "%s" "$content" > "$path"
    echo "✅ CREATED: $path"
  fi
}

create_if_missing "header/${FOLDER}/${NAME}.hpp" \
"#pragma once

#include <string>
#include <vector>

class ${NAME} {
public:
};
"

if [[ -z "$HEADER_ONLY" ]]; then
  create_if_missing "src/${FOLDER}/${NAME}.cpp" \
"#include \"${FOLDER}/${NAME}.hpp\"
"

  create_if_missing "unit_tests/${FOLDER}/test_${NAME}.cpp" \
"#include \"${FOLDER}/${NAME}.hpp\"
#include <gtest/gtest.h>

TEST(${NAME}Test, Placeholder) {
    GTEST_SKIP() << \"TODO\";
}
"
fi