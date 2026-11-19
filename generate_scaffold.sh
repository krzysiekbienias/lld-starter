#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "❌ Usage: ./generate_scaffold.sh <folder|.> <file_name> [--header-only]"
  echo "   Example: ./generate_scaffold.sh states idle_state"
  echo "            ./generate_scaffold.sh enums coin --header-only"
  echo "            ./generate_scaffold.sh . inventory      (no subfolder)"
  exit 1
}

[[ $# -eq 2 || $# -eq 3 ]] || usage
FOLDER="$1"
FILE="$2"
HEADER_ONLY="${3:-}"
[[ -z "$HEADER_ONLY" || "$HEADER_ONLY" == "--header-only" ]] || usage

[[ -f CMakeLists.txt ]] || { echo "❌ Run from project root"; exit 1; }
[[ "$FILE" =~ ^[a-z0-9_]+$ ]] || { echo "❌ Invalid file name (use snake_case): $FILE"; exit 1; }

if [[ -z "$FOLDER" || "$FOLDER" == "." ]]; then
  PREFIX=""
else
  [[ "$FOLDER" =~ ^[a-z0-9_]+$ ]] || { echo "❌ Invalid folder name (use snake_case or .): $FOLDER"; exit 1; }
  PREFIX="${FOLDER}/"
fi

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

create_if_missing "header/${PREFIX}${FILE}.hpp" \
"#pragma once

"

if [[ -z "$HEADER_ONLY" ]]; then
  create_if_missing "src/${PREFIX}${FILE}.cpp" \
"#include \"${PREFIX}${FILE}.hpp\"

"

  create_if_missing "unit_tests/${PREFIX}test_${FILE}.cpp" \
"#include \"${PREFIX}${FILE}.hpp\"
#include <gtest/gtest.h>

"
fi
