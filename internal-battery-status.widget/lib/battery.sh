#!/bin/bash
# Internal battery status via `pmset -g batt`. On first run, also renders the SF
# Symbol bolt.fill to a PNG (the charging-bolt mask) with the Swift helper; the PNG
# is generated locally, not shipped. Requires Xcode Command Line Tools (`swift`).
DIR="$(cd "$(dirname "$0")" && pwd)"
if [ ! -f "$DIR/icons/bolt.fill.ink.png" ]; then
  mkdir -p "$DIR/icons"
  swift "$DIR/render-bolt.swift" "$DIR/icons" >/dev/null 2>&1
fi

pmset -g batt
