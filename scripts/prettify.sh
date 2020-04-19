#!/bin/bash

# prettify using shfmt

if ! command -v shfmt 2>/dev/null; then
  echo "Unable to find \`shfmt\` in PATH"
  echo "Make sure you have it installed"
  echo ""
  echo "https://github.com/mvdan/sh"
else 
  shfmt -p -w -i 2 -ci tsu tsudo
  # prettify the linter and prettify script
  shfmt -w -i 2 -ci -- *.sh
fi
