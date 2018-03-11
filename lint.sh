#!/bin/bash

# lint using shellcheck

if ! command -v shellcheck 2>/dev/null; then
  echo "Unable to find \`shellcheck\` in PATH"
  echo "Make sure you have it installed"
  echo ""
  echo "https://github.com/koalaman/shellcheck"
  exit 1
fi

shellcheck -s sh tsu tsudo

# lint the linter and prettify script
shellcheck -s bash -- *.sh
